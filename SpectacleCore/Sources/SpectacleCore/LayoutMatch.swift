/// Recognises which layout a window is already in, so the menu bar panel can highlight its tile
/// and show its size.
public struct LayoutMatch: Equatable {
  public var action: WindowAction
  /// The window's size along the action's axis. 1/2 for actions that don't resize by fraction.
  public var fraction: Fraction

  public init(action: WindowAction, fraction: Fraction) {
    self.action = action
    self.fraction = fraction
  }

  /// The layout `window` is in on `screen`, or nil if it isn't in one.
  ///
  /// Checks Fill Screen, then every half and corner at every resize-session size, then Center.
  /// Apps with a minimum size, or that snap to a character grid, land a few points off, so frames
  /// match within `tolerance` points on every edge.
  ///
  /// - Parameters:
  ///   - window: The window's frame, in the same bottom-left-origin space as `screen`.
  ///   - screen: The visible frame of the screen the window is on.
  public static func match(window: Rect, screen: Rect, tolerance: Double = 2) -> LayoutMatch? {
    func matches(_ action: WindowAction, _ fraction: Fraction) -> Bool {
      let frame = WindowLayout.frame(
        for: action, window: window, sourceScreen: screen, destinationScreen: screen,
        fraction: fraction)
      return abs(frame.minX - window.minX) <= tolerance
        && abs(frame.minY - window.minY) <= tolerance
        && abs(frame.maxX - window.maxX) <= tolerance
        && abs(frame.maxY - window.maxY) <= tolerance
    }
    if matches(.fullscreen, .oneHalf) {
      return LayoutMatch(action: .fullscreen, fraction: .oneHalf)
    }
    for action in WindowAction.allCases where action.resizeMirror != nil {
      for fraction in ResizeSession.sizes where matches(action, fraction) {
        return LayoutMatch(action: action, fraction: fraction)
      }
    }
    if matches(.center, .oneHalf) {
      return LayoutMatch(action: .center, fraction: .oneHalf)
    }
    return nil
  }
}

/// The tiles of the menu bar panel's layout grid, in reading order (four per row).
public enum LayoutGrid {
  public static let tiles: [WindowAction] = [
    .leftHalf, .rightHalf, .topHalf, .bottomHalf,
    .upperLeft, .upperRight, .lowerLeft, .lowerRight,
    .nextThird, .center, .fullscreen, .larger,
  ]
}

extension WindowAction {
  /// A short name that fits under a grid tile, such as "Left" or "Top left".
  public var shortTitle: String {
    switch self {
    case .center: return "Center"
    case .fullscreen: return "Fill"
    case .leftHalf: return "Left"
    case .rightHalf: return "Right"
    case .topHalf: return "Top"
    case .bottomHalf: return "Bottom"
    case .upperLeft: return "Top left"
    case .upperRight: return "Top right"
    case .lowerLeft: return "Bottom left"
    case .lowerRight: return "Bottom right"
    case .nextDisplay: return "Next display"
    case .previousDisplay: return "Previous display"
    case .nextThird: return "Third"
    case .previousThird: return "Third"
    case .larger: return "Larger"
    case .smaller: return "Smaller"
    }
  }

  /// Where a tile's icon shows the window, as a share of the screen with a top-left origin. Nil for
  /// actions without a fixed place, which draw a symbol instead.
  public var iconRegion: Rect? {
    switch self {
    case .leftHalf: return Rect(x: 0, y: 0, width: 0.5, height: 1)
    case .rightHalf: return Rect(x: 0.5, y: 0, width: 0.5, height: 1)
    case .topHalf: return Rect(x: 0, y: 0, width: 1, height: 0.5)
    case .bottomHalf: return Rect(x: 0, y: 0.5, width: 1, height: 0.5)
    case .upperLeft: return Rect(x: 0, y: 0, width: 0.5, height: 0.5)
    case .upperRight: return Rect(x: 0.5, y: 0, width: 0.5, height: 0.5)
    case .lowerLeft: return Rect(x: 0, y: 0.5, width: 0.5, height: 0.5)
    case .lowerRight: return Rect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
    case .nextThird, .previousThird: return Rect(x: 0, y: 0, width: 1.0 / 3, height: 1)
    case .center: return Rect(x: 0.25, y: 0.2, width: 0.5, height: 0.6)
    case .fullscreen: return Rect(x: 0, y: 0, width: 1, height: 1)
    case .larger, .smaller, .nextDisplay, .previousDisplay: return nil
    }
  }
}
