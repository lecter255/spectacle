# Spectacle (community fork)

[![CI](https://github.com/lecter255/spectacle/actions/workflows/ci.yml/badge.svg)](https://github.com/lecter255/spectacle/actions/workflows/ci.yml)

Easily organize windows without using a mouse.

## About this fork

This is an independent, community-maintained fork of [Spectacle](https://github.com/eczarny/spectacle), the macOS window manager created by [Eric Czarny](https://github.com/eczarny). The original project is no longer maintained and its repository has been archived. Its author invited people to "feel free to make Spectacle your own", and this fork aims to keep the app building and working on current versions of macOS and to improve on it from there.

**This fork is not affiliated with, or endorsed by, Eric Czarny or the original Spectacle project.** Please do not report issues with this fork to the original project.

See [CHANGELOG.md](CHANGELOG.md) for what has changed relative to the last upstream release (1.2).

## Credits

- **Eric Czarny** created Spectacle and wrote the vast majority of its code over nearly a decade.
- Everyone who contributed code and fixes to the original project. The full commit history is preserved in this repository; see also the [original contributors list](https://github.com/eczarny/spectacle/graphs/contributors).
- **[Iiro Jäppinen](http://iiro.jappinen.fi)** designed the icons and other artwork.
- The community translators behind the Finnish, French, Italian, Portuguese and Spanish localizations.

Spectacle is distributed under the MIT License; see [LICENSE.md](LICENSE.md). The original copyright notice is retained as the license requires.

## System requirements

macOS 10.13 (High Sierra) or later. Building requires a recent version of Xcode (CI builds with the default Xcode on GitHub's `macos-15` runner).

## Keyboard Shortcuts

Spectacle makes use of several [keyboard shortcuts][3] that trigger specific _window actions_. A window action is nothing more than a command that tells Spectacle how to change the size and/or position of a particular window.

A keyboard shortcut consists of one or more modifier keys paired with a character key. The common modifier keys Spectacle takes advantage of are:

| Symbol    | Key         |
|:---------:|:-----------:|
|  &#8984;  | Command Key |
|  &#8963;  | Control Key |
|  &#8997;  | Option Key  |
|  &#8679;  | Shift Key   |

The default keyboard shortcuts can be changed at any time. Use new key combinations to trigger window actions, or clear particular keyboard shortcuts to disable window actions entirely.

### Basic window actions

To move a window to the center of the screen use the &#8997;&#8984;C keyboard shortcut. Centered windows will __not__ have their size altered. Maximize a window using the &#8997;&#8984;F shortcut.

Windows can be moved to a number of predefined regions of the screen:

- _Move to the left half_ &#8212; &#8997;&#8984;&#8592;
- _Move to the right half_ &#8212; &#8997;&#8984;&#8594;
- _Move to the top half_ &#8212; &#8997;&#8984;&#8593;
- _Move to the bottom half_ &#8212; &#8997;&#8984;&#8595;
<br /><br />
- _Move to the upper left_ &#8212; &#8963;&#8984;&#8592;
- _Move to the lower left_ &#8212; &#8963;&#8679;&#8984;&#8592;
- _Move to the upper right_ &#8212; &#8963;&#8984;&#8594;
- _Move to the lower right_ &#8212; &#8963;&#8679;&#8984;&#8594;

Windows may also be resized between quarters and thirds using any of the shortcuts above. For example, to make a window take up a different share of the left side of the screen, activate the *left half* &#8997;&#8984;&#8592; keyboard shortcut more than once. The first press snaps the window to 1/2; each further press steps through 2/3, 3/4, 1/4 and 1/3 before returning to 1/2. This works the same way for the right, top and bottom half shortcuts, and for the upper left, lower left, upper right, and lower right shortcuts (which change the width while keeping half the screen height).

Spectacle can also move windows between horizontal and vertical thirds of the screen. The &#8963;&#8997;&#8594; keyboard shortcut will move a window to the next third of the screen, starting with the horizontal third region on the left of the screen. &#8963;&#8997;&#8592; will move a window to the previous third of the screen.

Resizing a window is just as easy. To make a window a bit larger use the &#8963;&#8997;&#8679;&#8594; keyboard shortcut; &#8963;&#8997;&#8679;&#8592; can be used to make a window smaller. Spectacle will always attempt to maintain contact between the edges of a window and the edges of the screen when resizing.

### Multiple displays

The &#8963;&#8997;&#8984;&#8594; keyboard shortcut will move a window to the next available display. &#8963;&#8997;&#8984;&#8592; can be used to move a window to the previous display.

### Window action history

Spectacle remembers where every window was prior to executing a window action. To undo a window action use the &#8997;&#8984;Z keyboard shortcut. Use the &#8997;&#8679;&#8984;Z shortcut to redo the window action once again.

## Common Issues

### Spectacle is requesting access to use accessibility features

Apple's [macOS Accessibility API][4] makes Spectacle possible. It allows assistive applications to _drive the user interface of another application_. In order to do its job Spectacle must be granted access in **System Settings → Privacy & Security → Accessibility** (or **System Preferences → Security & Privacy → Privacy → Accessibility** on older macOS releases). Spectacle shows a prompt with a button that opens the right pane if it does not have sufficient privileges.

Because this fork uses its own bundle identifier, macOS treats it as a different app from the original Spectacle: you will need to grant it Accessibility access separately, and it does not share the original app's preferences.

### Spectacle does not resize a particular window as expected

macOS allows applications to place constraints on the size of its windows. This allows application developers to design their user interfaces without needing to worry about supporting every possible window dimension. In these cases Spectacle will not be able to resize those windows to fit into the exact dimensions intended by the shortcut used.

As an example suppose a display has a 2880x1800 resolution and a window is being resized to fit the left half of the display. If the window has specified a minimum allowable width of 1600 pixels Spectacle will not be able to resize the window to fit the expected 1440 pixels. The constraints placed on windows will always be respected despite leading to potentially unexpected results; in this example Spectacle will resize the window's width to 1600 pixels.

### Spectacle behaves strangely with Terminal windows

Terminal (and other terminal emulation applications like iTerm 2) place constraints on how windows are resized so entire rows and columns are always visible. This behavior works great since it guarantees no rows or columns are truncated. Unfortunately it does mean that Spectacle needs to do some extra work to make these windows fit.

To work around the limitations imposed on Terminal windows Spectacle will first try to resize a window to match the desired dimensions. If a window cannot be resized to fit Spectacle will immediately try to make the window a little smaller. This process is repeated until the window can be made to fit with its constraints still in place. The result is a window that is centered within the desired dimensions at the cost of a slightly jittery experience.

### Spectacle does not work with all applications

Most applications built with the Cocoa frameworks can be readily manipulated via the _macOS Accessibility API_; allowing Spectacle to interact with nearly every window it encounters. Unfortunately this is not always the case. Spectacle will be unable to manipulate the windows of applications that build their user interfaces in unexpected ways.

## Building and running

The project has no third-party dependencies. Open the project in Xcode and press &#8984;R:

    $ open Spectacle.xcodeproj

To build and run the test suite from the command line:

    $ xcodebuild -project Spectacle.xcodeproj -scheme Spectacle -destination 'platform=macOS' test

Every push and pull request is built and tested by [GitHub Actions](.github/workflows/ci.yml).

When you run a development build for the first time, macOS will ask you to grant it Accessibility access. Ad-hoc signed builds are treated as a new app each time their signature changes, so you may need to remove and re-add the entry in the Accessibility settings after rebuilding.

## License

Copyright (c) 2017 Eric Czarny, and contributors to this fork.

Spectacle is released under the MIT License. See [LICENSE.md](LICENSE.md) for the full text.

[3]: https://support.apple.com/HT201236
[4]: https://developer.apple.com/documentation/applicationservices/axuielement_h
