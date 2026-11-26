#import "SpectacleAppDelegate.h"

#import "Spectacle-Swift.h"

#import "SpectacleAccessibilityElement.h"
#import "SpectacleDefaultShortcutHelpers.h"
#import "SpectacleMigratingShortcutStorage.h"
#import "SpectaclePreferencesController.h"
#import "SpectacleScreenDetector.h"
#import "SpectacleShortcut.h"
#import "SpectacleShortcutJSONStorage.h"
#import "SpectacleShortcutManager.h"
#import "SpectacleShortcutTranslations.h"
#import "SpectacleShortcutUserDefaultsStorage.h"
#import "SpectacleUtilities.h"
#import "SpectacleWindowPositionCalculator.h"
#import "SpectacleWindowPositionManager.h"

static BOOL SpectacleIsRunningUnitTests(void)
{
  return NSProcessInfo.processInfo.environment[@"XCTestConfigurationFilePath"] != nil
    || NSClassFromString(@"XCTestCase") != Nil;
}

@interface SpectacleAppDelegate () <SpectacleStatusPanelDelegate>
@end

@implementation SpectacleAppDelegate
{
  SpectacleStatusPanel *_statusPanel;
  NSDictionary<NSString *, NSMenuItem *> *_shortcutMenuItems;
  NSStatusItem *_statusItem;
  id<SpectacleShortcutStorage> _shortcutStorage;
  SpectacleShortcutManager *_shortcutManager;
  SpectacleWindowPositionManager *_windowPositionManager;
  SpectaclePreferencesController *_preferencesController;
  NSTimer *_disableShortcutsForAnHourTimer;
  NSSet<NSString *> *_blacklistedApplications;
  NSMutableSet<NSString *> *_disabledApplications;
  BOOL _shortcutsAreDisabledForAnHour;
  SpectacleAccessibilityPermission *_accessibilityPermission;
  SpectacleDisplaySettingsMenu *_displaySettingsMenu;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  // When the app is acting as the host for unit tests, skip all side effects: registering global
  // hot keys, adding a status item, and (most importantly) presenting the modal accessibility
  // dialog, which would block the test run indefinitely on a CI machine.
  if (SpectacleIsRunningUnitTests()) {
    return;
  }
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  NSNotificationCenter *workspaceNotificationCenter = [NSWorkspace sharedWorkspace].notificationCenter;
  [notificationCenter addObserver:self
                         selector:@selector(enableStatusItem)
                             name:@"SpectacleStatusItemEnabledNotification"
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(disableStatusItem)
                             name:@"SpectacleStatusItemDisabledNotification"
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(updateShortcutMenuItems)
                             name:@"SpectacleShortcutChangedNotification"
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(updateShortcutMenuItems)
                             name:@"SpectacleRestoreDefaultShortcutsNotification"
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(menuDidSendAction:)
                             name:NSMenuDidSendActionNotification
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(inputSourceSelectionDidChange)
                             name:NSTextInputContextKeyboardSelectionDidChangeNotification
                           object:nil];
  [workspaceNotificationCenter addObserver:self
                                  selector:@selector(applicationDidActivate:)
                                      name:NSWorkspaceDidActivateApplicationNotification
                                    object:nil];
  [workspaceNotificationCenter addObserver:self
                                  selector:@selector(applicationDidDeactivate:)
                                      name:NSWorkspaceDidDeactivateApplicationNotification
                                    object:nil];
  [SpectacleUtilities registerDefaultsForBundle:[NSBundle mainBundle]];
  [SpectacleAppearance.shared start];
  _shortcutMenuItems = @{
                         @"MoveToCenter": _moveToCenterShortcutMenuItem,
                         @"MoveToFullscreen": _moveToFullscreenShortcutMenuItem,
                         @"MoveToLeftHalf": _moveToLeftShortcutMenuItem,
                         @"MoveToRightHalf": _moveToRightShortcutMenuItem,
                         @"MoveToTopHalf": _moveToTopShortcutMenuItem,
                         @"MoveToBottomHalf": _moveToBottomShortcutMenuItem,
                         @"MoveToUpperLeft": _moveToUpperLeftShortcutMenuItem,
                         @"MoveToLowerLeft": _moveToLowerLeftShortcutMenuItem,
                         @"MoveToUpperRight": _moveToUpperRightShortcutMenuItem,
                         @"MoveToLowerRight": _moveToLowerRightShortcutMenuItem,
                         @"MoveToNextDisplay": _moveToNextDisplayShortcutMenuItem,
                         @"MoveToPreviousDisplay": _moveToPreviousDisplayShortcutMenuItem,
                         @"MoveToNextThird": _moveToNextThirdShortcutMenuItem,
                         @"MoveToPreviousThird": _moveToPreviousThirdShortcutMenuItem,
                         @"MakeLarger": _makeLargerShortcutMenuItem,
                         @"MakeSmaller": _makeSmallerShortcutMenuItem,
                         @"UndoLastMove": _undoLastMoveShortcutMenuItem,
                         @"RedoLastMove": _redoLastMoveShortcutMenuItem,
                         };
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  // Always disable shortcuts while Spectacle itself is frontmost so the shortcut recorder in the
  // preferences window can capture key combinations that are already registered as hot keys.
  NSMutableSet<NSString *> *blacklistedApplications = [NSMutableSet setWithArray:[userDefaults objectForKey:@"BlacklistedApplications"]];
  NSString *ownBundleIdentifier = NSBundle.mainBundle.bundleIdentifier;
  if (ownBundleIdentifier) {
    [blacklistedApplications addObject:ownBundleIdentifier];
  }
  _blacklistedApplications = blacklistedApplications;
  _disabledApplications = [NSMutableSet setWithArray:[userDefaults objectForKey:@"DisabledApplications"]];
  _shortcutStorage = [[SpectacleMigratingShortcutStorage alloc] initWithShortcutStorage:[SpectacleShortcutUserDefaultsStorage new]
                                                                   migrationDestination:[SpectacleShortcutJSONStorage new]];
  _shortcutManager = [[SpectacleShortcutManager alloc] initWithShortcutStorage:_shortcutStorage];
  // A script error is a bug in Spectacle, not something the user can act on, so log it (visible in
  // Console.app) rather than interrupting them with a modal alert. The action itself fails with the
  // usual beep because the calculator returns no result.
  SpectacleWindowPositionCalculator *windowPositionCalculator = [[SpectacleWindowPositionCalculator alloc] initWithErrorHandler:^(NSString *errorMessage) {
    NSLog(@"Spectacle: window position calculation failed: %@", errorMessage);
  }];
  _windowPositionManager = [[SpectacleWindowPositionManager alloc] initWithScreenDetector:[SpectacleScreenDetector new]
                                                                 windowPositionCalculator:windowPositionCalculator
                                                                          sharedWorkspace:[NSWorkspace sharedWorkspace]];
  _windowPositionManager.showsSnapHUD = YES;
  [self addDisplaySettingsMenuItems];
  _preferencesController = [[SpectaclePreferencesController alloc] initWithShortcutManager:_shortcutManager
                                                                     windowPositionManager:_windowPositionManager
                                                                           shortcutStorage:_shortcutStorage];
  _shortcutsAreDisabledForAnHour = NO;
  [self manageShortcuts];
  [self disableShortcutsIfFrontmostApplicationIsBlacklistedOrDisabled];
  BOOL statusItemEnabled = [userDefaults boolForKey:@"StatusItemEnabled"];
  if (statusItemEnabled) {
    [self enableStatusItem];
  }
  [self updateShortcutMenuItems];
  [self showAccessibilityAccessDialogIfNeeded];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)application hasVisibleWindows:(BOOL)visibleWindows
{
  [self showPreferencesWindow:self];

  return YES;
}

