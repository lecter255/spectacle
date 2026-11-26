#import "SpectacleWindowPositionCalculator.h"

#import "Spectacle-Swift.h"
#import "SpectacleWindowPositionCalculationResult.h"

@implementation SpectacleWindowPositionCalculator

- (instancetype)initWithErrorHandler:(void(^)(NSString *message))errorHandler
{
  // The layout calculations used to be JavaScript, which could throw; the error handler reported
  // those exceptions. The Swift implementation in SpectacleCore can't fail, so the handler is no
  // longer called. The initializer is kept until callers are ported to Swift.
  return [super init];
}

- (SpectacleWindowPositionCalculationResult *)calculateWindowRect:(CGRect)windowRect
                                       visibleFrameOfSourceScreen:(CGRect)visibleFrameOfSourceScreen
                                  visibleFrameOfDestinationScreen:(CGRect)visibleFrameOfDestinationScreen
                                                           action:(SpectacleWindowAction *)action
{
  return [self calculateWindowRect:windowRect
        visibleFrameOfSourceScreen:visibleFrameOfSourceScreen
   visibleFrameOfDestinationScreen:visibleFrameOfDestinationScreen
                            action:action
                 fractionNumerator:1
               fractionDenominator:2];
}

- (SpectacleWindowPositionCalculationResult *)calculateWindowRect:(CGRect)windowRect
                                       visibleFrameOfSourceScreen:(CGRect)visibleFrameOfSourceScreen
                                  visibleFrameOfDestinationScreen:(CGRect)visibleFrameOfDestinationScreen
                                                           action:(SpectacleWindowAction *)action
                                                fractionNumerator:(double)fractionNumerator
                                              fractionDenominator:(double)fractionDenominator
{
  CGRect calculatedWindowRect = [SpectacleWindowLayoutBridge frameForAction:action
                                                                 windowRect:windowRect
                                                 visibleFrameOfSourceScreen:visibleFrameOfSourceScreen
                                            visibleFrameOfDestinationScreen:visibleFrameOfDestinationScreen
                                                          fractionNumerator:fractionNumerator
                                                        fractionDenominator:fractionDenominator];
  if (CGRectIsNull(calculatedWindowRect)) {
    return nil;
  }
  return [SpectacleWindowPositionCalculationResult resultWithAction:action windowRect:calculatedWindowRect];
}

@end
