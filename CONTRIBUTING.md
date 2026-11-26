# Contributing

Thanks for your interest in this fork of Spectacle! Please report issues and send pull requests to this repository, not to the original (archived) project.

Contributions come in many forms. Creating an issue that documents a previously unreported defect is just as important as sending a pull request. Spectacle can only be great when the folks that use it are passionate about its quality.

Before you start working on your contribution to Spectacle please keep reading. For even more information read [Contributing to Open Source on GitHub][1].

## Issues

Before creating a new issue check and make sure somebody hasn't already beat you to it. _Please take this time to also review Spectacle's [common issues][2]_. If your defect or feature request doesn't already exist feel free to create a new issue. When creating a new issue take the time to be as clear and descriptive as possible.

Here are a few things to keep in mind when creating an issue for a potential defect:

* What version of Spectacle did you use when encountering the defect?
* What version of macOS did you use when encountering the defect?
* Was there any relevant Spectacle output in the [Console][3]?

Including screenshots or videos are extremely helpful so please include them if you can. Diagrams can also be highly valuable when describing a new feature in a feature request.

## Pull Requests

1. Fork the repository and create your branch from `master`
2. Add tests if your changes can and should be tested (tests use plain XCTest; see `SpectacleSpecs/`)
3. Run the test suite and confirm that all tests pass:
   `xcodebuild -project Spectacle.xcodeproj -scheme Spectacle -destination 'platform=macOS' test`
   - The app is being ported to Swift gradually. Window layout logic is moving into `SpectacleCore/`, a Swift package with no macOS dependencies; test it on macOS or Linux with `swift test --package-path SpectacleCore`.
   - The window position math lives in JavaScript (`Spectacle/Resources/Window Position Calculations/`). You can test it on any OS, without Xcode, with Node 18 or later:
     `node --test Tests/geometry/geometry.test.mjs`
     This runs every case from the XCTest `*CalculationSpec.m` files plus a few invariants (windows stay on screen, sizes cycle correctly). Add new cases to the XCTest spec and they run in both suites.
4. Rebase your changes on top of the most recent changes from `master`
5. Make sure the GitHub Actions CI build passes on your pull request. Each CI run also uploads an unsigned build of the app (under the run's **Artifacts**) that you can try on a Mac.

## Coding Style

To help make it easier maintain Spectacle please match the existing coding style as much as possible. This make it easier to both understand and merge your contributions. Only use two __spaces__ for indentation.

## License

By contributing to Spectacle you agree that your contributions will be licensed under its MIT license.

[1]: https://guides.github.com/activities/contributing-to-open-source/#contributing
[2]: README.md#common-issues
[3]: https://support.apple.com/guide/console/welcome/mac
