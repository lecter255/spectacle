#import <XCTest/XCTest.h>

#import "SpectacleTestHelpers.h"
#import "SpectacleWindowPositionCalculationResult.h"
#import "SpectacleWindowPositionCalculator.h"

@interface SpectaclePreviousDisplayWindowCalculationTests : XCTestCase
@end

@implementation SpectaclePreviousDisplayWindowCalculationTests
{
  CGRect visibleFrameSourceScreen;
  CGRect visibleFrameDestinationScreen;
  SpectacleWindowPositionCalculator *windowPositionCalculator;
}

- (void)setUp
{
  [super setUp];
  visibleFrameSourceScreen = CGRectMake(0.0f, 4.0f, 1440.0f, 873.0f);
  visibleFrameDestinationScreen = CGRectMake(1440.0f, 4.0f, 1440.0f, 873.0f);
  __weak __typeof__(self) weakSelf = self;
  windowPositionCalculator = [[SpectacleWindowPositionCalculator alloc] initWithErrorHandler:^(NSString *message) {
    __strong __typeof__(weakSelf) self = weakSelf;
    XCTFail(@"%@", message);
  }];
}

- (void)testCalculateACenteredWindowsCGRectInThePreviousDisplay
{
  SpectacleWindowPositionCalculationResult *result = [windowPositionCalculator calculateWindowRect:CGRectMake(165.0f, 245.0f, 564.0f, 384.0f)
                                                                        visibleFrameOfSourceScreen:visibleFrameSourceScreen
                                                                   visibleFrameOfDestinationScreen:visibleFrameDestinationScreen
                                                                                            action:kSpectacleWindowActionPreviousDisplay];
  SpectacleAssertEqualRects(result.windowRect, CGRectMake(1878.0f, 249.0f, 564.0f, 384.0f));
}

@end
