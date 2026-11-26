import AppKit
import SwiftUI

/// What the menu bar panel asks of the rest of the app. The app delegate implements it.
///
/// It is `public` because, without a bridging header, only public declarations are written to the
/// generated `Spectacle-Swift.h` that the Objective-C code imports.
@objc(SpectacleStatusPanelDelegate)
public protocol SpectacleStatusPanelDelegate: AnyObject {
  /// Performs a `kSpectacleWindowAction…` constant on the frontmost window, as its shortcut would.
  func statusPanelPerformAction(_ actionName: String)
  /// Lays out a half or corner at a specific size.
  func statusPanelPerformAction(_ actionName: String, fractionNumerator: Double, fractionDenominator: Double)
  func statusPanelUndo()
  func statusPanelShowPreferences()
  /// Shows the full status menu (shortcut toggles, Appearance, Redo and the rest).
  func statusPanelShowFullMenu()
  /// The frontmost window's frame in accessibility coordinates (top-left origin), or `CGRect.null`.
  func statusPanelFrontmostWindowRect() -> CGRect
  /// Display strings for the current shortcuts, keyed by `kSpectacleWindowAction…` constant.
  func statusPanelShortcutDisplayStrings() -> [String: String]
}

/// The panel that drops down from the status item: a grid of layouts for the frontmost window, its
/// current size, and buttons for displays, undo, settings and quit.
///
/// It is a non-activating panel rather than an `NSPopover`, so clicking in it never brings
/// Spectacle to the front: the window being moved stays the frontmost one.
@objc(SpectacleStatusPanel)
public final class SpectacleStatusPanel: NSObject {
  @objc public weak var delegate: SpectacleStatusPanelDelegate?

  private let model = StatusPanelModel()
  private var panel: NSPanel?
  private var eventMonitors: [Any] = []

  @objc public var isShown: Bool {
    panel?.isVisible ?? false
  }

  /// Shows the panel below `button`, or hides it if it is already showing.
  @objc(toggleRelativeToButton:)
  public func toggle(relativeTo button: NSStatusBarButton) {
    if isShown {
      close()
    } else {
      show(relativeTo: button)
    }
  }

  @objc public func close() {
    eventMonitors.forEach(NSEvent.removeMonitor)
    eventMonitors.removeAll()
    panel?.orderOut(nil)
  }

  private func show(relativeTo button: NSStatusBarButton) {
    refresh()
    let panel = self.panel ?? makePanel()
    guard let hostingView = panel.contentView?.subviews.first else {
      return
    }
    let size = hostingView.fittingSize
    let buttonFrame = button.window.map { $0.convertToScreen(button.convert(button.bounds, to: nil)) }
      ?? .zero
    let screenFrame = (button.window?.screen ?? NSScreen.main)?.visibleFrame ?? .zero
    var origin = CGPoint(x: (buttonFrame.midX - size.width / 2).rounded(), y: buttonFrame.minY - 6 - size.height)
    origin.x = min(max(origin.x, screenFrame.minX + 8), screenFrame.maxX - size.width - 8)
    panel.setFrame(CGRect(origin: origin, size: size), display: true)
    panel.orderFrontRegardless()
    startMonitoringEvents(ignoring: button)
  }

  /// Reads the frontmost app, its window's layout and the shortcuts again.
  private func refresh() {
    model.appName = NSWorkspace.shared.frontmostApplication?.localizedName ?? ""
    model.shortcuts = delegate?.statusPanelShortcutDisplayStrings() ?? [:]
    model.match = currentMatch()
  }

  private func currentMatch() -> LayoutMatch? {
    guard let axRect = delegate?.statusPanelFrontmostWindowRect(), !axRect.isNull,
      let primaryScreen = NSScreen.screens.first
    else {
      return nil
    }
    // Accessibility frames have a top-left origin on the primary screen; AppKit's are bottom-left.
    var window = axRect
    window.origin.y = primaryScreen.frame.height - axRect.maxY
    let center = CGPoint(x: window.midX, y: window.midY)
    guard let screen = NSScreen.screens.first(where: { $0.frame.contains(center) }) else {
      return nil
    }
    return LayoutMatch.match(window: Rect(window), screen: Rect(screen.visibleFrame))
  }

