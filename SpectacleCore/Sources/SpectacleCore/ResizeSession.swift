/// Grows and shrinks a half or corner while the shortcut's modifier keys stay held.
///
/// The first press of a half or corner shortcut snaps the window to 1/2 and starts a session.
/// While the modifiers stay held, pressing the same shortcut again moves the window's free edge
/// towards its anchored edge (shrink), and pressing the mirror shortcut moves it away (grow). For
/// a left half, that means ← shrinks and → grows; for a top half, ↑ shrinks and ↓ grows. Corners
/// work the same way on their width, so upper left grows with upper right, and their height stays
/// at 1/2. Sizes step through 1/4, 1/3, 1/2, 2/3 and 3/4 and stop at either end.
public struct ResizeSession: Equatable {
  /// The sizes a session steps through, smallest first.
  public static let sizes: [Fraction] = [
    Fraction(numerator: 1, denominator: 4),
    Fraction(numerator: 1, denominator: 3),
    Fraction(numerator: 1, denominator: 2),
    Fraction(numerator: 2, denominator: 3),
    Fraction(numerator: 3, denominator: 4),
  ]

  /// The index of 1/2 in `sizes`, where every session starts.
  public static let startIndex = 2

  /// What a press does to the window during a session.
  public enum Step: Equatable {
    case grow
    case shrink
  }

  /// The half or corner the session started with. Its anchored edge stays put.
  public let action: WindowAction
  /// The index in `sizes` of the window's current size.
  public private(set) var sizeIndex: Int

  /// The window's current size.
  public var fraction: Fraction { Self.sizes[sizeIndex] }

  /// Starts a session at 1/2, or returns nil if `action` isn't a half or corner.
  public init?(action: WindowAction) {
    guard action.resizeMirror != nil else {
      return nil
    }
    self.action = action
    self.sizeIndex = Self.startIndex
  }

  /// What pressing `incoming` does during a session that started with `anchor`, or nil if
  /// `incoming` isn't part of that session (another axis, another row, or not a half or corner).
  public static func step(for incoming: WindowAction, anchor: WindowAction) -> Step? {
    if incoming == anchor, anchor.resizeMirror != nil {
      return .shrink
    }
    if incoming == anchor.resizeMirror {
      return .grow
    }
    return nil
  }

  /// Applies a press of `incoming`. Returns false, leaving the session unchanged, if `incoming`
  /// isn't part of this session. At either end of `sizes` the size stays where it is.
  public mutating func apply(_ incoming: WindowAction) -> Bool {
    guard let step = Self.step(for: incoming, anchor: action) else {
      return false
    }
    switch step {
    case .grow:
      sizeIndex = min(sizeIndex + 1, Self.sizes.count - 1)
    case .shrink:
      sizeIndex = max(sizeIndex - 1, 0)
    }
    return true
  }
}

/// Decides, press by press, what layout to apply, given which modifier keys are held.
///
/// The modifier flags are opaque bit masks (the app passes `CGEventFlags` raw values) so this stays
/// free of platform types. A session lasts while every modifier that was held when it started is
/// still held; letting go of any of them ends it, and the next press starts fresh at 1/2.
public struct ResizeSessionTracker: Equatable {
  /// What to lay out for one press.
  public struct Layout: Equatable {
    public var action: WindowAction
    public var fraction: Fraction
  }

  public private(set) var session: ResizeSession?
  /// The modifiers held when the session started.
  public private(set) var sessionModifiers: UInt64 = 0

  public init() {}

  /// The layout for a press of `action` while `heldModifiers` are down, updating the session.
  public mutating func layout(for action: WindowAction, heldModifiers: UInt64) -> Layout {
    modifiersChanged(heldModifiers)
    if var continuing = session, continuing.apply(action) {
      session = continuing
      return Layout(action: continuing.action, fraction: continuing.fraction)
    }
    session = nil
    // A press with no modifiers held (from the menu, say) can't be followed by a held-key
    // adjustment, so it doesn't start a session.
    if heldModifiers != 0, let started = ResizeSession(action: action) {
      session = started
      sessionModifiers = heldModifiers
      return Layout(action: action, fraction: started.fraction)
    }
    return Layout(action: action, fraction: .oneHalf)
  }

  /// Ends the session if any of its modifiers is no longer held.
  public mutating func modifiersChanged(_ heldModifiers: UInt64) {
    if session != nil, heldModifiers & sessionModifiers != sessionModifiers {
      endSession()
    }
  }

  public mutating func endSession() {
    session = nil
    sessionModifiers = 0
  }
}

extension WindowAction {
  /// The half or corner on the other side of the same axis, whose shortcut grows a session started
  /// with this one. Nil for actions that don't take part in resize sessions.
  public var resizeMirror: WindowAction? {
    switch self {
    case .leftHalf: return .rightHalf
    case .rightHalf: return .leftHalf
    case .topHalf: return .bottomHalf
    case .bottomHalf: return .topHalf
    case .upperLeft: return .upperRight
    case .upperRight: return .upperLeft
    case .lowerLeft: return .lowerRight
    case .lowerRight: return .lowerLeft
    default: return nil
    }
  }
}
