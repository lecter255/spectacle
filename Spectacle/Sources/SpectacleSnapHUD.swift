import AppKit
import SwiftUI

/// The small translucent panel that appears near the bottom of the screen after a window action,
/// naming the layout and, for halves and corners, its size and what pressing again does.
///
/// It never takes focus or clicks, follows the app's light or dark appearance, and can be turned
/// off with the `SpectacleSnapHUDEnabled` user default ("Show Snap HUD" in the status menu).
///
/// It is `public` because, without a bridging header, only public declarations are written to the
/// generated `Spectacle-Swift.h` that the Objective-C code imports.
@objc(SpectacleSnapHUD)
public final class SpectacleSnapHUD: NSObject {
  @objc public static let shared = SpectacleSnapHUD()

  static let enabledDefaultsKey = "SpectacleSnapHUDEnabled"
  static let distanceFromBottom: CGFloat = 40
  static let cornerRadius: CGFloat = 16
  static let visibleDuration: TimeInterval = 0.9
  static let sessionVisibleDuration: TimeInterval = 1.6
  static let fadeDuration: TimeInterval = 0.2

  /// Whether the HUD is shown. On unless the user turned it off.
  @objc public static var isEnabled: Bool {
    get {
      UserDefaults.standard.object(forKey: enabledDefaultsKey) as? Bool ?? true
    }
    set {
      UserDefaults.standard.set(newValue, forKey: enabledDefaultsKey)
      if !newValue {
        shared.hide(animated: false)
      }
    }
  }

  private var panel: NSPanel?
  private var hostingView: NSHostingView<SnapHUDView>?
  private var hideWorkItem: DispatchWorkItem?

  /// Shows the HUD for a layout that was just applied.
  ///
  /// - Parameters:
  ///   - actionName: A `kSpectacleWindowAction…` constant. Actions SpectacleCore doesn't lay out
  ///     (undo, redo) show nothing.
  ///   - windowRect: The window's new frame, in AppKit's bottom-left-origin screen coordinates.
  ///   - visibleFrame: The visible frame of the screen the window is on, in the same coordinates.
  @objc(showForAction:fractionNumerator:fractionDenominator:sessionActive:windowRect:visibleFrameOfScreen:)
  public func show(
    forAction actionName: String,
    fractionNumerator: Double,
    fractionDenominator: Double,
    sessionActive: Bool,
    windowRect: CGRect,
    visibleFrameOfScreen visibleFrame: CGRect
  ) {
    guard Self.isEnabled, let action = WindowAction(rawValue: actionName) else {
      return
    }
    let feedback = SnapFeedback.make(
      action: action,
      fraction: Fraction(numerator: fractionNumerator, denominator: fractionDenominator),
      sessionActive: sessionActive,
      window: Rect(windowRect),
      screen: Rect(visibleFrame),
      sizes: StoredResizeSizes.current
    )
    present(feedback, on: visibleFrame)
    scheduleHide(after: sessionActive ? Self.sessionVisibleDuration : Self.visibleDuration)
  }

  private func present(_ feedback: SnapFeedback, on visibleFrame: CGRect) {
    let panel = self.panel ?? makePanel()
    hostingView?.rootView = SnapHUDView(feedback: feedback)
    let size = hostingView?.fittingSize ?? .zero
    let origin = CGPoint(
      x: (visibleFrame.midX - size.width / 2).rounded(),
      y: visibleFrame.minY + Self.distanceFromBottom
    )
    panel.setFrame(CGRect(origin: origin, size: size), display: true)
    panel.alphaValue = 1
    panel.orderFrontRegardless()
  }

  private func scheduleHide(after delay: TimeInterval) {
    hideWorkItem?.cancel()
    let workItem = DispatchWorkItem { [weak self] in
      self?.hide(animated: true)
    }
    hideWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
  }

