#import <Carbon/Carbon.h>
#import <XCTest/XCTest.h>

#import "SpectacleShortcut.h"
#import "SpectacleShortcutKeyBindings.h"
#import "SpectacleTestHelpers.h"

static SpectacleShortcut *shortcutForKeyBinding(NSString *keyBinding);

@interface SpectacleShortcutKeyBindingsTests : XCTestCase
@end

@implementation SpectacleShortcutKeyBindingsTests

- (void)testConvertAnEmptyOrNilKeyBindingToNilModifiers
{
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(nil), 0);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@""), 0);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@" "), 0);
}

- (void)testConvertKeyBindingsToModifiers
{
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@"cmd+c"), cmdKey);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@"shift+cmd+c"), shiftKey |cmdKey);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@"alt+shift+cmd+c"), optionKey | shiftKey |cmdKey);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@"ctrl+alt+shift+cmd+c"), controlKey | optionKey | shiftKey | cmdKey);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@"command+c"), cmdKey);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@"shift+command+c"), shiftKey |cmdKey);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@"option+shift+command+c"), optionKey | shiftKey |cmdKey);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@"control+option+shift+command+c"), controlKey | optionKey | shiftKey | cmdKey);
}

- (void)testConvertMixedCaseKeyBindingsToModifiers
{
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@"Cmd+C"), cmdKey);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@"Shift+Cmd+C"), shiftKey |cmdKey);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@"Alt+Shift+Cmd+C"), optionKey | shiftKey |cmdKey);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@"Ctrl+Alt+Shift+Cmd+C"), controlKey | optionKey | shiftKey | cmdKey);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@"COMMAND+C"), cmdKey);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@"SHIFT+COMMAND+C"), shiftKey |cmdKey);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@"OPTION+SHIFT+COMMAND+C"), optionKey | shiftKey |cmdKey);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@"CONTROL+OPTION+SHIFT+COMMAND+C"), controlKey | optionKey | shiftKey | cmdKey);
}

- (void)testConvertKeyBindingsWithWhitespaceToModifiers
{
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToModifiers(@" alt  +   shift    +     cmd    +c"), optionKey | shiftKey |cmdKey);
}

- (void)testConvertAnEmptyOrNilKeyBindingToNilKeyCodes
{
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(nil), 0);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@""), 0);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@" "), 0);
}

- (void)testConvertLowercaseAlphabeticalKeyBindingsToKeyCodes
{
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"a"), kVK_ANSI_A);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"b"), kVK_ANSI_B);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"c"), kVK_ANSI_C);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"d"), kVK_ANSI_D);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"e"), kVK_ANSI_E);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f"), kVK_ANSI_F);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"g"), kVK_ANSI_G);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"h"), kVK_ANSI_H);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"i"), kVK_ANSI_I);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"j"), kVK_ANSI_J);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"k"), kVK_ANSI_K);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"l"), kVK_ANSI_L);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"m"), kVK_ANSI_M);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"n"), kVK_ANSI_N);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"o"), kVK_ANSI_O);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"p"), kVK_ANSI_P);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"q"), kVK_ANSI_Q);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"r"), kVK_ANSI_R);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"s"), kVK_ANSI_S);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"t"), kVK_ANSI_T);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"u"), kVK_ANSI_U);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"v"), kVK_ANSI_V);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"w"), kVK_ANSI_W);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"x"), kVK_ANSI_X);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"y"), kVK_ANSI_Y);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"z"), kVK_ANSI_Z);
}

- (void)testConvertUppercaseAlphabeticalKeyBindingsToKeyCodes
{
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"A"), kVK_ANSI_A);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"B"), kVK_ANSI_B);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"C"), kVK_ANSI_C);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"D"), kVK_ANSI_D);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"E"), kVK_ANSI_E);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F"), kVK_ANSI_F);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"G"), kVK_ANSI_G);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"H"), kVK_ANSI_H);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"I"), kVK_ANSI_I);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"J"), kVK_ANSI_J);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"K"), kVK_ANSI_K);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"L"), kVK_ANSI_L);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"M"), kVK_ANSI_M);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"N"), kVK_ANSI_N);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"O"), kVK_ANSI_O);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"P"), kVK_ANSI_P);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Q"), kVK_ANSI_Q);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"R"), kVK_ANSI_R);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"S"), kVK_ANSI_S);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"T"), kVK_ANSI_T);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"U"), kVK_ANSI_U);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"V"), kVK_ANSI_V);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"W"), kVK_ANSI_W);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"X"), kVK_ANSI_X);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Y"), kVK_ANSI_Y);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Z"), kVK_ANSI_Z);
}

