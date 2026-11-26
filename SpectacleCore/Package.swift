// swift-tools-version:5.9
//
// SpectacleCore holds Spectacle's window layout logic: given a window's frame, the screen it is on
// and a window action, where should the window go? It deliberately has no dependency on AppKit,
// CoreGraphics or the Accessibility API, so it builds and tests on Linux too, and could be shared
// by a port to another platform.
import PackageDescription

let package = Package(
  name: "SpectacleCore",
  platforms: [.macOS(.v10_13)],
  products: [
    .library(name: "SpectacleCore", targets: ["SpectacleCore"]),
  ],
  targets: [
    .target(name: "SpectacleCore"),
    .testTarget(name: "SpectacleCoreTests", dependencies: ["SpectacleCore"]),
  ]
)