  private func hide(animated: Bool) {
    hideWorkItem?.cancel()
    hideWorkItem = nil
    guard let panel = panel, panel.isVisible else {
      return
    }
    guard animated else {
      panel.orderOut(nil)
      return
    }
    NSAnimationContext.runAnimationGroup({ context in
      context.duration = Self.fadeDuration
      panel.animator().alphaValue = 0
    }, completionHandler: {
      // A new press during the fade brings the panel back to full opacity; leave it up then.
      if panel.alphaValue == 0 {
        panel.orderOut(nil)
      }
    })
  }

  private func makePanel() -> NSPanel {
    let panel = NSPanel(
      contentRect: .zero,
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: true
    )
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = true
    panel.level = .statusBar
    panel.ignoresMouseEvents = true
    panel.hidesOnDeactivate = false
    panel.isReleasedWhenClosed = false
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]

    let background = NSVisualEffectView()
    background.material = .hudWindow
    background.blendingMode = .behindWindow
    background.state = .active
    background.maskImage = roundedMask(radius: Self.cornerRadius)

    let hostingView = NSHostingView(rootView: SnapHUDView(feedback: nil))
    hostingView.translatesAutoresizingMaskIntoConstraints = false
    background.addSubview(hostingView)
    NSLayoutConstraint.activate([
      hostingView.leadingAnchor.constraint(equalTo: background.leadingAnchor),
      hostingView.trailingAnchor.constraint(equalTo: background.trailingAnchor),
      hostingView.topAnchor.constraint(equalTo: background.topAnchor),
      hostingView.bottomAnchor.constraint(equalTo: background.bottomAnchor),
    ])
    panel.contentView = background

    self.panel = panel
    self.hostingView = hostingView
    return panel
  }
}

/// The HUD's accent: a teal that reads on the dark blur, deepened for the light one.
private let hudAccent = adaptiveColor(light: 0x148F73, dark: 0x5FD6B6)

struct SnapHUDView: View {
  let feedback: SnapFeedback?

  var body: some View {
    if let feedback = feedback {
      HStack(spacing: 12) {
        ScreenRegionIcon(region: feedback.region)
          .frame(width: 38, height: 26)
        VStack(alignment: .leading, spacing: 2) {
          Text(headline(feedback))
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.primary)
          if let hint = feedback.hint {
            Text(hint)
              .font(.system(size: 11.5))
              .foregroundColor(.secondary)
          }
        }
        if !feedback.steps.isEmpty {
          HStack(spacing: 4) {
            ForEach(Array(feedback.steps.enumerated()), id: \.offset) { index, step in
              StepChip(label: step, isCurrent: index == feedback.currentStep)
            }
          }
          .padding(.leading, 4)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .fixedSize()
      .accessibilityElement(children: .combine)
    } else {
      EmptyView()
    }
  }

  private func headline(_ feedback: SnapFeedback) -> String {
    guard let size = feedback.sizeLabel else {
      return feedback.title
    }
    return "\(feedback.title) · \(size)"
  }
}

/// A tiny screen with the window's new area filled in.
struct ScreenRegionIcon: View {
  let region: Rect

  var body: some View {
    GeometryReader { geometry in
      let inset: CGFloat = 2.5
      let inner = CGSize(width: geometry.size.width - inset * 2, height: geometry.size.height - inset * 2)
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 4)
          .strokeBorder(Color.secondary.opacity(0.6), lineWidth: 1.5)
        RoundedRectangle(cornerRadius: 2)
          .fill(hudAccent)
          .frame(
            width: max(2, inner.width * CGFloat(region.width)),
            height: max(2, inner.height * CGFloat(region.height))
          )
          .offset(
            x: inset + inner.width * CGFloat(region.x),
            y: inset + inner.height * CGFloat(region.y)
          )
      }
    }
  }
}

struct StepChip: View {
  let label: String
  let isCurrent: Bool

  var body: some View {
    Text(label)
      .font(.system(size: 12, weight: isCurrent ? .bold : .regular))
      .foregroundColor(isCurrent ? Color(NSColor.windowBackgroundColor) : .secondary)
      .frame(width: 22, height: 20)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(isCurrent ? hudAccent : Color.secondary.opacity(0.15))
      )
  }
}
