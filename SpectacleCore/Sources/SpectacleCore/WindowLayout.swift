/// Calculates where a window should go for a given action.
///
/// This is a direct port of the JavaScript calculations that used to be bundled with the app
/// (`Spectacle/Resources/Window Position Calculations/`), and must produce identical frames: the
/// tests replay every case from the app's XCTest calculation specs.
public enum WindowLayout {
  /// The frame for `window` after performing `action`.
  ///
  /// - Parameters:
  ///   - window: The window's current frame, in the same coordinate space as the screens.
  ///   - sourceScreen: The visible frame of the screen the window is on now.
  ///   - destinationScreen: The visible frame of the screen the window should end up on. The same
  ///     as `sourceScreen` except for the next and previous display actions.
  public static func frame(
    for action: WindowAction,
    window: Rect,
    sourceScreen: Rect,
    destinationScreen screen: Rect
  ) -> Rect {
    switch action {
    case .center:
      return centered(window, in: screen)
    case .fullscreen:
      return screen
    case .leftHalf:
      return nextInResizeCycle(window) { fraction in
        var rect = screen
        rect.width = fraction.of(screen.width)
        return rect
      }
    case .rightHalf:
      return nextInResizeCycle(window) { fraction in
        var rect = screen
        rect.width = fraction.of(screen.width)
        rect.x = screen.x + screen.width - rect.width
        return rect
      }
    case .topHalf:
      return nextInResizeCycle(window) { fraction in
        var rect = screen
        rect.height = fraction.of(screen.height)
        rect.y = screen.y + screen.height - rect.height
        return rect
      }
    case .bottomHalf:
      return nextInResizeCycle(window) { fraction in
        var rect = screen
        rect.height = fraction.of(screen.height)
        return rect
      }
    case .upperLeft:
      return nextInResizeCycle(window) { fraction in
        var rect = screen
        rect.width = fraction.of(screen.width)
        rect.height = (screen.height / 2).floored
        rect.y = screen.y + screen.height - rect.height
        return rect
      }
    case .upperRight:
      return nextInResizeCycle(window) { fraction in
        var rect = screen
        rect.width = fraction.of(screen.width)
        rect.x = screen.x + screen.width - rect.width
        rect.height = (screen.height / 2).floored
        rect.y = screen.y + screen.height - rect.height
        return rect
      }
    case .lowerLeft:
      return nextInResizeCycle(window) { fraction in
        var rect = screen
        rect.width = fraction.of(screen.width)
        rect.height = (screen.height / 2).floored
        return rect
      }
    case .lowerRight:
      return nextInResizeCycle(window) { fraction in
        var rect = screen
        rect.width = fraction.of(screen.width)
        rect.x = screen.x + screen.width - rect.width
        rect.height = (screen.height / 2).floored
        return rect
      }
    case .nextDisplay, .previousDisplay:
      // A window that fits keeps its size and is centered; a larger one fills the new screen.
      return window.fits(within: screen) ? centered(window, in: screen) : screen
    case .nextThird:
      return thirdsCycle(window, screen: screen, step: 1)
    case .previousThird:
      return thirdsCycle(window, screen: screen, step: -1)
    case .larger:
      return WindowResizer.resize(window, screen: screen, by: 30)
    case .smaller:
      return WindowResizer.resize(window, screen: screen, by: -30)
    }
  }

  // MARK: - Center

  static func centered(_ window: Rect, in screen: Rect) -> Rect {
    var rect = window
    rect.x = ((screen.width - window.width) / 2).roundedHalfUp + screen.x
    rect.y = ((screen.height - window.height) / 2).roundedHalfUp + screen.y
    return rect
  }

  // MARK: - Halves and corners

  /// A size in the resize cycle, as a fraction of the screen's width or height.
  struct Fraction: Equatable {
    var numerator: Double
    var denominator: Double

    func of(_ length: Double) -> Double {
      (length * numerator / denominator).floored
    }
  }

  /// The sizes that repeated presses of a half or corner shortcut step through. The first press
  /// lands on 1/2, and each further press moves to the next size, wrapping around.
  static let resizeCycle: [Fraction] = [
    Fraction(numerator: 1, denominator: 2),
    Fraction(numerator: 2, denominator: 3),
    Fraction(numerator: 3, denominator: 4),
    Fraction(numerator: 1, denominator: 4),
    Fraction(numerator: 1, denominator: 3),
  ]

  /// The rect for the size after the one `window` occupies now, or for 1/2 if it occupies none.
  /// `rectForFraction` places a rect of the given size for the action.
  static func nextInResizeCycle(_ window: Rect, rectForFraction: (Fraction) -> Rect) -> Rect {
    for (index, fraction) in resizeCycle.enumerated() where rectForFraction(fraction).isCentered(on: window) {
      return rectForFraction(resizeCycle[(index + 1) % resizeCycle.count])
    }
    return rectForFraction(resizeCycle[0])
  }

  // MARK: - Thirds

  /// The three vertical columns, left to right, then the three horizontal rows, top to bottom.
  static func thirds(of screen: Rect) -> [Rect] {
    let columnWidth = (screen.width / 3).floored
    let rowHeight = (screen.height / 3).floored
    let columns = (0..<3).map { i -> Rect in
      var third = screen
      third.x = screen.x + columnWidth * Double(i)
      third.width = columnWidth
      return third
    }
    let rows = (0..<3).map { i -> Rect in
      var third = screen
      third.y = screen.y + screen.height - rowHeight * Double(i + 1)
      third.height = rowHeight
      return third
    }
    return columns + rows
  }

  static func thirdsCycle(_ window: Rect, screen: Rect, step: Int) -> Rect {
    let candidates = thirds(of: screen)
    guard let index = candidates.firstIndex(where: { $0.isCentered(on: window) }) else {
      return candidates[0]
    }
    let count = candidates.count
    return candidates[((index + step) % count + count) % count]
  }
}
