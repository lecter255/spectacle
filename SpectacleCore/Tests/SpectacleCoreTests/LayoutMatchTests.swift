import XCTest

@testable import SpectacleCore

final class LayoutMatchTests: XCTestCase {
  let screen = Rect(x: 0, y: 4, width: 1440, height: 873)
  let anyWindow = Rect(x: 100, y: 100, width: 400, height: 300)

  func testRecognisesEveryHalfAndCornerAtEverySize() {
    for action in WindowAction.allCases where action.resizeMirror != nil {
      for fraction in ResizeSession.sizes {
        let frame = WindowLayout.frame(
          for: action, window: anyWindow, sourceScreen: screen, destinationScreen: screen,
          fraction: fraction)
        XCTAssertEqual(
          LayoutMatch.match(window: frame, screen: screen),
          LayoutMatch(action: action, fraction: fraction), "\(action) at \(fraction)")
      }
    }
  }

  func testRecognisesFillScreenBeforeHalves() {
    XCTAssertEqual(
      LayoutMatch.match(window: screen, screen: screen),
      LayoutMatch(action: .fullscreen, fraction: .oneHalf))
  }

  func testRecognisesCenter() {
    let centered = WindowLayout.frame(
      for: .center, window: anyWindow, sourceScreen: screen, destinationScreen: screen)
    XCTAssertEqual(
      LayoutMatch.match(window: centered, screen: screen),
      LayoutMatch(action: .center, fraction: .oneHalf))
  }

  func testAllowsAFewPointsOfSlack() {
    var leftHalf = WindowLayout.frame(
      for: .leftHalf, window: anyWindow, sourceScreen: screen, destinationScreen: screen)
    leftHalf.width -= 2
    XCTAssertEqual(LayoutMatch.match(window: leftHalf, screen: screen)?.action, .leftHalf)
    leftHalf.width -= 10
    XCTAssertNil(LayoutMatch.match(window: leftHalf, screen: screen))
  }

  func testFreeWindowMatchesNothing() {
    XCTAssertNil(LayoutMatch.match(window: anyWindow, screen: screen))
  }

  func testGridHasTwelveDistinctTilesWithIconsOrSymbols() {
    XCTAssertEqual(LayoutGrid.tiles.count, 12)
    XCTAssertEqual(Set(LayoutGrid.tiles).count, 12)
    XCTAssertNil(WindowAction.larger.iconRegion)
    XCTAssertNotNil(WindowAction.leftHalf.iconRegion)
  }
}
