import XCTest

@testable import SpectacleCore

/// Properties that should hold on any screen, checked across several display layouts.
final class InvariantTests: XCTestCase {
  let screens = [
    Rect(x: 0, y: 4, width: 1440, height: 873),  // 13" MacBook Air with menu bar and Dock
    Rect(x: 0, y: 25, width: 1512, height: 919),  // 14" MacBook Pro
    Rect(x: -1920, y: 0, width: 1920, height: 1055),  // external display to the left
    Rect(x: 1440, y: -300, width: 2560, height: 1415),  // external display to the right, offset
    Rect(x: 0, y: 0, width: 1081, height: 1897),  // portrait display with an odd width
  ]

  let tilingActions: [WindowAction] = [
    .leftHalf, .rightHalf, .topHalf, .bottomHalf,
    .upperLeft, .upperRight, .lowerLeft, .lowerRight,
    .nextThird, .previousThird, .fullscreen, .center,
  ]

  func testTilingActionsKeepWindowsOnScreenWithWholePixelFrames() {
    for screen in screens {
      let start = Rect(x: screen.x + 100, y: screen.y + 100, width: (screen.width / 2.5).floored, height: (screen.height / 2.5).floored)
      for action in tilingActions {
        var window = start
        for press in 1...6 {
          window = WindowLayout.frame(for: action, window: window, sourceScreen: screen, destinationScreen: screen)
          XCTAssertTrue(screen.contains(window), "\(action) press \(press) on \(screen) produced \(window)")
          for value in [window.x, window.y, window.width, window.height] {
            XCTAssertEqual(value, value.rounded(), "\(action) produced a fractional frame \(window)")
          }
        }
      }
    }
  }

  func testHalvesAndCornersCycleThroughDistinctSizesAndReturnToTheStart() {
    let screen = screens[0]
    for action in tilingActions.prefix(8) {
      let first = WindowLayout.frame(for: action, window: Rect(x: 200, y: 200, width: 500, height: 300), sourceScreen: screen, destinationScreen: screen)
      var seen = [first]
      var window = WindowLayout.frame(for: action, window: first, sourceScreen: screen, destinationScreen: screen)
      while window != first {
        XCTAssertFalse(seen.contains(window), "\(action): cycle repeats \(window) before returning to the start")
        XCTAssertLessThan(seen.count, 12, "\(action): cycle never returns to the start")
        if seen.contains(window) || seen.count >= 12 { break }
        seen.append(window)
        window = WindowLayout.frame(for: action, window: window, sourceScreen: screen, destinationScreen: screen)
      }
      XCTAssertEqual(seen.count, WindowLayout.resizeCycle.count, "\(action): cycle length")
    }
  }

  func testLargerAndSmallerStayWithinBounds() {
    for screen in screens {
      var window = Rect(x: screen.x + 200, y: screen.y + 150, width: (screen.width / 2).floored, height: (screen.height / 2).floored)
      for _ in 0..<60 {
        window = WindowLayout.frame(for: .larger, window: window, sourceScreen: screen, destinationScreen: screen)
        XCTAssertLessThanOrEqual(window.width, screen.width)
        XCTAssertLessThanOrEqual(window.height, screen.height)
      }
      for _ in 0..<60 {
        window = WindowLayout.frame(for: .smaller, window: window, sourceScreen: screen, destinationScreen: screen)
        XCTAssertGreaterThan(window.width, screen.width / 4)
        XCTAssertGreaterThan(window.height, screen.height / 4)
      }
    }
  }

  func testMovingToAnotherDisplayCentersWindowsThatFitAndFillsForThoseThatDont() {
    let source = screens[0]
    let destination = screens[3]
    let small = Rect(x: 10, y: 10, width: 800, height: 600)
    let moved = WindowLayout.frame(for: .nextDisplay, window: small, sourceScreen: source, destinationScreen: destination)
    XCTAssertEqual(moved.width, small.width)
    XCTAssertEqual(moved.height, small.height)
    XCTAssertEqual(moved.midX, destination.midX, accuracy: 1)
    XCTAssertEqual(moved.midY, destination.midY, accuracy: 1)
    let huge = Rect(x: 0, y: 0, width: 3000, height: 600)
    XCTAssertEqual(WindowLayout.frame(for: .previousDisplay, window: huge, sourceScreen: source, destinationScreen: destination), destination)
  }

  func testRoundingMatchesJavaScriptMathRound() {
    XCTAssertEqual((2.5).roundedHalfUp, 3)
    XCTAssertEqual((-2.5).roundedHalfUp, -2)
    XCTAssertEqual((-2.6).roundedHalfUp, -3)
    XCTAssertEqual((-0.5).floored, -1)
  }
}
