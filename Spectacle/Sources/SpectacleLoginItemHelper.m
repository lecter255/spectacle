#import "SpectacleLoginItemHelper.h"

@import ServiceManagement;

// On macOS 13 and later, login items are managed through SMAppService. The LSSharedFileList
// session login item API was deprecated in 10.11 and no longer works on current macOS releases,
// so it is only used as a fallback on older systems.

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation SpectacleLoginItemHelper

+ (BOOL)isLoginItemEnabledForBundle:(NSBundle *)bundle
{
  if (@available(macOS 13.0, *)) {
    return SMAppService.mainAppService.status == SMAppServiceStatusEnabled;
  }
  LSSharedFileListRef sharedFileList = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
  NSString *applicationPath = bundle.bundlePath;
  BOOL result = NO;
  if (sharedFileList) {
    UInt32 seedValue;
    NSArray *sharedFileListArray = CFBridgingRelease(LSSharedFileListCopySnapshot(sharedFileList, &seedValue));
    for (id sharedFile in sharedFileListArray) {
      LSSharedFileListItemRef sharedFileListItem = (__bridge LSSharedFileListItemRef)sharedFile;
      CFURLRef applicationPathURL = NULL;
      LSSharedFileListItemResolve(sharedFileListItem, 0, (CFURLRef *)&applicationPathURL, NULL);
      if (applicationPathURL != NULL) {
        NSString *resolvedApplicationPath = [(__bridge NSURL *)applicationPathURL path];
        CFRelease(applicationPathURL);
        if ([resolvedApplicationPath compare:applicationPath] == NSOrderedSame) {
          result = YES;
          break;
        }
      }
    }
    CFRelease(sharedFileList);
  } else {
    NSLog(@"Unable to create the shared file list.");
  }
  return result;
}

+ (void)enableLoginItemForBundle:(NSBundle *)bundle
{
  if (@available(macOS 13.0, *)) {
    NSError *error = nil;
    if (![SMAppService.mainAppService registerAndReturnError:&error]) {
      NSLog(@"Unable to register the login item: %@", error);
    }
    return;
  }
  LSSharedFileListRef sharedFileList = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
  NSString *applicationPath = bundle.bundlePath;
  NSURL *applicationPathURL = [NSURL fileURLWithPath:applicationPath];
  if (sharedFileList) {
    LSSharedFileListItemRef sharedFileListItem = LSSharedFileListInsertItemURL(sharedFileList,
                                                                               kLSSharedFileListItemLast,
                                                                               NULL,
                                                                               NULL,
                                                                               (__bridge CFURLRef)applicationPathURL,
                                                                               NULL,
                                                                               NULL);
    if (sharedFileListItem) {
      CFRelease(sharedFileListItem);
    }
    CFRelease(sharedFileList);
  } else {
    NSLog(@"Unable to create the shared file list.");
  }
}

+ (void)disableLoginItemForBundle:(NSBundle *)bundle
{
  if (@available(macOS 13.0, *)) {
    NSError *error = nil;
    if (![SMAppService.mainAppService unregisterAndReturnError:&error]) {
      NSLog(@"Unable to unregister the login item: %@", error);
    }
    return;
  }
  LSSharedFileListRef sharedFileList = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
  NSString *applicationPath = bundle.bundlePath;
  if (sharedFileList) {
    UInt32 seedValue;
    NSArray *sharedFileListArray = CFBridgingRelease(LSSharedFileListCopySnapshot(sharedFileList, &seedValue));
    for (id sharedFile in sharedFileListArray) {
      LSSharedFileListItemRef sharedFileListItem = (__bridge LSSharedFileListItemRef)sharedFile;
      CFURLRef applicationPathURL = NULL;
      if (LSSharedFileListItemResolve(sharedFileListItem, 0, &applicationPathURL, NULL) == noErr) {
        NSString *resolvedApplicationPath = [(__bridge NSURL *)applicationPathURL path];
        if ([resolvedApplicationPath compare:applicationPath] == NSOrderedSame) {
          LSSharedFileListItemRemove(sharedFileList, sharedFileListItem);
        }
        CFRelease(applicationPathURL);
      }
    }
    CFRelease(sharedFileList);
  } else {
    NSLog(@"Unable to create the shared file list.");
  }
}

@end

#pragma clang diagnostic pop