- (void)testConvertNumericKeyBindingsToKeyCodes
{
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"0"), kVK_ANSI_0);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"1"), kVK_ANSI_1);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"2"), kVK_ANSI_2);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"3"), kVK_ANSI_3);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"4"), kVK_ANSI_4);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"5"), kVK_ANSI_5);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"6"), kVK_ANSI_6);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"7"), kVK_ANSI_7);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"8"), kVK_ANSI_8);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"9"), kVK_ANSI_9);
}

- (void)testConvertAlphabeticalKeyBindingsWithModifiersToKeyCodes
{
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"cmd+a"), kVK_ANSI_A);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"shift+cmd+b"), kVK_ANSI_B);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"alt+shift+cmd+c"), kVK_ANSI_C);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"ctrl+alt+shift+cmd+d"), kVK_ANSI_D);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"command+e"), kVK_ANSI_E);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"shift+command+f"), kVK_ANSI_F);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"option+shift+command+g"), kVK_ANSI_G);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"control+option+shift+command+h"), kVK_ANSI_H);
}

- (void)testConvertAlphanumericKeyBindingsWithWhitespaceToKeyCodes
{
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@" cmd  +   a    "), kVK_ANSI_A);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@" shift  +   cmd    +     0      "), kVK_ANSI_0);
}

- (void)testConvertNamedKeyBindingsToKeyCodes
{
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f1"), kVK_F1);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f2"), kVK_F2);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f3"), kVK_F3);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f4"), kVK_F4);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f5"), kVK_F5);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f6"), kVK_F6);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f7"), kVK_F7);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f8"), kVK_F8);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f9"), kVK_F9);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f10"), kVK_F10);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f11"), kVK_F11);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f12"), kVK_F12);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f13"), kVK_F13);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f14"), kVK_F14);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f15"), kVK_F15);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f16"), kVK_F16);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f17"), kVK_F17);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f18"), kVK_F18);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f19"), kVK_F19);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"f20"), kVK_F20);

  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypaddecimal"), kVK_ANSI_KeypadDecimal);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypadmultiply"), kVK_ANSI_KeypadMultiply);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypadplus"), kVK_ANSI_KeypadPlus);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypadclear"), kVK_ANSI_KeypadClear);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypaddivide"), kVK_ANSI_KeypadDivide);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypadenter"), kVK_ANSI_KeypadEnter);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypadminus"), kVK_ANSI_KeypadMinus);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypadequals"), kVK_ANSI_KeypadEquals);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypad0"), kVK_ANSI_Keypad0);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypad1"), kVK_ANSI_Keypad1);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypad2"), kVK_ANSI_Keypad2);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypad3"), kVK_ANSI_Keypad3);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypad4"), kVK_ANSI_Keypad4);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypad5"), kVK_ANSI_Keypad5);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypad6"), kVK_ANSI_Keypad6);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypad7"), kVK_ANSI_Keypad7);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypad8"), kVK_ANSI_Keypad8);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"keypad9"), kVK_ANSI_Keypad9);

  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"return"), kVK_Return);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"tab"), kVK_Tab);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"space"), kVK_Space);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"delete"), kVK_Delete);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"escape"), kVK_Escape);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"command"), kVK_Command);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"shift"), kVK_Shift);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"capslock"), kVK_CapsLock);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"option"), kVK_Option);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"control"), kVK_Control);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"rightshift"), kVK_RightShift);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"rightoption"), kVK_RightOption);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"rightcontrol"), kVK_RightControl);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"function"), kVK_Function);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"volumeup"), kVK_VolumeUp);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"volumedown"), kVK_VolumeDown);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"mute"), kVK_Mute);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"help"), kVK_Help);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"home"), kVK_Home);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"pageup"), kVK_PageUp);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"forwarddelete"), kVK_ForwardDelete);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"end"), kVK_End);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"pagedown"), kVK_PageDown);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"left"), kVK_LeftArrow);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"right"), kVK_RightArrow);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"down"), kVK_DownArrow);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"up"), kVK_UpArrow);
}

