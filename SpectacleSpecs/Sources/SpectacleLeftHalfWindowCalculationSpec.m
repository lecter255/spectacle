#import <XCTest/XCTest.h>

#import "SpectacleTestHelpers.h"
#import "SpectacleWindowPositionCalculationResult.h"
#import "SpectacleWindowPositionCalculator.h"

@interface SpectacleLeftHalfWindowCalculationTests : XCTestCase
@end

@implementation SpectacleLeftHalfWindowCalculationTests
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

- (void)testCalculateAWindowsCGRectInTheLeftHalfOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(165.0f, 245.0f, 564.0f, 384.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionLeftHalf];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 4.0f, 720.0f, 873.0f));
}

- (void)testRepeatedPressesCycleFromHalfToTwoThirds
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 4.0f, 720.0f, 873.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionLeftHalf];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 4.0f, 960.0f, 873.0f));
}

- (void)testRepeatedPressesCycleFromTwoThirdsToThreeQuarters
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 4.0f, 960.0f, 873.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionLeftHalf];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 4.0f, 1080.0f, 873.0f));
}

- (void)testRepeatedPressesCycleFromThreeQuartersToOneQuarter
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 4.0f, 1080.0f, 873.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionLeftHalf];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 4.0f, 360.0f, 873.0f));
}

- (void)testRepeatedPressesCycleFromOneQuarterToOneThird
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 4.0f, 360.0f, 873.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionLeftHalf];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 4.0f, 480.0f, 873.0f));
}

- (void)testRepeatedPressesCycleFromOneThirdBackToHalf
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 4.0f, 480.0f, 873.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionLeftHalf];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 4.0f, 720.0f, 873.0f));
}

@end