  private func perform(_ command: StatusPanelCommand) {
    guard let delegate = delegate else {
      return
    }
    switch command {
    case .action(let action):
      delegate.statusPanelPerformAction(action.rawValue)
    case .size(let action, let fraction):
      delegate.statusPanelPerformAction(
        action.rawValue, fractionNumerator: fraction.numerator, fractionDenominator: fraction.denominator)
    case .undo:
      delegate.statusPanelUndo()
    case .preferences:
      close()
      delegate.statusPanelShowPreferences()
      return
    case .fullMenu:
      close()
      delegate.statusPanelShowFullMenu()
      return
    case .quit:
      NSApp.terminate(nil)
      return
    }
    // Window moves happen synchronously, so the new layout can be read straight away.
    model.match = currentMatch()
  }

  private func startMonitoringEvents(ignoring button: NSStatusBarButton) {
    // Clicks anywhere outside the panel close it. Clicks on the status item toggle it themselves.
    if let monitor = NSEvent.addGlobalMonitorForEvents(
      matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown], handler: { [weak self] _ in
        self?.close()
      })
    {
      eventMonitors.append(monitor)
    }
    // Escape closes it. The panel never becomes key, so watch keys system-wide; this needs the
    // accessibility access Spectacle already has.
    if let monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: { [weak self] event in
      if event.keyCode == 53 {
        self?.close()
      }
    }) {
      eventMonitors.append(monitor)
    }
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
    panel.level = .popUpMenu
    panel.hidesOnDeactivate = false
    panel.isReleasedWhenClosed = false
    panel.becomesKeyOnlyIfNeeded = true
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]

    let background = NSVisualEffectView()
    background.material = .popover
    background.blendingMode = .behindWindow
    background.state = .active
    background.maskImage = roundedMask(radius: 14)

    let view = StatusPanelView(model: model) { [weak self] command in
      self?.perform(command)
    }
    let hostingView = NSHostingView(rootView: view)
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
    return panel
  }
}

/// A stretchable rounded-rectangle mask, so a blur gets rounded corners at any size.
func roundedMask(radius: CGFloat) -> NSImage {
  let edge = radius * 2 + 1
  let image = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
    NSColor.black.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
    return true
  }
  image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
  image.resizingMode = .stretch
  return image
}

/// A color with separate light and dark values, following the app's appearance.
func adaptiveColor(light: UInt32, dark: UInt32) -> Color {
  func make(_ hex: UInt32) -> NSColor {
    NSColor(
      srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
      green: CGFloat((hex >> 8) & 0xFF) / 255,
      blue: CGFloat(hex & 0xFF) / 255,
      alpha: 1)
  }
  return Color(NSColor(name: nil) { appearance in
    appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? make(dark) : make(light)
  })
}

enum StatusPanelCommand {
  case action(WindowAction)
  case size(WindowAction, Fraction)
  case undo
  case preferences
  case fullMenu
  case quit
}

final class StatusPanelModel: ObservableObject {
  @Published var appName = ""
  @Published var match: LayoutMatch?
  @Published var shortcuts: [String: String] = [:]
}

private let panelAccent = adaptiveColor(light: 0x5B4BD6, dark: 0xA79CFF)
private let panelAccentWash = adaptiveColor(light: 0xEFEDFB, dark: 0x332E52)
private let stripBackground = adaptiveColor(light: 0xF4F2FD, dark: 0x262338)

struct StatusPanelView: View {
  @ObservedObject var model: StatusPanelModel
  let perform: (StatusPanelCommand) -> Void

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 1) {
        Text("Move front window")
          .font(.system(size: 13, weight: .semibold))
        if !model.appName.isEmpty {
          Text(model.appName)
            .font(.system(size: 11.5))
            .foregroundColor(.secondary)
        }
      }

      LazyVGrid(columns: columns, spacing: 8) {
        ForEach(LayoutGrid.tiles, id: \.self) { action in
          LayoutTile(
            action: action,
            shortcut: model.shortcuts[action.rawValue],
            isCurrent: model.match?.action == action
          ) {
            perform(.action(action))
          }
        }
      }

      if let match = model.match, match.action.resizeMirror != nil {
        SizeStrip(match: match, shortcut: model.shortcuts[match.action.rawValue]) { fraction in
          perform(.size(match.action, fraction))
        }
      }

      HStack(spacing: 6) {
        PanelButton(title: "← Display", help: model.shortcuts[WindowAction.previousDisplay.rawValue]) {
          perform(.action(.previousDisplay))
        }
        PanelButton(title: "Undo", help: model.shortcuts["SpectacleWindowActionUndo"]) {
          perform(.undo)
        }
        PanelButton(title: "Display →", help: model.shortcuts[WindowAction.nextDisplay.rawValue]) {
          perform(.action(.nextDisplay))
        }
      }

      Divider()

      VStack(spacing: 0) {
        MenuRow(title: "Edit Shortcuts…", detail: nil) { perform(.preferences) }
        MenuRow(title: "More", detail: "▸") { perform(.fullMenu) }
        MenuRow(title: "Quit Spectacle", detail: "⌘Q") { perform(.quit) }
      }
    }
    .padding(14)
    .frame(width: 330)
  }
}

