#import <Foundation/Foundation.h>

#import "SpectacleMacros.h"
#import "SpectacleWindowAction.h"

@class SpectacleWindowPositionCalculationResult;

@interface SpectacleWindowPositionCalculator : NSObject

- (instancetype)initWithErrorHandler:(void(^)(NSString *message))errorHandler NS_DESIGNATED_INITIALIZER;

- (SpectacleWindowPositionCalculationResult *)calculateWindowRect:(CGRect)windowRect
                                       visibleFrameOfSourceScreen:(CGRect)visibleFrameOfSourceScreen
                                  visibleFrameOfDestinationScreen:(CGRect)visibleFrameOfDestinationScreen
                                                           action:(SpectacleWindowAction *)action;

/// Like the method above, but for halves and corners the window takes `fractionNumerator /
/// fractionDenominator` of the screen along the action's axis instead of 1/2. Other actions ignore
/// the fraction. The method above calls this one with 1/2.
- (SpectacleWindowPositionCalculationResult *)calculateWindowRect:(CGRect)windowRect
                                       visibleFrameOfSourceScreen:(CGRect)visibleFrameOfSourceScreen
                                  visibleFrameOfDestinationScreen:(CGRect)visibleFrameOfDestinationScreen
                                                           action:(SpectacleWindowAction *)action
                                                fractionNumerator:(double)fractionNumerator
                                              fractionDenominator:(double)fractionDenominator;

SPECTACLE_INIT_AND_NEW_UNAVAILABLE

@end
