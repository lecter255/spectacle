#import <XCTest/XCTest.h>

#import "SpectacleTestHelpers.h"
#import "SpectacleWindowPositionCalculationResult.h"
#import "SpectacleWindowPositionCalculator.h"

@interface SpectacleTopHalfWindowCalculationTests : XCTestCase
@end

@implementation SpectacleTopHalfWindowCalculationTests
{
  CGRect visibleFrameSourceScreen;
  CGRect visibleFrameDestinationScreen;
  SpectacleWindowPositionCalculator *windowPositionCalculator;
  NSMutableArray<NSString *> *calculationErrors;
}

- (void)setUp
{
  [super setUp];
  visibleFrameSourceScreen = CGRectMake(0.0f, 4.0f, 1440.0f, 873.0f);
  visibleFrameDestinationScreen = CGRectMake(0.0f, 4.0f, 1440.0f, 873.0f);
  // Collect JavaScript errors instead of failing inside the block, which would need to capture self.
  NSMutableArray<NSString *> *errors = [NSMutableArray new];
  calculationErrors = errors;
  windowPositionCalculator = [[SpectacleWindowPositionCalculator alloc] initWithErrorHandler:^(NSString *message) {
    [errors addObject:message];
  }];
}

- (void)tearDown
{
  XCTAssertEqualObjects(calculationErrors, @[], @"The window position calculation raised a JavaScript error");
  [super tearDown];
}

- (void)testCalculateAWindowsCGRectInTheTopHalfOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(165.0f, 245.0f, 564.0f, 384.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionTopHalf];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 441.0f, 1440.0f, 436.0f));
}

- (void)testRepeatedPressesCycleFromHalfToTwoThirds
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 441.0f, 1440.0f, 436.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionTopHalf];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 295.0f, 1440.0f, 582.0f));
}

- (void)testRepeatedPressesCycleFromTwoThirdsToThreeQuarters
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 295.0f, 1440.0f, 582.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionTopHalf];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 223.0f, 1440.0f, 654.0f));
}

- (void)testRepeatedPressesCycleFromThreeQuartersToOneQuarter
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 223.0f, 1440.0f, 654.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionTopHalf];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 659.0f, 1440.0f, 218.0f));
}

- (void)testRepeatedPressesCycleFromOneQuarterToOneThird
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 659.0f, 1440.0f, 218.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionTopHalf];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 586.0f, 1440.0f, 291.0f));
}

- (void)testRepeatedPressesCycleFromOneThirdBackToHalf
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 586.0f, 1440.0f, 291.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionTopHalf];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 441.0f, 1440.0f, 436.0f));
}

- (void)testRepeatedPressesStepThroughEverySizeAndWrapAround
{
  // 1/2, 2/3, 3/4, 1/4, 1/3, then back to 1/2.
  NSArray<NSValue *> *expectedRects = @[
    [NSValue valueWithRect:NSRectFromCGRect(CGRectMake(0.0f, 441.0f, 1440.0f, 436.0f))],
    [NSValue valueWithRect:NSRectFromCGRect(CGRectMake(0.0f, 295.0f, 1440.0f, 582.0f))],
    [NSValue valueWithRect:NSRectFromCGRect(CGRectMake(0.0f, 223.0f, 1440.0f, 654.0f))],
    [NSValue valueWithRect:NSRectFromCGRect(CGRectMake(0.0f, 659.0f, 1440.0f, 218.0f))],
    [NSValue valueWithRect:NSRectFromCGRect(CGRectMake(0.0f, 586.0f, 1440.0f, 291.0f))],
    [NSValue valueWithRect:NSRectFromCGRect(CGRectMake(0.0f, 441.0f, 1440.0f, 436.0f))],
  ];
  CGRect windowRect = CGRectMake(165.0f, 245.0f, 564.0f, 384.0f);
  for (NSValue *expectedRect in expectedRects) {
    windowRect = [windowPositionCalculator calculateWindowRect:windowRect
                                    visibleFrameOfSourceScreen:visibleFrameSourceScreen
                               visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                        action:kSpectacleWindowActionTopHalf].windowRect;
    SpectacleAssertEqualRects(windowRect, NSRectToCGRect(expectedRect.rectValue));
  }
}

@end
