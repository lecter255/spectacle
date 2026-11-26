#import <XCTest/XCTest.h>

#import "SpectacleTestHelpers.h"
#import "SpectacleWindowPositionCalculationResult.h"
#import "SpectacleWindowPositionCalculator.h"

@interface SpectacleLowerRightWindowCalculationTests : XCTestCase
@end

@implementation SpectacleLowerRightWindowCalculationTests
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

- (void)testCalculateAWindowsCGRectInTheLowerRightCornerOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(165.0f, 245.0f, 564.0f, 384.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionLowerRight];

  SpectacleAssertEqualRects(result.windowRect, CGRectMake(720.0f, 4.0f, 720.0f, 436.0f));
}

- (void)testRepeatedPressesCycleFromHalfToTwoThirds
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(720.0f, 4.0f, 720.0f, 436.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionLowerRight];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(480.0f, 4.0f, 960.0f, 436.0f));
}

- (void)testRepeatedPressesCycleFromTwoThirdsToThreeQuarters
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(480.0f, 4.0f, 960.0f, 436.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionLowerRight];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(360.0f, 4.0f, 1080.0f, 436.0f));
}

- (void)testRepeatedPressesCycleFromThreeQuartersToOneQuarter
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(360.0f, 4.0f, 1080.0f, 436.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionLowerRight];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(1080.0f, 4.0f, 360.0f, 436.0f));
}

- (void)testRepeatedPressesCycleFromOneQuarterToOneThird
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(1080.0f, 4.0f, 360.0f, 436.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionLowerRight];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(960.0f, 4.0f, 480.0f, 436.0f));
}

- (void)testRepeatedPressesCycleFromOneThirdBackToHalf
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(960.0f, 4.0f, 480.0f, 436.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionLowerRight];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(720.0f, 4.0f, 720.0f, 436.0f));
}

- (void)testRepeatedPressesStepThroughEverySizeAndWrapAround
{
  // 1/2, 2/3, 3/4, 1/4, 1/3, then back to 1/2.
  NSArray<NSValue *> *expectedRects = @[
    [NSValue valueWithRect:NSRectFromCGRect(CGRectMake(720.0f, 4.0f, 720.0f, 436.0f))],
    [NSValue valueWithRect:NSRectFromCGRect(CGRectMake(480.0f, 4.0f, 960.0f, 436.0f))],
    [NSValue valueWithRect:NSRectFromCGRect(CGRectMake(360.0f, 4.0f, 1080.0f, 436.0f))],
    [NSValue valueWithRect:NSRectFromCGRect(CGRectMake(1080.0f, 4.0f, 360.0f, 436.0f))],
    [NSValue valueWithRect:NSRectFromCGRect(CGRectMake(960.0f, 4.0f, 480.0f, 436.0f))],
    [NSValue valueWithRect:NSRectFromCGRect(CGRectMake(720.0f, 4.0f, 720.0f, 436.0f))],
  ];
  CGRect windowRect = CGRectMake(165.0f, 245.0f, 564.0f, 384.0f);
  for (NSValue *expectedRect in expectedRects) {
    windowRect = [windowPositionCalculator calculateWindowRect:windowRect
                                    visibleFrameOfSourceScreen:visibleFrameSourceScreen
                               visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                        action:kSpectacleWindowActionLowerRight].windowRect;
    SpectacleAssertEqualRects(windowRect, NSRectToCGRect(expectedRect.rectValue));
  }
}

@end
