#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "SpectacleShortcut.h"
#import "SpectacleTestHelpers.h"

@interface SpectacleShortcutTests : XCTestCase
@end

@implementation SpectacleShortcutTests

- (void)testBeInitializedWithAKeyBinding
{
  SpectacleShortcut *shortcut = [[SpectacleShortcut alloc] initWithShortcutName:@"MoveToCenter"
                                                             shortcutKeyBinding:@"option+command+c"];
  XCTAssertEqual(shortcut.shortcutKeyCode, kVK_ANSI_C);
  XCTAssertEqual(shortcut.shortcutModifiers, optionKey | cmdKey);
}

- (void)testBeCopiedWithANewShortcutAction
{
  SpectacleShortcut *shortcut = [[SpectacleShortcut alloc] initWithShortcutName:@"MoveToCenter"
                                                                shortcutKeyCode:kVK_ANSI_C
                                                              shortcutModifiers:NSEventModifierFlagOption | NSEventModifierFlagCommand];
  XCTAssertNil(shortcut.shortcutAction);
  XCTAssertNotNil([shortcut copyWithShortcutAction:^(SpectacleShortcut *shortcut) {}].shortcutAction);
}

- (void)testTriggerShortcutActions
{
  __block BOOL shortcutActionTriggered = NO;
  SpectacleShortcut *shortcut = [[SpectacleShortcut alloc] initWithShortcutName:@"MoveToCenter"
                                                                shortcutKeyCode:kVK_ANSI_C
                                                              shortcutModifiers:NSEventModifierFlagOption | NSEventModifierFlagCommand
                                                                 shortcutAction:^(SpectacleShortcut *shortcut) {
                                                                   shortcutActionTriggered = YES;
                                                                 }];
  [shortcut triggerShortcutAction];
  XCTAssertTrue(shortcutActionTriggered);
}

- (void)testDetermineIfTheShortcutIsCleared
{
  XCTAssertTrue([[[SpectacleShortcut alloc] initWithShortcutName:nil shortcutKeyBinding:nil] isClearedShortcut]);
  XCTAssertTrue([[[SpectacleShortcut alloc] initWithShortcutName:nil shortcutKeyBinding:@""] isClearedShortcut]);
  XCTAssertTrue([[[SpectacleShortcut alloc] initWithShortcutName:nil
                                                 shortcutKeyCode:-1
                                               shortcutModifiers:0] isClearedShortcut]);
  XCTAssertTrue([[[SpectacleShortcut alloc] initWithShortcutName:@"MoveToCenter"
                                                 shortcutKeyCode:-1
                                               shortcutModifiers:0] isClearedShortcut]);
}

- (void)testProvideADisplayString
{
  SpectacleShortcut *shortcut = [[SpectacleShortcut alloc] initWithShortcutName:@"MoveToCenter"
                                                                shortcutKeyCode:kVK_ANSI_C
                                                              shortcutModifiers:NSEventModifierFlagOption | NSEventModifierFlagCommand];
  XCTAssertEqualObjects([shortcut displayString], @"⌥⌘C");
}

- (void)testProvideAKeyBinding
{
  SpectacleShortcut *shortcut = [[SpectacleShortcut alloc] initWithShortcutName:@"MoveToCenter"
                                                             shortcutKeyBinding:@"alt+cmd+c"];
  XCTAssertEqualObjects(shortcut.shortcutKeyBinding, @"alt+cmd+c");
}

- (void)testSupportEquality
{
  SpectacleShortcut *shortcut1 = [[SpectacleShortcut alloc] initWithShortcutName:@"MoveToCenter"
                                                                 shortcutKeyCode:kVK_ANSI_C
                                                               shortcutModifiers:NSEventModifierFlagOption | NSEventModifierFlagCommand];
  SpectacleShortcut *shortcut2 = [[SpectacleShortcut alloc] initWithShortcutName:@"MoveToCenter"
                                                                 shortcutKeyCode:kVK_ANSI_C
                                                               shortcutModifiers:NSEventModifierFlagOption | NSEventModifierFlagCommand];
  SpectacleShortcut *shortcut3 = [[SpectacleShortcut alloc] initWithShortcutName:nil
                                                                 shortcutKeyCode:kVK_ANSI_C
                                                               shortcutModifiers:NSEventModifierFlagOption | NSEventModifierFlagCommand];
  XCTAssertEqualObjects(shortcut1, shortcut2);
  XCTAssertEqualObjects(shortcut1, shortcut3);
  SpectacleShortcut *clearedShortcut = [[SpectacleShortcut alloc] initWithShortcutName:nil
                                                                       shortcutKeyCode:-1
                                                                     shortcutModifiers:0];
  XCTAssertNotEqualObjects(shortcut1, clearedShortcut);
}

- (void)testDetermineIfTheShortcutIsContainsModifiers
{
  SpectacleShortcut *shortcut = [[SpectacleShortcut alloc] initWithShortcutName:@"MoveToCenter"
                                                                shortcutKeyCode:kVK_ANSI_C
                                                              shortcutModifiers:NSEventModifierFlagOption | NSEventModifierFlagCommand];
  XCTAssertTrue([shortcut containsModifiers:NSEventModifierFlagOption]);
  XCTAssertTrue([shortcut containsModifiers:NSEventModifierFlagOption | NSEventModifierFlagCommand]);
  XCTAssertFalse([shortcut containsModifiers:NSEventModifierFlagControl]);
}

@end
