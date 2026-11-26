#import <XCTest/XCTest.h>

#import "SpectacleTestHelpers.h"
#import "SpectacleWindowPositionCalculationResult.h"
#import "SpectacleWindowPositionCalculator.h"

@interface SpectaclePreviousThirdWindowCalculationTests : XCTestCase
@end

@implementation SpectaclePreviousThirdWindowCalculationTests
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

- (void)testCalculateAWindowsCGRectInTheFirstHorizontalThirdOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(165.0f, 245.0f, 564.0f, 384.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionPreviousThird];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 4.0f, 480.0f, 873.0f));
}

- (void)testCalculateAWindowsCGRectInTheLastVerticalThirdOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 4.0f, 480.0f, 873.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionPreviousThird];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 4.0f, 1440.0f, 291.0f));
}

- (void)testCalculateAWindowsCGRectInTheSecondVerticalThirdOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 4.0f, 1440.0f, 291.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionPreviousThird];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 295.0f, 1440.0f, 291.0f));
}

- (void)testCalculateAWindowsCGRectInTheFirstVerticalThirdOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 295.0f, 1440.0f, 291.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionPreviousThird];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 586.0f, 1440.0f, 291.0f));
}

- (void)testCalculateAWindowsCGRectInTheLastHorizontalThirdOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 586.0f, 1440.0f, 291.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionPreviousThird];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(960.0f, 4.0f, 480.0f, 873.0f));
}

- (void)testCalculateAWindowsCGRectInTheSecondHorizontalThirdOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(960.0f, 4.0f, 480.0f, 873.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionPreviousThird];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(480.0f, 4.0f, 480.0f, 873.0f));
}

@end
