# Changelog

All notable changes to this fork are documented here. Version 1.2 is the last release of the
original [Spectacle](https://github.com/eczarny/spectacle) by Eric Czarny; everything below is
specific to this fork.

## Unreleased

### Window management

- Repeated presses of a half or corner shortcut now cycle through 1/2, 2/3, 3/4, 1/4 and 1/3
  (previously 1/2, 2/3 and 1/3). The shared cycle lives in `SpectacleWindowCalculationHelpers.js`.
- On screens with an odd pixel width, right-side half and corner positions are now flush with the
  right edge instead of leaving a 1px gap.

### Build and tooling

- Builds on current Xcode and macOS SDKs. The minimum deployment target is now macOS 10.13, the
  oldest version current Xcode can target (previously 10.9).
- Removed Carthage and every third-party dependency.
- Ported the test suite from Specta/Expecta/OCMockito (all unmaintained) to plain XCTest with
  hand-written test doubles. All 99 original test cases are preserved, plus one new test.
- The app skips its launch side effects (global hot keys, status item, accessibility prompt) when
  hosting unit tests, so tests can run unattended in CI instead of hanging on a modal dialog.
- Replaced Travis CI (`xcode8.2`, long defunct) with GitHub Actions.
- `CFBundleVersion` is derived from `git rev-list --count HEAD` and no longer assumes a `master`
  branch exists.
- Replaced APIs deprecated as of macOS 10.13 so the project still builds with warnings treated
  as errors.

### Fork identity and security

- New bundle identifier (`io.github.lecter255.Spectacle`) so the fork doesn't collide with the
  original app's preferences, Accessibility permission, or login item.
- Removed the Sparkle auto-updater. It pointed at the original project's update feed
  (`spectacleapp.com`), which this fork does not control, and used DSA signatures, which Sparkle
  has since deprecated. Updates can come back later with a feed and EdDSA keys owned by this fork.

### Fixes

- **Launch at login** works again on macOS 13 and later, using `SMAppService`. The
  `LSSharedFileList` API it relied on no longer works on current macOS; it is kept only as a
  fallback for older systems.
- **Open System Settings** in the Accessibility prompt now opens Privacy & Security >
  Accessibility directly on every supported macOS version. The old bundled AppleScript drove a
  System Preferences pane that no longer exists and needed an extra Automation permission.
- Fixed a crash when choosing "Disable for *application*" while an app without a bundle
  identifier was frontmost.
- Fixed an inverted check in `SpectacleShortcutManager -updateShortcut:`. While shortcuts were
  enabled, every update returned early. Even without that, the old key combination would have been
  re-registered under the new shortcut.
- Fixed undefined behaviour (`id = ++id`) when assigning hot key IDs.
- Fixed a NULL dereference and a CoreFoundation leak in `SpectacleAccessibilityElement` when a
  window's position or size couldn't be read, and hardened the other accessibility helpers against
  NULL and unexpected value types.
- Turning the status bar icon on and off repeatedly no longer adds duplicate menu bar items.
- Moved the status item to the `NSStatusBarButton` API.
- Spectacle always ignores its own shortcuts while it is the frontmost app, whatever its bundle
  identifier, so the shortcut recorder keeps working.
