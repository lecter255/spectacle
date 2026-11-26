#import "SpectaclePreferencesController.h"

#import "Spectacle-Swift.h"
#import "SpectacleAccessibilityElement.h"
#import "SpectacleDefaultShortcutHelpers.h"
#import "SpectacleLoginItemHelper.h"
#import "SpectacleRegisteredShortcutValidator.h"
#import "SpectacleShortcut.h"
#import "SpectacleShortcutManager.h"
#import "SpectacleShortcutRecorder.h"
#import "SpectacleShortcutStorage.h"
#import "SpectacleShortcutValidation.h"
#import "SpectacleUtilities.h"
#import "SpectacleWindowPositionManager.h"

@interface SpectaclePreferencesController () <SpectacleSettingsDataSource>
@end

@implementation SpectaclePreferencesController
{
  SpectacleShortcutManager *_shortcutManager;
  SpectacleWindowPositionManager *_windowPositionManager;
  id<SpectacleShortcutStorage> _shortcutStorage;
  NSDictionary<NSString *, SpectacleShortcutRecorder *> *_shortcutRecorders;
  SpectacleSettingsWindowController *_settingsWindowController;
}

- (instancetype)initWithShortcutManager:(SpectacleShortcutManager *)shortcutManager
                  windowPositionManager:(SpectacleWindowPositionManager *)windowPositionManager
                        shortcutStorage:(id<SpectacleShortcutStorage>)shortcutStorage
{
  if (self = [super initWithWindow:nil]) {
    _shortcutManager = shortcutManager;
    _windowPositionManager = windowPositionManager;
    _shortcutStorage = shortcutStorage;
    NSMutableDictionary<NSString *, SpectacleShortcutRecorder *> *shortcutRecorders = [NSMutableDictionary new];
    for (NSString *shortcutName in @[@"MoveToCenter", @"MoveToFullscreen", @"MoveToLeftHalf", @"MoveToRightHalf",
                                     @"MoveToTopHalf", @"MoveToBottomHalf", @"MoveToUpperLeft", @"MoveToLowerLeft",
                                     @"MoveToUpperRight", @"MoveToLowerRight", @"MoveToNextDisplay",
                                     @"MoveToPreviousDisplay", @"MoveToNextThird", @"MoveToPreviousThird",
                                     @"MakeLarger", @"MakeSmaller", @"UndoLastMove", @"RedoLastMove"]) {
      shortcutRecorders[shortcutName] = [[SpectacleShortcutRecorder alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    }
    _shortcutRecorders = shortcutRecorders;
    [self loadRegisteredShortcuts];
    _settingsWindowController = [[SpectacleSettingsWindowController alloc] initWithDataSource:self];
    self.window = _settingsWindowController.window;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(loadRegisteredShortcuts)
                               name:@"SpectacleShortcutChangedNotification"
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(loadRegisteredShortcuts)
                               name:@"SpectacleRestoreDefaultShortcutsNotification"
                             object:nil];
  }
  return self;
}

- (void)showWindow:(id)sender
{
  [_settingsWindowController reload];
  [super showWindow:sender];
}

- (void)shortcutRecorder:(SpectacleShortcutRecorder *)shortcutRecorder
   didReceiveNewShortcut:(SpectacleShortcut *)shortcut
{
  [_shortcutManager updateShortcut:[shortcut copyWithShortcutAction:^(SpectacleShortcut *shortcut) {
    [self->_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                                      action:shortcut.windowAction];
  }]];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"SpectacleShortcutChangedNotification" object:self];
}

- (void)shortcutRecorder:(SpectacleShortcutRecorder *)shortcutRecorder
didClearExistingShortcut:(SpectacleShortcut *)shortcut
{
  [_shortcutManager clearShortcut:shortcut];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"SpectacleShortcutChangedNotification" object:self];
}

- (void)loadRegisteredShortcuts
{
  for (NSString *shortcutName in _shortcutRecorders.allKeys) {
    SpectacleShortcutRecorder *shortcutRecorder = _shortcutRecorders[shortcutName];
    SpectacleShortcut *shortcut = [_shortcutManager shortcutForShortcutName:shortcutName];
    shortcutRecorder.shortcutName = shortcutName;
    shortcutRecorder.shortcut = shortcut;
    shortcutRecorder.delegate = self;
    shortcutRecorder.shortcutValidation =
    [[SpectacleShortcutValidation alloc] initWithShortcutManager:_shortcutManager
                                                      validators:@[
                                                                   [SpectacleRegisteredShortcutValidator new],
                                                                   ]];
  }
  [_settingsWindowController reload];
}

#pragma mark - SpectacleSettingsDataSource

- (NSView *)settingsShortcutRecorderForShortcutName:(NSString *)shortcutName
{
  return _shortcutRecorders[shortcutName] ?: [NSView new];
}

- (NSString *)settingsShortcutDisplayStringForShortcutName:(NSString *)shortcutName
{
  SpectacleShortcut *shortcut = [_shortcutManager shortcutForShortcutName:shortcutName];
  if (!shortcut || shortcut.isClearedShortcut) {
    return nil;
  }
  return shortcut.displayString;
}

- (void)settingsRestoreDefaultShortcuts
{
  [SpectacleUtilities displayRestoreDefaultsAlertWithConfirmationCallback:^() {
    NSArray<SpectacleShortcut *> *shortcuts = SpectacleDefaultShortcutsWithAction(^(SpectacleShortcut *shortcut) {
      [self->_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                                        action:shortcut.windowAction];
    });
    [self->_shortcutManager updateShortcuts:shortcuts];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SpectacleRestoreDefaultShortcutsNotification"
                                                        object:self];
  }];
}

- (BOOL)settingsIsLoginItemEnabled
{
  return [SpectacleLoginItemHelper isLoginItemEnabledForBundle:NSBundle.mainBundle];
}

- (void)settingsSetLoginItemEnabled:(BOOL)enabled
{
  if (enabled) {
    [SpectacleLoginItemHelper enableLoginItemForBundle:NSBundle.mainBundle];
  } else {
    [SpectacleLoginItemHelper disableLoginItemForBundle:NSBundle.mainBundle];
  }
}

- (BOOL)settingsIsStatusItemEnabled
{
  return [NSUserDefaults.standardUserDefaults boolForKey:@"StatusItemEnabled"];
}

- (void)settingsSetStatusItemEnabled:(BOOL)enabled
{
  NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
  if ([userDefaults boolForKey:@"StatusItemEnabled"] == enabled) {
    return;
  }
  __block BOOL confirmed = YES;
  if (!enabled && ![userDefaults boolForKey:@"BackgroundAlertSuppressed"]) {
    // Hiding the icon leaves the app running with no visible way back, so say how to return.
    [SpectacleUtilities displayRunningInBackgroundAlertWithCallback:^(BOOL isConfirmed, BOOL isSuppressed) {
      confirmed = isConfirmed;
      [userDefaults setBool:isSuppressed forKey:@"BackgroundAlertSuppressed"];
    }];
  }
  if (!confirmed) {
    return;
  }
  [userDefaults setBool:enabled forKey:@"StatusItemEnabled"];
  NSString *notificationName = enabled ? @"SpectacleStatusItemEnabledNotification" : @"SpectacleStatusItemDisabledNotification";
  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
