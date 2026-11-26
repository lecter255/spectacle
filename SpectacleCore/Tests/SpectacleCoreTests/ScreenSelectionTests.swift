import XCTest

@testable import SpectacleCore

final class ScreenSelectionTests: XCTestCase {
  // A laptop (primary) with a monitor to its right, one to its left, and one above.
  let laptop = Rect(x: 0, y: 0, width: 1512, height: 982)
  let right = Rect(x: 1512, y: -200, width: 2560, height: 1440)
  let left = Rect(x: -1920, y: 0, width: 1920, height: 1080)
  let above = Rect(x: 0, y: 982, width: 1920, height: 1080)

  func testPrimaryScreenComesFirstThenRightToLeft() {
    let screens = [left, right, laptop]
    XCTAssertEqual(ScreenSelection.consistentOrder(of: screens), [2, 1, 0])
  }

  func testOrderDoesNotDependOnInputOrder() {
    let arrangement = [laptop, right, left, above]
    let expected = ScreenSelection.consistentOrder(of: arrangement).map { arrangement[$0] }
    for permutation in [[3, 2, 1, 0], [1, 3, 0, 2], [2, 0, 3, 1]] {
      let screens = permutation.map { arrangement[$0] }
      XCTAssertEqual(ScreenSelection.consistentOrder(of: screens).map { screens[$0] }, expected)
    }
  }

  func testScreensWithTheSameXAreOrderedTopToBottom() {
    let lower = Rect(x: 1512, y: 0, width: 1920, height: 1080)
    let upper = Rect(x: 1512, y: 1080, width: 1920, height: 1080)
    let screens = [lower, laptop, upper]
    XCTAssertEqual(ScreenSelection.consistentOrder(of: screens), [1, 2, 0])
  }

  func testNextAndPreviousWrapAround() {
    let screens = [laptop, right, left]
    // Order: laptop, right, left.
    XCTAssertEqual(ScreenSelection.adjacentScreenIndex(to: 0, in: screens, direction: .next), 1)
    XCTAssertEqual(ScreenSelection.adjacentScreenIndex(to: 1, in: screens, direction: .next), 2)
    XCTAssertEqual(ScreenSelection.adjacentScreenIndex(to: 2, in: screens, direction: .next), 0)
    XCTAssertEqual(ScreenSelection.adjacentScreenIndex(to: 0, in: screens, direction: .previous), 2)
    XCTAssertEqual(ScreenSelection.adjacentScreenIndex(to: 2, in: screens, direction: .previous), 1)
  }

  func testNoAdjacentScreenWithOneScreen() {
    XCTAssertNil(ScreenSelection.adjacentScreenIndex(to: 0, in: [laptop], direction: .next))
    XCTAssertNil(ScreenSelection.adjacentScreenIndex(to: 3, in: [laptop, right], direction: .next))
  }

  func testFlippingConvertsBetweenCoordinateSpacesAndIsItsOwnInverse() {
    let window = Rect(x: 100, y: 50, width: 800, height: 600)  // 50pt below the top of the laptop
    let flipped = ScreenSelection.flipped(window, primaryScreenHeight: laptop.height)
    XCTAssertEqual(flipped, Rect(x: 100, y: 332, width: 800, height: 600))
    XCTAssertEqual(ScreenSelection.flipped(flipped, primaryScreenHeight: laptop.height), window)
  }

  func testFindsTheScreenContainingTheWindow() {
    let screens = [left, laptop, right]
    // Accessibility coordinates: y grows downwards from the top of the laptop screen.
    let onRight = Rect(x: 2000, y: 100, width: 800, height: 600)
    XCTAssertEqual(ScreenSelection.screenIndex(containing: onRight, screens: screens, primaryScreenHeight: laptop.height, fallback: 1), 2)
    let onLeft = Rect(x: -1500, y: 100, width: 800, height: 600)
    XCTAssertEqual(ScreenSelection.screenIndex(containing: onLeft, screens: screens, primaryScreenHeight: laptop.height, fallback: 1), 0)
  }

  func testAWindowSpanningScreensBelongsToTheOneShowingMostOfIt() {
    let screens = [laptop, right]
    // 312pt on the laptop, 488pt on the right-hand monitor.
    let spanning = Rect(x: 1200, y: 100, width: 800, height: 600)
    XCTAssertEqual(ScreenSelection.screenIndex(containing: spanning, screens: screens, primaryScreenHeight: laptop.height, fallback: 0), 1)
  }

  func testAWindowOffEveryScreenFallsBack() {
    let screens = [laptop, right]
    let offscreen = Rect(x: 9000, y: 9000, width: 100, height: 100)
    XCTAssertEqual(ScreenSelection.screenIndex(containing: offscreen, screens: screens, primaryScreenHeight: laptop.height, fallback: 0), 0)
    XCTAssertNil(ScreenSelection.screenIndex(containing: offscreen, screens: screens, primaryScreenHeight: laptop.height, fallback: nil))
  }
}
