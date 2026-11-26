#import "SpectacleScreenDetector.h"

#import "Spectacle-Swift.h"
#import "SpectacleAccessibilityElement.h"
#import "SpectacleScreenDetectionResult.h"

// The screen selection logic lives in SpectacleCore (ScreenSelection.swift), where it is tested
// on its own. This class maps NSScreen objects to and from the frames that logic works with.
@implementation SpectacleScreenDetector

- (SpectacleScreenDetectionResult *)screenWithAction:(SpectacleWindowAction *)action
                              frontmostWindowElement:(SpectacleAccessibilityElement *)frontmostWindowElement
                                             screens:(NSArray<NSScreen *> *)screens
                                          mainScreen:(NSScreen *)mainScreen
{
  NSMutableArray<NSValue *> *screenFrames = [NSMutableArray arrayWithCapacity:screens.count];
  for (NSScreen *screen in screens) {
    [screenFrames addObject:[NSValue valueWithRect:screen.frame]];
  }
  // Accessibility coordinates are relative to the top left of the primary screen (the one with the
  // menu bar), which is always the first in NSScreen.screens.
  CGFloat primaryScreenHeight = NSScreen.screens.firstObject.frame.size.height;
  NSUInteger mainScreenIndex = mainScreen ? [screens indexOfObject:mainScreen] : NSNotFound;
  NSInteger sourceIndex = [SpectacleScreenSelectionBridge screenIndexContainingWindowRect:[frontmostWindowElement rectOfElement]
                                                                             screenFrames:screenFrames
                                                                      primaryScreenHeight:primaryScreenHeight
                                                                            fallbackIndex:mainScreenIndex == NSNotFound ? -1 : (NSInteger)mainScreenIndex];
  NSScreen *sourceScreen = sourceIndex >= 0 ? screens[(NSUInteger)sourceIndex] : mainScreen;
  NSScreen *destinationScreen = sourceScreen;
  if (SpectacleIsMovingToDisplayWindowAction(action)) {
    destinationScreen = nil;
    if (sourceIndex >= 0) {
      NSInteger destinationIndex = [SpectacleScreenSelectionBridge adjacentScreenIndexTo:sourceIndex
                                                                           screenFrames:screenFrames
                                                                                   next:SpectacleIsNextDisplayWindowAction(action)];
      if (destinationIndex >= 0) {
        destinationScreen = screens[(NSUInteger)destinationIndex];
      }
    }
  }
  return [SpectacleScreenDetectionResult resultWithSourceScreen:sourceScreen destinationScreen:destinationScreen];
}

@end