- (IBAction)showPreferencesWindow:(id)sender
{
  [_preferencesController showWindow:sender];
}

- (IBAction)moveFrontmostWindowToFullscreen:(id)sender
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:kSpectacleWindowActionFullscreen];
}

- (IBAction)moveFrontmostWindowToCenter:(id)sender
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:kSpectacleWindowActionCenter];
}

- (IBAction)moveFrontmostWindowToLeftHalf:(id)sender
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:kSpectacleWindowActionLeftHalf];
}

- (IBAction)moveFrontmostWindowToRightHalf:(id)sender
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:kSpectacleWindowActionRightHalf];
}

- (IBAction)moveFrontmostWindowToTopHalf:(id)sender
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:kSpectacleWindowActionTopHalf];
}

- (IBAction)moveFrontmostWindowToBottomHalf:(id)sender
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:kSpectacleWindowActionBottomHalf];
}

- (IBAction)moveFrontmostWindowToUpperLeft:(id)sender
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:kSpectacleWindowActionUpperLeft];
}

- (IBAction)moveFrontmostWindowToLowerLeft:(id)sender
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:kSpectacleWindowActionLowerLeft];
}

- (IBAction)moveFrontmostWindowToUpperRight:(id)sender
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:kSpectacleWindowActionUpperRight];
}