- (void)testConvertMixedCaseNamedKeyBindingsToKeyCodes
{
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F1"), kVK_F1);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F2"), kVK_F2);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F3"), kVK_F3);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F4"), kVK_F4);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F5"), kVK_F5);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F6"), kVK_F6);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F7"), kVK_F7);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F8"), kVK_F8);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F9"), kVK_F9);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F10"), kVK_F10);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F11"), kVK_F11);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F12"), kVK_F12);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F13"), kVK_F13);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F14"), kVK_F14);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F15"), kVK_F15);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F16"), kVK_F16);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F17"), kVK_F17);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F18"), kVK_F18);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F19"), kVK_F19);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"F20"), kVK_F20);

  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"KeypadDecimal"), kVK_ANSI_KeypadDecimal);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"KeypadMultiply"), kVK_ANSI_KeypadMultiply);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"KeypadPlus"), kVK_ANSI_KeypadPlus);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"KeypadClear"), kVK_ANSI_KeypadClear);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"KeypadDivide"), kVK_ANSI_KeypadDivide);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"KeypadEnter"), kVK_ANSI_KeypadEnter);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"KeypadMinus"), kVK_ANSI_KeypadMinus);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"KeypadEquals"), kVK_ANSI_KeypadEquals);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Keypad0"), kVK_ANSI_Keypad0);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Keypad1"), kVK_ANSI_Keypad1);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Keypad2"), kVK_ANSI_Keypad2);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Keypad3"), kVK_ANSI_Keypad3);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Keypad4"), kVK_ANSI_Keypad4);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Keypad5"), kVK_ANSI_Keypad5);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Keypad6"), kVK_ANSI_Keypad6);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Keypad7"), kVK_ANSI_Keypad7);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Keypad8"), kVK_ANSI_Keypad8);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Keypad9"), kVK_ANSI_Keypad9);

  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Return"), kVK_Return);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Tab"), kVK_Tab);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Space"), kVK_Space);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Delete"), kVK_Delete);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Escape"), kVK_Escape);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Command"), kVK_Command);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Shift"), kVK_Shift);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"CapsLock"), kVK_CapsLock);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Option"), kVK_Option);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Control"), kVK_Control);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"RightShift"), kVK_RightShift);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"RightOption"), kVK_RightOption);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"RightControl"), kVK_RightControl);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Function"), kVK_Function);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"VolumeUp"), kVK_VolumeUp);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"VolumeDown"), kVK_VolumeDown);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Mute"), kVK_Mute);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Help"), kVK_Help);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Home"), kVK_Home);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"PageUp"), kVK_PageUp);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"ForwardDelete"), kVK_ForwardDelete);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"End"), kVK_End);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"PageDown"), kVK_PageDown);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Left"), kVK_LeftArrow);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Right"), kVK_RightArrow);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Down"), kVK_DownArrow);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"Up"), kVK_UpArrow);
}

- (void)testConvertNamedKeyBindingsWithModifiersToKeyCodes
{
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"cmd+up"), kVK_UpArrow);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"shift+cmd+down"), kVK_DownArrow);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"alt+shift+cmd+left"), kVK_LeftArrow);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"ctrl+alt+shift+cmd+right"), kVK_RightArrow);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"command+space"), kVK_Space);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"shift+command+f1"), kVK_F1);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"option+shift+command+keypad0"), kVK_ANSI_Keypad0);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"control+option+shift+command+escape"), kVK_Escape);
}

- (void)testConvertMixedCaseNamedKeyBindingsWithModifiersToKeyCodes
{
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"cmd+Up"), kVK_UpArrow);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"shift+cmd+Down"), kVK_DownArrow);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"alt+shift+cmd+left"), kVK_LeftArrow);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"ctrl+alt+shift+cmd+Right"), kVK_RightArrow);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"command+SPACE"), kVK_Space);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"shift+command+F1"), kVK_F1);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"option+shift+command+KEYPAD0"), kVK_ANSI_Keypad0);
  XCTAssertEqual(SpectacleConvertShortcutKeyBindingToKeyCode(@"control+option+shift+command+ESCAPE"), kVK_Escape);
}

- (void)testConvertEmptyShortcutsToNilKeyBindings
{
  XCTAssertEqual(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(nil)), 0);
}

- (void)testConvertShortcutsToKeyBindings
{
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"alt+cmd+c")), @"alt+cmd+c");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"alt+cmd+f")), @"alt+cmd+f");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"alt+cmd+left")), @"alt+cmd+left");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"alt+cmd+right")), @"alt+cmd+right");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"alt+cmd+up")), @"alt+cmd+up");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"alt+cmd+down")), @"alt+cmd+down");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"ctrl+cmd+left")), @"ctrl+cmd+left");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"ctrl+shift+cmd+left")), @"ctrl+shift+cmd+left");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"ctrl+cmd+right")), @"ctrl+cmd+right");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"ctrl+shift+cmd+right")), @"ctrl+shift+cmd+right");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"ctrl+alt+cmd+right")), @"ctrl+alt+cmd+right");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"ctrl+alt+cmd+left")), @"ctrl+alt+cmd+left");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"ctrl+alt+right")), @"ctrl+alt+right");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"ctrl+alt+left")), @"ctrl+alt+left");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"ctrl+alt+shift+right")), @"ctrl+alt+shift+right");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"ctrl+alt+shift+left")), @"ctrl+alt+shift+left");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"alt+cmd+z")), @"alt+cmd+z");
  XCTAssertEqualObjects(SpectacleConvertShortcutToKeyBinding(shortcutForKeyBinding(@"alt+shift+cmd+z")), @"alt+shift+cmd+z");
}

@end

static SpectacleShortcut *shortcutForKeyBinding(NSString *keyBinding)
{
  return [[SpectacleShortcut alloc] initWithShortcutName:nil shortcutKeyBinding:keyBinding];
}
