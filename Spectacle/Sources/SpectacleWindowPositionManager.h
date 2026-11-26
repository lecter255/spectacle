#import <Cocoa/Cocoa.h>

#import "SpectacleMacros.h"
#import "SpectacleWindowAction.h"

typedef void (^SpectacleFailureFeedback)(void);

@class SpectacleAccessibilityElement;
@class SpectacleScreenDetector;
@class SpectacleShortcut;
@class SpectacleWindowPositionCalculator;

@protocol SpectacleWindowMover;

@interface SpectacleWindowPositionManager : NSObject

- (instancetype)initWithScreenDetector:(SpectacleScreenDetector *)screenDetector
              windowPositionCalculator:(SpectacleWindowPositionCalculator *)windowPositionCalculator
                       sharedWorkspace:(NSWorkspace *)sharedWorkspace
                       failureFeedback:(SpectacleFailureFeedback)failureFeedback
                           windowMover:(id<SpectacleWindowMover>)windowMover NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithScreenDetector:(SpectacleScreenDetector *)screenDetector
              windowPositionCalculator:(SpectacleWindowPositionCalculator *)windowPositionCalculator
                       sharedWorkspace:(NSWorkspace *)sharedWorkspace;

SPECTACLE_INIT_AND_NEW_UNAVAILABLE

// Shows the snap HUD after each layout. Off by default so tests never put up windows.
@property (nonatomic) BOOL showsSnapHUD;

- (void)moveFrontmostWindowElement:(SpectacleAccessibilityElement *)frontmostWindowElement
                            action:(SpectacleWindowAction *)action
                           screens:(NSArray<NSScreen *> *)screens
                        mainScreen:(NSScreen *)mainScreen;

- (void)moveFrontmostWindowElement:(SpectacleAccessibilityElement *)frontmostWindowElement
                            action:(SpectacleWindowAction *)action;

// Lays out a half or corner at a given size, outside any resize session (the menu bar panel's
// size chips).
- (void)moveFrontmostWindowElement:(SpectacleAccessibilityElement *)frontmostWindowElement
                            action:(SpectacleWindowAction *)action
                 fractionNumerator:(double)fractionNumerator
               fractionDenominator:(double)fractionDenominator;

- (void)undoLastWindowAction;
- (void)redoLastWindowAction;

@end
