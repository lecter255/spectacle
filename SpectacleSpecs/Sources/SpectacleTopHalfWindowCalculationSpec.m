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
}

- (void)setUp
{
  [super setUp];
  visibleFrameSourceScreen = CGRectMake(0.0f, 4.0f, 1440.0f, 873.0f);
  visibleFrameDestinationScreen = CGRectMake(0.0f, 4.0f, 1440.0f, 873.0f);
  __weak __typeof__(self) weakSelf = self;
  windowPositionCalculator = [[SpectacleWindowPositionCalculator alloc] initWithErrorHandler:^(NSString *message) {
    __strong __typeof__(weakSelf) self = weakSelf;
    XCTFail(@"%@", message);
  }];
}

- (void)testCalculateAWindowsCGRectInTheTopHalfOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(165.0f, 245.0f, 564.0f, 384.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionTopHalf];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 441.0f, 1440.0f, 436.0f));
}

- (void)testCalculateAWindowsCGRectInTheTopTwoThirdsOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 441.0f, 1440.0f, 436.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionTopHalf];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 295.0f, 1440.0f, 582.0f));
}

- (void)testCalculateAWindowsCGRectInTheTopOneThirdOfTheScreen
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(0.0f, 295.0f, 1440.0f, 582.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionTopHalf];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(0.0f, 586.0f, 1440.0f, 291.0f));
}

@end
