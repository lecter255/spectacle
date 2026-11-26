import CoreGraphics
import Foundation

/// The layout to apply for one shortcut press: which action to lay out, and for halves and corners
/// what share of the screen the window should take.
@objc(SpectacleResizeLayout)
public final class SpectacleResizeLayout: NSObject {
  /// A `kSpectacleWindowAction…` constant.
  @objc public let action: String
  @objc public let fractionNumerator: Double
  @objc public let fractionDenominator: Double

  init(action: String, fraction: Fraction) {
    self.action = action
    self.fractionNumerator = fraction.numerator
    self.fractionDenominator = fraction.denominator
    super.init()
  }

  /// A layout at a size picked directly, such as from the menu bar panel's size chips.
  @objc public convenience init(action: String, fractionNumerator: Double, fractionDenominator: Double) {
    self.init(action: action, fraction: Fraction(numerator: fractionNumerator, denominator: fractionDenominator))
  }
}

/// Connects SpectacleCore's `ResizeSessionTracker` to the keyboard: it reads which modifier keys are
/// held when a shortcut fires, and while a session is running it polls them so that letting go of
/// one ends the session.
///
/// Polling `CGEventSource.flagsState` needs no extra permission and no event tap, and only runs
/// while a session is active (at most a few seconds at a time).
///
/// It is `public` because, without a bridging header, only public declarations are written to the
/// generated `Spectacle-Swift.h` that the Objective-C code imports.
@objc(SpectacleResizeSessionMonitor)
public final class SpectacleResizeSessionMonitor: NSObject {
  /// The modifier keys that make up shortcuts. Other flags (Caps Lock, and the numeric pad and Fn
  /// flags that arrow keys set) are ignored.
  static let shortcutModifiers: CGEventFlags = [.maskCommand, .maskAlternate, .maskControl, .maskShift]

  static let pollInterval: TimeInterval = 0.05

  private var tracker = ResizeSessionTracker()
  private let modifierFlagsProvider: () -> UInt64
  private var pollTimer: Timer?

  /// Reads the modifier keys from the current login session.
  @objc public override convenience init() {
    self.init(modifierFlagsProvider: {
      CGEventSource.flagsState(.combinedSessionState).rawValue
    })
  }

  /// `modifierFlagsProvider` returns the currently held modifiers as `CGEventFlags` raw values.
  @objc public init(modifierFlagsProvider: @escaping () -> UInt64) {
    self.modifierFlagsProvider = modifierFlagsProvider
    super.init()
  }

  deinit {
    pollTimer?.invalidate()
  }

  /// Whether a resize session is running.
  @objc public var isSessionActive: Bool {
    tracker.session != nil
  }

  /// The layout for a press of `actionName`, starting, continuing or ending a session as needed.
  /// Actions SpectacleCore doesn't know (undo, redo) pass through at 1/2 and end any session.
  @objc(layoutForAction:)
  public func layout(forAction actionName: String) -> SpectacleResizeLayout {
    guard let action = WindowAction(rawValue: actionName) else {
      endSession()
      return SpectacleResizeLayout(action: actionName, fraction: .oneHalf)
    }
    let layout = tracker.layout(for: action, heldModifiers: heldModifiers())
    updatePolling()
    return SpectacleResizeLayout(action: layout.action.rawValue, fraction: layout.fraction)
  }

  /// Ends the session if any of its modifiers has been released. Called by the poll timer.
  @objc public func checkModifiers() {
    tracker.modifiersChanged(heldModifiers())
    updatePolling()
  }

  @objc public func endSession() {
    tracker.endSession()
    updatePolling()
  }

  private func heldModifiers() -> UInt64 {
    modifierFlagsProvider() & Self.shortcutModifiers.rawValue
  }

  private func updatePolling() {
    if tracker.session == nil {
      pollTimer?.invalidate()
      pollTimer = nil
    } else if pollTimer == nil {
      let timer = Timer(timeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
        self?.checkModifiers()
      }
      // Keep polling while a menu is being tracked, too.
      RunLoop.main.add(timer, forMode: .common)
      pollTimer = timer
    }
  }
}