struct LayoutTile: View {
  let action: WindowAction
  let shortcut: String?
  let isCurrent: Bool
  let onTap: () -> Void
  @State private var isHovered = false

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 5) {
        TileIcon(action: action, isCurrent: isCurrent)
          .frame(width: 40, height: 27)
        Text(action.shortTitle)
          .font(.system(size: 10.5, weight: isCurrent ? .semibold : .regular))
          .foregroundColor(isCurrent ? panelAccent : .primary)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 7)
      .background(
        RoundedRectangle(cornerRadius: 9)
          .fill(isCurrent ? panelAccentWash : (isHovered ? Color.primary.opacity(0.06) : Color.clear))
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { isHovered = $0 }
    .help(shortcut.map { "\(action.title)  \($0)" } ?? action.title)
  }
}

struct TileIcon: View {
  let action: WindowAction
  let isCurrent: Bool

  var body: some View {
    GeometryReader { geometry in
      let inset: CGFloat = 2.5
      let inner = CGSize(width: geometry.size.width - inset * 2, height: geometry.size.height - inset * 2)
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 4)
          .strokeBorder(Color.secondary.opacity(isCurrent ? 0.9 : 0.5), lineWidth: 1.25)
        if let region = action.iconRegion {
          RoundedRectangle(cornerRadius: 2)
            .fill(isCurrent ? panelAccent : Color.secondary.opacity(0.55))
            .frame(width: inner.width * CGFloat(region.width), height: inner.height * CGFloat(region.height))
            .offset(x: inset + inner.width * CGFloat(region.x), y: inset + inner.height * CGFloat(region.y))
        } else {
          Text("⤢")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(isCurrent ? panelAccent : .secondary)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
      }
    }
  }
}

struct SizeStrip: View {
  let match: LayoutMatch
  let shortcut: String?
  let onPick: (Fraction) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(match.action.title)
          .font(.system(size: 12, weight: .semibold))
        Spacer()
        if let shortcut = shortcut {
          Text(shortcut)
            .font(.system(size: 11.5))
            .foregroundColor(.secondary)
        }
      }
      HStack(spacing: 6) {
        ForEach(ResizeSession.sizes, id: \.self) { fraction in
          let isCurrent = fraction == match.fraction
          Button {
            onPick(fraction)
          } label: {
            Text(fraction.glyph)
              .font(.system(size: 13, weight: isCurrent ? .bold : .regular))
              .foregroundColor(isCurrent ? .white : .primary)
              .frame(maxWidth: .infinity, minHeight: 24)
              .background(
                RoundedRectangle(cornerRadius: 7)
                  .fill(isCurrent ? panelAccent : Color.primary.opacity(0.07))
              )
              .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      Text("Hold the keys and press again to shrink, or the opposite arrow to grow.")
        .font(.system(size: 10.5))
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(10)
    .background(RoundedRectangle(cornerRadius: 10).fill(stripBackground))
  }
}

struct PanelButton: View {
  let title: String
  let help: String?
  let onTap: () -> Void
  @State private var isHovered = false

  var body: some View {
    Button(action: onTap) {
      Text(title)
        .font(.system(size: 11.5, weight: .medium))
        .frame(maxWidth: .infinity, minHeight: 26)
        .background(
          RoundedRectangle(cornerRadius: 7)
            .fill(Color.primary.opacity(isHovered ? 0.11 : 0.06))
        )
        .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { isHovered = $0 }
    .help(help ?? "")
  }
}

struct MenuRow: View {
  let title: String
  let detail: String?
  let onTap: () -> Void
  @State private var isHovered = false

  var body: some View {
    Button(action: onTap) {
      HStack {
        Text(title)
          .font(.system(size: 13))
          .foregroundColor(isHovered ? .white : .primary)
        Spacer()
        if let detail = detail {
          Text(detail)
            .font(.system(size: 12))
            .foregroundColor(isHovered ? .white.opacity(0.85) : .secondary)
        }
      }
      .padding(.horizontal, 8)
      .frame(minHeight: 24)
      .background(
        RoundedRectangle(cornerRadius: 5)
          .fill(isHovered ? Color(NSColor.selectedContentBackgroundColor) : Color.clear)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .onHover { isHovered = $0 }
  }
}
