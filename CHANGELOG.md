# Changelog

All notable changes to this fork are documented here. Version 1.2 is the last release of the
original [Spectacle](https://github.com/eczarny/spectacle) by Eric Czarny; everything below is
specific to this fork.

## Unreleased

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

- Added fast window-geometry tests that run the bundled JavaScript under Node on Linux
  (`Tests/geometry/`). They replay every case from the XCTest calculation specs and check
  invariants such as "windows stay on screen" across several display layouts.
- CI uploads an unsigned Release build of the app on every run, for testing on a real Mac.
- Removed an unused asset set that worked around a macOS 10.9 crash.
- Added GitHub issue templates for bug reports and feature requests.

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
- The order of displays for "Next Display" and "Previous Display" is now well defined. The sort
  comparator returned raw coordinate differences instead of an ordering, which the sort doesn't
  support.
- An error in a window position script is now logged to Console instead of interrupting you with
  a modal alert, and the window is left where it was. Previously the window could be moved to a
  zero-size frame at the corner of the screen.
- Spectacle always ignores its own shortcuts while it is the frontmost app, whatever its bundle
  identifier, so the shortcut recorder keeps working.
