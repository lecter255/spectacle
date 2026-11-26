import XCTest

@testable import SpectacleCore

final class ShortcutCatalogTests: XCTestCase {
  func testListsEveryActionOnceAndUndoRedo() {
    let entries = ShortcutCatalog.entries
    XCTAssertEqual(entries.count, WindowAction.allCases.count + 2)
    XCTAssertEqual(Set(entries.map(\.shortcutName)).count, entries.count)
    XCTAssertEqual(Set(entries.compactMap(\.action)), Set(WindowAction.allCases))
  }

  func testMatchesTheAppsStoredShortcutNames() {
    // The names the app stores shortcuts under (SpectacleDefaultShortcutHelpers.m).
    let stored: Set<String> = [
      "MoveToCenter", "MoveToFullscreen", "MoveToLeftHalf", "MoveToRightHalf", "MoveToTopHalf",
      "MoveToBottomHalf", "MoveToUpperLeft", "MoveToLowerLeft", "MoveToUpperRight", "MoveToLowerRight",
      "MoveToNextDisplay", "MoveToPreviousDisplay", "MoveToNextThird", "MoveToPreviousThird",
      "MakeLarger", "MakeSmaller", "UndoLastMove", "RedoLastMove",
    ]
    XCTAssertEqual(Set(ShortcutCatalog.entries.map(\.shortcutName)), stored)
  }

  func testLooksUpByName() {
    XCTAssertEqual(ShortcutCatalog.entry(named: "MoveToLeftHalf")?.action, .leftHalf)
    XCTAssertNil(ShortcutCatalog.entry(named: "Nope"))
  }
}