- (IBAction)moveFrontmostWindowToLowerRight:(id)sender
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:kSpectacleWindowActionLowerRight];
}

- (IBAction)moveFrontmostWindowToNextDisplay:(id)sender
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:kSpectacleWindowActionNextDisplay];
}

- (IBAction)moveFrontmostWindowToPreviousDisplay:(id)sender
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:kSpectacleWindowActionPreviousDisplay];
}

- (IBAction)moveFrontmostWindowToNextThird:(id)sender
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:kSpectacleWindowActionNextThird];
}

- (IBAction)moveFrontmostWindowToPreviousThird:(id)sender
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:kSpectacleWindowActionPreviousThird];
}

- (IBAction)makeFrontmostWindowLarger:(id)sender
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:kSpectacleWindowActionLarger];
}

- (IBAction)makeFrontmostWindowSmaller:(id)sender
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:kSpectacleWindowActionSmaller];
}

- (IBAction)undoLastWindowAction:(id)sender
{
  [_windowPositionManager undoLastWindowAction];
}

- (IBAction)redoLastWindowAction:(id)sender
{
  [_windowPositionManager redoLastWindowAction];
}

- (IBAction)disableOrEnableShortcutsForAnHour:(id)sender
{
  NSControlStateValue newMenuItemState = NSControlStateValueMixed;
  if (_shortcutsAreDisabledForAnHour) {
    _shortcutsAreDisabledForAnHour = NO;
    [_disableShortcutsForAnHourTimer invalidate];
    [self enableShortcutsIfPermitted];
    newMenuItemState = NSControlStateValueOff;
  } else {
    _shortcutsAreDisabledForAnHour = YES;
    _disableShortcutsForAnHourTimer = [NSTimer scheduledTimerWithTimeInterval:3600
                                                                       target:self
                                                                     selector:@selector(disableOrEnableShortcutsForAnHour:)
                                                                     userInfo:nil
                                                                      repeats:NO];
    [_shortcutManager unregisterShortcuts];
    newMenuItemState = NSControlStateValueOn;
  }
  self.disableShortcutsForAnHourMenuItem.state = newMenuItemState;
}

- (IBAction)disableOrEnableShortcutsForApplication:(id)sender
{
  NSRunningApplication *frontmostApplication = [NSWorkspace sharedWorkspace].frontmostApplication;
  NSString *bundleIdentifier = frontmostApplication.bundleIdentifier;
  // Some processes (e.g. bare executables or certain Java apps) have no bundle identifier;
  // inserting nil into the set would raise and crash Spectacle.
  if (!bundleIdentifier) {
    NSBeep();
    return;
  }
  if ([_disabledApplications containsObject:bundleIdentifier]) {
    [_disabledApplications removeObject:bundleIdentifier];
    [self enableShortcutsIfPermitted];
    self.disableShortcutsForApplicationMenuItem.state = NSControlStateValueOff;
  } else {
    [_disabledApplications addObject:bundleIdentifier];
    [_shortcutManager unregisterShortcuts];
    self.disableShortcutsForApplicationMenuItem.state = NSControlStateValueOn;
  }
  [NSUserDefaults.standardUserDefaults setObject:_disabledApplications.allObjects forKey:@"DisabledApplications"];
}

- (IBAction)openSystemPreferences:(id)sender
{
  // This URL opens Privacy & Security > Accessibility in both System Preferences (macOS 12 and
  // earlier) and System Settings (macOS 13+). It replaces a bundled AppleScript that drove the old
  // Security.prefPane UI, which no longer exists and required an extra Automation permission.
  // The dialog stays open as a reminder and closes itself once access is granted.
  NSURL *accessibilitySettingsURL = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"];
  [[NSWorkspace sharedWorkspace] openURL:accessibilitySettingsURL];
}

- (void)showAccessibilityAccessDialogIfNeeded
{
  if (SpectacleAccessibilityPermission.isGranted) {
    return;
  }
  // The dialog used to be app-modal, which blocked the menu bar item and preferences until the
  // user clicked a button, and never noticed when access was granted. Now it is an ordinary window
  // that closes itself as soon as access is granted.
  NSWindow *dialog = self.accessiblityAccessDialogWindow;
  [dialog center];
  [NSApp activateIgnoringOtherApps:YES];
  [dialog makeKeyAndOrderFront:self];
  _accessibilityPermission = [SpectacleAccessibilityPermission new];
  [_accessibilityPermission waitUntilGrantedCheckingEvery:1.0 completion:^{
    [dialog orderOut:nil];
  }];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)manageShortcuts
{
  SpectacleShortcutAction action = ^(SpectacleShortcut *shortcut) {
    [self->_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                                      action:shortcut.windowAction];
  };
  NSArray<SpectacleShortcut *> *shortcuts = [_shortcutStorage loadShortcutsWithAction:action];
  if (shortcuts.count != 0) {
    [_shortcutManager manageShortcuts:shortcuts];
  } else {
    [_shortcutManager manageShortcuts:SpectacleDefaultShortcutsWithAction(action)];
  }
}

