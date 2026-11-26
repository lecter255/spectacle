/// What the snap HUD shows after a window action: the layout's name, its size, the sizes a resize
/// session steps through, and what pressing again would do.
///
/// It holds only text and numbers, so the app can draw it however the platform likes. The strings
/// are English for now; they move to the app's localizations when the UI is rebuilt.
public struct SnapFeedback: Equatable {
  /// The layout's name, such as "Left Half".
  public var title: String
  /// The window's size as a fraction glyph, such as "¾", for halves and corners. Nil otherwise.
  public var sizeLabel: String?
  /// The sizes a resize session steps through, smallest first, for halves and corners. Empty
  /// otherwise.
  public var steps: [String]
  /// The index in `steps` of the window's size, or nil when `steps` is empty.
  public var currentStep: Int?
  /// What pressing again does while the modifier keys stay held, such as "Again for ⅓ · Opposite
  /// for ⅔". Nil when no resize session is running.
  public var hint: String?
  /// Where the window ended up, as a share of the screen: (0, 0) is the screen's top left corner and
  /// (1, 1) its bottom right. Used to draw the small screen icon.
  public var region: Rect

  public init(
    title: String,
    sizeLabel: String? = nil,
    steps: [String] = [],
    currentStep: Int? = nil,
    hint: String? = nil,
    region: Rect
  ) {
    self.title = title
    self.sizeLabel = sizeLabel
    self.steps = steps
    self.currentStep = currentStep
    self.hint = hint
    self.region = region
  }

  /// The feedback for `action` laid out at `fraction`.
  ///
  /// - Parameters:
  ///   - sessionActive: Whether a resize session is running, so pressing again resizes.
  ///   - window: The window's new frame, in the same bottom-left-origin space as `screen`.
  ///   - screen: The visible frame of the screen the window is on.
  public static func make(
    action: WindowAction,
    fraction: Fraction,
    sessionActive: Bool,
    window: Rect,
    screen: Rect
  ) -> SnapFeedback {
    let region = Self.region(of: window, in: screen)
    guard action.resizeMirror != nil else {
      return SnapFeedback(title: action.title, region: region)
    }
    let sizes = ResizeSession.sizes
    let index = sizes.firstIndex(of: fraction)
    var hint: String?
    if sessionActive, let index = index {
      var parts: [String] = []
      if index > 0 {
        parts.append("Again for \(sizes[index - 1].glyph)")
      }
      if index < sizes.count - 1 {
        parts.append("Opposite for \(sizes[index + 1].glyph)")
      }
      hint = parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
    return SnapFeedback(
      title: action.title,
      sizeLabel: fraction.glyph,
      steps: sizes.map(\.glyph),
      currentStep: index,
      hint: hint,
      region: region
    )
  }

  /// `window` as a share of `screen`, flipped to a top-left origin and clamped to the screen.
  public static func region(of window: Rect, in screen: Rect) -> Rect {
    guard screen.width > 0, screen.height > 0 else {
      return Rect(x: 0, y: 0, width: 1, height: 1)
    }
    func clamp(_ value: Double) -> Double { min(max(value, 0), 1) }
    let left = clamp((window.minX - screen.minX) / screen.width)
    let right = clamp((window.maxX - screen.minX) / screen.width)
    // Bottom-left origin in, top-left origin out.
    let top = clamp((screen.maxY - window.maxY) / screen.height)
    let bottom = clamp((screen.maxY - window.minY) / screen.height)
    return Rect(x: left, y: top, width: right - left, height: bottom - top)
  }
}

extension WindowAction {
  /// The name people see for this action, matching the menu and the settings window.
  public var title: String {
    switch self {
    case .center: return "Center"
    case .fullscreen: return "Fill Screen"
    case .leftHalf: return "Left Half"
    case .rightHalf: return "Right Half"
    case .topHalf: return "Top Half"
    case .bottomHalf: return "Bottom Half"
    case .upperLeft: return "Top Left"
    case .upperRight: return "Top Right"
    case .lowerLeft: return "Bottom Left"
    case .lowerRight: return "Bottom Right"
    case .nextDisplay: return "Next Display"
    case .previousDisplay: return "Previous Display"
    case .nextThird: return "Next Third"
    case .previousThird: return "Previous Third"
    case .larger: return "Larger"
    case .smaller: return "Smaller"
    }
  }
}

extension Fraction {
  /// The Unicode vulgar fraction for this fraction, such as "¾", or "3/8" when there is none.
  public var glyph: String {
    let glyphs: [String: String] = [
      "1/4": "¼", "1/3": "⅓", "1/2": "½", "2/3": "⅔", "3/4": "¾",
      "1/5": "⅕", "2/5": "⅖", "3/5": "⅗", "4/5": "⅘", "1/6": "⅙", "5/6": "⅚",
      "1/8": "⅛", "3/8": "⅜", "5/8": "⅝", "7/8": "⅞",
    ]
    let key = "\(Int(numerator))/\(Int(denominator))"
    return glyphs[key] ?? key
  }
}

/// Whether the app's windows and the snap HUD are light, dark, or follow the system.
public enum AppearancePreference: String, CaseIterable {
  case system
  case light
  case dark

  /// The user defaults key the preference is stored under.
  public static let defaultsKey = "SpectacleAppearance"

  /// Reads a stored value, falling back to `.system` for nil or anything unrecognized.
  public init(storedValue: String?) {
    self = storedValue.flatMap(AppearancePreference.init(rawValue:)) ?? .system
  }

  public var title: String {
    switch self {
    case .system: return "Match System"
    case .light: return "Light"
    case .dark: return "Dark"
    }
  }
}
