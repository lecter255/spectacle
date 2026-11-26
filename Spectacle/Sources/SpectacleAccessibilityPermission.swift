import ApplicationServices
import Foundation

/// Tracks whether Spectacle has been granted Accessibility access, which it needs to move other
/// apps' windows.
///
/// macOS doesn't post a notification when the user grants access in System Settings, so this
/// checks periodically while waiting. Once access is granted, the window actions work right away,
/// with no relaunch needed.
@objc(SpectacleAccessibilityPermission)
public final class SpectacleAccessibilityPermission: NSObject {
  private var timer: Timer?

  /// Whether Spectacle currently has Accessibility access.
  @objc public static var isGranted: Bool {
    AXIsProcessTrusted()
  }

  /// Calls `completion` on the main thread once access is granted, checking every `interval`
  /// seconds. Calls it immediately if access is already granted. Replaces any earlier wait.
  @objc(waitUntilGrantedCheckingEvery:completion:)
  public func waitUntilGranted(checkingEvery interval: TimeInterval, completion: @escaping () -> Void) {
    stopWaiting()
    if Self.isGranted {
      completion()
      return
    }
    let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
      guard Self.isGranted else {
        return
      }
      self?.stopWaiting()
      completion()
    }
    // Common modes, so the check keeps running while a menu is open.
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  /// Stops a wait started with `waitUntilGranted(checkingEvery:completion:)`, if any.
  @objc public func stopWaiting() {
    timer?.invalidate()
    timer = nil
  }

  deinit {
    timer?.invalidate()
  }
}