// Adds the Appearance submenu and the "Show Snap HUD" toggle just above Preferences, until the new
// settings window takes them over.
- (void)addDisplaySettingsMenuItems
{
  _displaySettingsMenu = [SpectacleDisplaySettingsMenu new];
  NSInteger index = _statusItemMenu.numberOfItems;
  for (NSInteger i = 0; i < _statusItemMenu.numberOfItems; i++) {
    if ([_statusItemMenu itemAtIndex:i].action == @selector(showPreferencesWindow:)) {
      index = i;
      break;
    }
  }
  for (NSMenuItem *menuItem in _displaySettingsMenu.menuItems) {
    [_statusItemMenu insertItem:menuItem atIndex:index++];
  }
  [_statusItemMenu insertItem:[NSMenuItem separatorItem] atIndex:index];
}

- (void)enableStatusItem
{
  if (_statusItem) {
    return;
  }
  _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  NSImage *statusImage = [NSBundle.mainBundle imageForResource:@"Spectacle Status Item"];
  [statusImage setTemplate:YES];
  _statusItem.button.image = statusImage;
  _statusItem.button.toolTip = [@"Spectacle " stringByAppendingString:SpectacleUtilities.applicationVersion];
  // A click opens the layout panel; a right-click or Control-click opens the full menu.
  _statusItem.button.target = self;
  _statusItem.button.action = @selector(statusItemClicked:);
  [_statusItem.button sendActionOn:NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp];
  if (!_statusPanel) {
    _statusPanel = [SpectacleStatusPanel new];
    _statusPanel.delegate = self;
  }
}

- (void)statusItemClicked:(id)sender
{
  NSEvent *event = NSApp.currentEvent;
  BOOL wantsFullMenu = event.type == NSEventTypeRightMouseUp
    || (event.modifierFlags & NSEventModifierFlagControl) != 0;
  if (wantsFullMenu) {
    [_statusPanel close];
    [self statusPanelShowFullMenu];
  } else {
    [_statusPanel toggleRelativeTo:_statusItem.button];
  }
}

#pragma mark - SpectacleStatusPanelDelegate

- (void)statusPanelPerformAction:(NSString *)actionName
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:actionName];
}

- (void)statusPanelPerformAction:(NSString *)actionName
               fractionNumerator:(double)fractionNumerator
             fractionDenominator:(double)fractionDenominator
{
  [_windowPositionManager moveFrontmostWindowElement:[SpectacleAccessibilityElement frontmostWindowElement]
                                              action:actionName
                                   fractionNumerator:fractionNumerator
                                 fractionDenominator:fractionDenominator];
}

- (void)statusPanelUndo
{
  [_windowPositionManager undoLastWindowAction];
}

- (void)statusPanelShowPreferences
{
  [NSApp activateIgnoringOtherApps:YES];
  [self showPreferencesWindow:self];
}

- (void)statusPanelShowFullMenu
{
  if (!_statusItem) {
    return;
  }
  // Attaching the menu only while it is open keeps plain clicks going to the panel. The click
  // tracks the menu until it closes.
  _statusItem.menu = _statusItemMenu;
  [_statusItem.button performClick:nil];
  _statusItem.menu = nil;
}

- (CGRect)statusPanelFrontmostWindowRect
{
  SpectacleAccessibilityElement *frontmostWindowElement = [SpectacleAccessibilityElement frontmostWindowElement];
  if (!frontmostWindowElement || frontmostWindowElement.isSheet || frontmostWindowElement.isSystemDialog) {
    return CGRectNull;
  }
  return [frontmostWindowElement rectOfElement];
}

- (NSDictionary<NSString *, NSString *> *)statusPanelShortcutDisplayStrings
{
  NSMutableDictionary<NSString *, NSString *> *displayStrings = [NSMutableDictionary new];
  for (SpectacleShortcut *shortcut in _shortcutManager.shortcuts) {
    if (!shortcut.isClearedShortcut && shortcut.windowAction && shortcut.displayString) {
      displayStrings[shortcut.windowAction] = shortcut.displayString;
    }
  }
  return displayStrings;
}

