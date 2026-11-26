#import "SpectacleShortcutUserDefaultsStorage.h"

@implementation SpectacleShortcutUserDefaultsStorage

+ (void)initialize
{
  [NSKeyedUnarchiver setClass:[SpectacleShortcut class] forClassName:@"SpectacleHotKey"];
  [NSKeyedUnarchiver setClass:[SpectacleShortcut class] forClassName:@"ZeroKitHotKey"];
  [NSKeyedUnarchiver setClass:[SpectacleShortcut class] forClassName:@"ZKHotKey"];
}

- (NSArray<SpectacleShortcut *> *)loadShortcutsWithAction:(SpectacleShortcutAction)action
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary<NSString *, NSData *> *shortcutsFromUserDefaults = [NSMutableDictionary new];
  for (NSString *shortcutName in [self shortcutNames]) {
    shortcutsFromUserDefaults[shortcutName] = [userDefaults dataForKey:shortcutName];
  }
  return [self shortcutsFromDictionary:shortcutsFromUserDefaults action:action];
}

- (void)storeShortcuts:(NSArray<SpectacleShortcut *> *)shortcuts
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  for (SpectacleShortcut *shortcut in shortcuts) {
    NSData *shortcutData = SpectacleArchiveShortcut(shortcut);
    NSString *shortcutName = shortcut.shortcutName;
    if (![shortcutData isEqualToData:[userDefaults dataForKey:shortcutName]]) {
      [userDefaults setObject:shortcutData forKey:shortcutName];
    }
  }
}

- (BOOL)isMigrationNeeded
{
  return NO;
}

- (NSArray<NSString *> *)shortcutNames
{
  return @[
           @"MoveToCenter",
           @"MoveToFullscreen",
           @"MoveToLeftHalf",
           @"MoveToRightHalf",
           @"MoveToTopHalf",
           @"MoveToBottomHalf",
           @"MoveToUpperLeft",
           @"MoveToLowerLeft",
           @"MoveToUpperRight",
           @"MoveToLowerRight",
           @"MoveToNextDisplay",
           @"MoveToPreviousDisplay",
           @"MoveToNextThird",
           @"MoveToPreviousThird",
           @"MakeLarger",
           @"MakeSmaller",
           @"UndoLastMove",
           @"RedoLastMove",
           ];
}

- (NSArray<SpectacleShortcut *> *)shortcutsFromDictionary:(NSDictionary<NSString *, NSData *> *)dictionary
                                                   action:(SpectacleShortcutAction)action
{
  NSMutableArray<SpectacleShortcut *> *shortcuts = [NSMutableArray new];
  for (NSData *shortcutData in dictionary.allValues) {
    SpectacleShortcut *shortcut = SpectacleUnarchiveShortcut(shortcutData);
    if (shortcut) {
      [shortcuts addObject:[shortcut copyWithShortcutAction:action]];
    }
  }
  return shortcuts;
}

// These read and write the legacy keyed-archive format, which predates secure coding. Secure coding
// stays off so shortcuts saved by older versions (including under the SpectacleHotKey, ZeroKitHotKey
// and ZKHotKey class names mapped in +initialize) can still be read and migrated.
static NSData *SpectacleArchiveShortcut(SpectacleShortcut *shortcut)
{
  NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
  [archiver encodeObject:shortcut forKey:NSKeyedArchiveRootObjectKey];
  [archiver finishEncoding];
  return archiver.encodedData;
}

static SpectacleShortcut *SpectacleUnarchiveShortcut(NSData *data)
{
  NSError *error;
  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&error];
  if (!unarchiver) {
    NSLog(@"Spectacle: unable to read a stored shortcut: %@", error.localizedDescription);
    return nil;
  }
  unarchiver.requiresSecureCoding = NO;
  id shortcut = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
  [unarchiver finishDecoding];
  return [shortcut isKindOfClass:[SpectacleShortcut class]] ? shortcut : nil;
}

@end
