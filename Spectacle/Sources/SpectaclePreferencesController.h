#import <Cocoa/Cocoa.h>

#import "SpectacleShortcutRecorderDelegate.h"

@class SpectacleShortcutManager;
@class SpectacleWindowPositionManager;

@protocol SpectacleShortcutStorage;

// Owns the settings window (built in SwiftUI by SpectacleSettingsWindowController) and the shortcut
// recorders and settings it shows.
@interface SpectaclePreferencesController : NSWindowController <SpectacleShortcutRecorderDelegate>

- (instancetype)initWithShortcutManager:(SpectacleShortcutManager *)shortcutManager
                  windowPositionManager:(SpectacleWindowPositionManager *)windowPositionManager
                        shortcutStorage:(id<SpectacleShortcutStorage>)shortcutStorage;

- (void)loadRegisteredShortcuts;

@end