- (void)disableStatusItem
{
  if (!_statusItem) {
    return;
  }
  [_statusPanel close];
  [NSStatusBar.systemStatusBar removeStatusItem:_statusItem];
  _statusItem = nil;
}

- (void)updateShortcutMenuItems
{
  for (NSString *shortcutName in _shortcutMenuItems.allKeys) {
    NSMenuItem *shortcutMenuItem = _shortcutMenuItems[shortcutName];
    SpectacleShortcut *shortcut = [_shortcutManager shortcutForShortcutName:shortcutName];
    if (shortcut) {
      shortcutMenuItem.keyEquivalent = [SpectacleTranslateKeyCode(shortcut.shortcutKeyCode) lowercaseString];
      shortcutMenuItem.keyEquivalentModifierMask = SpectacleConvertModifiersToCocoaIfNecessary(shortcut.shortcutModifiers);
    } else {
      shortcutMenuItem.keyEquivalent = @"";
      shortcutMenuItem.keyEquivalentModifierMask = 0;
    }
  }
}

- (void)enableShortcutsIfPermitted
{
  NSRunningApplication *frontmostApplication = [NSWorkspace sharedWorkspace].frontmostApplication;
  // Do not enable shortcuts if they should remain disabled for an hour.
  if (_shortcutsAreDisabledForAnHour) {
    return;
  }
  // Do not enable shortcuts if the application is blacklisted or disabled.
  if ([_blacklistedApplications containsObject:frontmostApplication.bundleIdentifier]
      || [_disabledApplications containsObject:frontmostApplication.bundleIdentifier]) {
    return;
  }
  [_shortcutManager registerShortcuts];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"SpectacleShortcutChangedNotification" object:self];
}

- (void)disableShortcutsIfFrontmostApplicationIsBlacklistedOrDisabled
{
  NSRunningApplication *frontmostApplication = [NSWorkspace sharedWorkspace].frontmostApplication;
  // Do not disable shortcuts if the application is not blacklisted or disabled.
  if (![_blacklistedApplications containsObject:frontmostApplication.bundleIdentifier]
      && ![_disabledApplications containsObject:frontmostApplication.bundleIdentifier]) {
    return;
  }
  [_shortcutManager unregisterShortcuts];
}

- (void)applicationDidActivate:(NSNotification *)notification
{
  NSRunningApplication *application = notification.userInfo[NSWorkspaceApplicationKey];
  if ([_blacklistedApplications containsObject:application.bundleIdentifier]
      || [_disabledApplications containsObject:application.bundleIdentifier]) {
    [_shortcutManager unregisterShortcuts];
  }
}

- (void)applicationDidDeactivate:(NSNotification *)notification
{
  NSRunningApplication *application = notification.userInfo[NSWorkspaceApplicationKey];
  if ([_blacklistedApplications containsObject:application.bundleIdentifier]
      || [_disabledApplications containsObject:application.bundleIdentifier]) {
    [self enableShortcutsIfPermitted];
  }
}

- (void)menuWillOpen:(NSMenu *)menu
{
  [_displaySettingsMenu refresh];
  NSRunningApplication *frontmostApplication = [NSWorkspace sharedWorkspace].frontmostApplication;
  self.disableShortcutsForApplicationMenuItem.hidden = NO;
  if ([_blacklistedApplications containsObject:frontmostApplication.bundleIdentifier]) {
    self.disableShortcutsForApplicationMenuItem.hidden = YES;
  } else {
    self.disableShortcutsForApplicationMenuItem.title =
      [NSString stringWithFormat:NSLocalizedString(@"MenuItemTitleDisableShortcutsForApplication", @"The menu item title that displays the application to disable shortcuts for"), frontmostApplication.localizedName];
  }
  if ([_disabledApplications containsObject:frontmostApplication.bundleIdentifier]) {
    self.disableShortcutsForApplicationMenuItem.state = NSControlStateValueOn;
  } else {
    self.disableShortcutsForApplicationMenuItem.state = NSControlStateValueOff;
  }
}

- (void)menuDidSendAction:(NSNotification *)notification
{
  NSMenuItem *menuItem = notification.userInfo[@"MenuItem"];
  if (menuItem.tag == -1) {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
  }
}

- (void)inputSourceSelectionDidChange
{
  [_preferencesController loadRegisteredShortcuts];
  [self updateShortcutMenuItems];
}

@end
