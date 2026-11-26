#import <XCTest/XCTest.h>

#import "SpectacleTestHelpers.h"
#import "SpectacleWindowPositionCalculationResult.h"
#import "SpectacleWindowPositionCalculator.h"

@interface SpectacleSmallerWindowCalculationTests : XCTestCase
@end

@implementation SpectacleSmallerWindowCalculationTests
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

- (void)testCalculateAWindowsSmallerCGRectWhenCenteredInTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(315.0f, 177.0f, 810.0f, 526.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(330.0f, 192.0f, 780.0f, 496.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(330.0f, 192.0f, 780.0f, 496.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(345.0f, 207.0f, 750.0f, 466.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(345.0f, 207.0f, 750.0f, 466.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(360.0f, 222.0f, 720.0f, 436.0f));
}

- (void)testCalculateAWindowsSmallerCGRectWhenAgainstTheTopEdgeOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(357.0f, 351.0f, 810.0f, 526.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(372.0f, 381.0f, 780.0f, 496.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(372.0f, 381.0f, 780.0f, 496.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(387.0f, 411.0f, 750.0f, 466.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(387.0f, 411.0f, 750.0f, 466.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(402.0f, 441.0f, 720.0f, 436.0f));
}

- (void)testCalculateAWindowsSmallerCGRectWhenAgainstTheBottomEdgeOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(193.0f, 4.0f, 810.0f, 526.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(208.0f, 4.0f, 780.0f, 496.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(208.0f, 4.0f, 780.0f, 496.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(223.0f, 4.0f, 750.0f, 466.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(223.0f, 4.0f, 750.0f, 466.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(238.0f, 4.0f, 720.0f, 436.0f));
}

- (void)testCalculateAWindowsSmallerCGRectWhenAgainstTheLeftEdgeOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 205.0f, 810.0f, 526.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 220.0f, 780.0f, 496.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 220.0f, 780.0f, 496.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 235.0f, 750.0f, 466.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 235.0f, 750.0f, 466.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 250.0f, 720.0f, 436.0f));
}

- (void)testCalculateAWindowsSmallerCGRectWhenAgainstTheRightEdgeOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(630.0f, 258.0f, 810.0f, 526.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(660.0f, 273.0f, 780.0f, 496.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(660.0f, 273.0f, 780.0f, 496.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(690.0f, 288.0f, 750.0f, 466.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(690.0f, 288.0f, 750.0f, 466.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(720.0f, 303.0f, 720.0f, 436.0f));
}

- (void)testCalculateAWindowsSmallerCGRectWhenAgainstTheTopAndLeftEdgesOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 351.0f, 810.0f, 526.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 381.0f, 780.0f, 496.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 381.0f, 780.0f, 496.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 411.0f, 750.0f, 466.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 411.0f, 750.0f, 466.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 441.0f, 720.0f, 436.0f));
}

- (void)testCalculateAWindowsSmallerCGRectWhenAgainstTheTopAndRightEdgesOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(630.0f, 351.0f, 810.0f, 526.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(660.0f, 381.0f, 780.0f, 496.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(660.0f, 381.0f, 780.0f, 496.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(690.0f, 411.0f, 750.0f, 466.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(690.0f, 411.0f, 750.0f, 466.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(720.0f, 441.0f, 720.0f, 436.0f));
}

- (void)testCalculateAWindowsSmallerCGRectWhenAgainstTheBottomAndLeftEdgesOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 4.0f, 810.0f, 526.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 4.0f, 780.0f, 496.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 4.0f, 780.0f, 496.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 4.0f, 750.0f, 466.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 4.0f, 750.0f, 466.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 4.0f, 720.0f, 436.0f));
}

- (void)testCalculateAWindowsSmallerCGRectWhenAgainstTheBottomAndRightEdgesOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(630.0f, 4.0f, 810.0f, 526.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(660.0f, 4.0f, 780.0f, 496.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(660.0f, 4.0f, 780.0f, 496.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(690.0f, 4.0f, 750.0f, 466.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(690.0f, 4.0f, 750.0f, 466.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(720.0f, 4.0f, 720.0f, 436.0f));
}

- (void)testCalculateAWindowsSmallerCGRectWhenAgainstTheTopAndBottomEdgesOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(299.0f, 4.0f, 810.0f, 873.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(314.0f, 4.0f, 780.0f, 873.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(314.0f, 4.0f, 780.0f, 873.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(329.0f, 4.0f, 750.0f, 873.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(329.0f, 4.0f, 750.0f, 873.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(344.0f, 4.0f, 720.0f, 873.0f));
}

- (void)testCalculateAWindowsSmallerCGRectWhenAgainstTheLeftAndRightEdgesOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 240.0f, 1440.0f, 536.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 255.0f, 1440.0f, 506.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 255.0f, 1440.0f, 506.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 270.0f, 1440.0f, 476.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 270.0f, 1440.0f, 476.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 285.0f, 1440.0f, 446.0f));
}

- (void)testCalculateAWindowsSmallerCGRectWhenAgainstAllEdgesOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 4.0f, 1440.0f, 873.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(15.0f, 19.0f, 1410.0f, 843.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(15.0f, 19.0f, 1410.0f, 843.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(30.0f, 34.0f, 1380.0f, 813.0f));
  result = [windowPositionCalculator calculateWindowRect:CGRectMake(30.0f, 34.0f, 1380.0f, 813.0f)
                              visibleFrameOfSourceScreen:visibleFrameSourceScreen
                         visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                  action:kSpectacleWindowActionSmaller];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(45.0f, 49.0f, 1350.0f, 783.0f));
}

@end
