/// Chooses which screen a window is on, and which screen "next display" and "previous display"
/// move it to.
///
/// Screens are given as frames in the AppKit coordinate space (origin at the bottom left of the
/// primary screen, y increasing upwards). Results are indices into the array passed in, so callers
/// can map them back to their own screen objects.
public enum ScreenSelection {
  /// The screens' indices in the order next/previous display steps through: the primary screen
  /// (the one at the origin) first, then from right to left, breaking ties from top to bottom.
  /// The order depends only on the screens' arrangement, not on the order the OS lists them in.
  public static func consistentOrder(of screens: [Rect]) -> [Int] {
    // Two stable passes, as in the original implementation: first by y, then by x, so x decides
    // and y breaks ties. The primary screen sorts first in both passes.
    let byY = stableSorted(Array(screens.indices)) { a, b in
      precedes(screens[a], screens[b], key: \.y)
    }
    return stableSorted(byY) { a, b in
      precedes(screens[a], screens[b], key: \.x)
    }
  }

  /// The index of the screen showing most of `window`, or `fallback` if it isn't on any screen.
  ///
  /// - Parameters:
  ///   - window: The window's frame in Accessibility coordinates (origin at the top left of the
  ///     primary screen, y increasing downwards), as the Accessibility API reports it.
  ///   - screens: Screen frames in AppKit coordinates.
  ///   - primaryScreenHeight: The height of the primary screen, used to convert between the two
  ///     coordinate spaces.
  public static func screenIndex(
    containing window: Rect,
    screens: [Rect],
    primaryScreenHeight: Double,
    fallback: Int?
  ) -> Int? {
    let windowInScreenCoordinates = flipped(window, primaryScreenHeight: primaryScreenHeight)
    var result = fallback
    var largestFraction = 0.0
    for index in consistentOrder(of: screens) {
      let screen = screens[index]
      if screen.contains(windowInScreenCoordinates) {
        return index
      }
      let fraction = fractionOf(windowInScreenCoordinates, within: screen)
      if fraction > largestFraction {
        largestFraction = fraction
        result = index
      }
    }
    return result
  }

  public enum Direction {
    case next
    case previous
  }

  /// The index of the screen after (or before) the screen at `index`, wrapping around, in
  /// `consistentOrder(of:)`. Nil if there's only one screen.
  public static func adjacentScreenIndex(to index: Int, in screens: [Rect], direction: Direction) -> Int? {
    guard screens.count > 1, screens.indices.contains(index) else {
      return nil
    }
    let order = consistentOrder(of: screens)
    // Match by frame, like the original implementation, so mirrored screens behave consistently.
    guard let position = order.firstIndex(where: { screens[$0] == screens[index] }) else {
      return nil
    }
    let step = direction == .next ? 1 : -1
    return order[(position + step + order.count) % order.count]
  }

  /// Converts a rect between Accessibility coordinates (top-left origin) and AppKit coordinates
  /// (bottom-left origin). The conversion is its own inverse.
  public static func flipped(_ rect: Rect, primaryScreenHeight: Double) -> Rect {
    var flipped = rect
    flipped.y = primaryScreenHeight - rect.maxY
    return flipped
  }

  // MARK: - Helpers

  private static func precedes(_ a: Rect, _ b: Rect, key: KeyPath<Rect, Double>) -> Bool {
    let aIsPrimary = a.x == 0 && a.y == 0
    let bIsPrimary = b.x == 0 && b.y == 0
    if aIsPrimary || bIsPrimary {
      return aIsPrimary && !bIsPrimary
    }
    return a[keyPath: key] > b[keyPath: key]
  }

  /// A stable sort: elements that compare equal keep their relative order.
  private static func stableSorted(_ indices: [Int], by areInIncreasingOrder: (Int, Int) -> Bool) -> [Int] {
    indices.enumerated()
      .sorted { lhs, rhs in
        if areInIncreasingOrder(lhs.element, rhs.element) {
          return true
        }
        if areInIncreasingOrder(rhs.element, lhs.element) {
          return false
        }
        return lhs.offset < rhs.offset
      }
      .map(\.element)
  }

  private static func fractionOf(_ rect: Rect, within screen: Rect) -> Double {
    let width = min(rect.maxX, screen.maxX) - max(rect.minX, screen.minX)
    let height = min(rect.maxY, screen.maxY) - max(rect.minY, screen.minY)
    let area = rect.width * rect.height
    guard width > 0, height > 0, area > 0 else {
      return 0
    }
    return (width * height) / area
  }
}
