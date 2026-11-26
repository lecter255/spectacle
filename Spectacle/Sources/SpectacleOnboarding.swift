import AppKit
import SwiftUI

/// What the first-run tour needs from the Objective-C side.
///
/// It is `public` because, without a bridging header, only public declarations are written to the
/// generated `Spectacle-Swift.h` that the Objective-C code imports.
@objc(SpectacleOnboardingDelegate)
public protocol SpectacleOnboardingDelegate: AnyObject {
  /// The shortcut's display string, such as "⌥⌘←", or nil if it has none.
  @objc(onboardingShortcutDisplayStringForShortcutName:)
  func onboardingShortcutDisplayString(forShortcutName shortcutName: String) -> String?
  /// The stored name of the shortcut `event` presses, or nil. Spectacle's own shortcuts are off
  /// while it is frontmost, so the tour watches for them itself.
  @objc(onboardingShortcutNameMatchingEvent:)
  func onboardingShortcutName(matching event: NSEvent) -> String?
  /// Performs a shortcut on the frontmost window, which is the tour's own window.
  @objc(onboardingPerformShortcutNamed:)
  func onboardingPerformShortcut(named shortcutName: String)
  @objc(onboardingOpenAccessibilitySettings)
  func onboardingOpenAccessibilitySettings()
  @objc(onboardingShowSettings)
  func onboardingShowSettings()
}

/// The first-run tour: asks for Accessibility access if needed, then has people try a half, a
/// corner and Fill Screen on the tour's own window.
@objc(SpectacleOnboardingWindowController)
public final class SpectacleOnboardingWindowController: NSObject, NSWindowDelegate {
  /// Set once the tour has been finished or skipped, so it shows only on first launch.
  @objc public static let completedDefaultsKey = "SpectacleOnboardingCompleted"
  /// Posted by the settings window's "Show Welcome Tour" button.
  @objc public static let showNotificationName = "SpectacleShowOnboardingNotification"

  @objc public static var isCompleted: Bool {
    UserDefaults.standard.bool(forKey: completedDefaultsKey)
  }

  @objc public weak var delegate: SpectacleOnboardingDelegate? {
    didSet { model.delegate = delegate }
  }

  private let model = OnboardingModel()
  private var window: NSWindow?
  private var keyMonitor: Any?

  @objc public func show() {
    let window = self.window ?? makeWindow()
    model.start()
    window.center()
    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
    startWatchingKeys()
  }

  public func windowWillClose(_ notification: Notification) {
    finish()
  }

  private func finish() {
    UserDefaults.standard.set(true, forKey: Self.completedDefaultsKey)
    model.stop()
    if let keyMonitor = keyMonitor {
      NSEvent.removeMonitor(keyMonitor)
      self.keyMonitor = nil
    }
  }

  private func close() {
    finish()
    window?.orderOut(nil)
  }

  private func startWatchingKeys() {
    guard keyMonitor == nil else {
      return
    }
    keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      guard let self = self, event.window === self.window,
        let shortcutName = self.model.delegate?.onboardingShortcutName(matching: event)
      else {
        return event
      }
      self.model.didPress(shortcutName)
      return nil
    }
  }

  private func makeWindow() -> NSWindow {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 640, height: 580),
      styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
      backing: .buffered,
      defer: true
    )
    window.titlebarAppearsTransparent = true
    window.title = "Welcome to \(appDisplayName)"
    window.isReleasedWhenClosed = false
    window.minSize = NSSize(width: 460, height: 420)
    window.delegate = self
    model.onClose = { [weak self] in self?.close() }
    window.contentView = NSHostingView(rootView: OnboardingView(model: model))
    self.window = window
    return window
  }
}

/// One "try it" step of the tour.
struct OnboardingLesson: Equatable {
  var shortcutName: String
  var heading: String
  var detail: String
  var nextTitle: String
}

final class OnboardingModel: ObservableObject {
  enum Step: Equatable {
    case permission
    case lesson(Int)
    case done
  }

  static let lessons = [
    OnboardingLesson(
      shortcutName: "MoveToLeftHalf",
      heading: "Snap this window to the left",
      detail: "Then keep the keys held and press the opposite arrow to grow it, or the same arrow to shrink it.",
      nextTitle: "Next: corners"),
    OnboardingLesson(
      shortcutName: "MoveToUpperRight",
      heading: "Now try a corner",
      detail: "Corners resize the same way while you keep the keys held.",
      nextTitle: "Next: fill the screen"),
    OnboardingLesson(
      shortcutName: "MoveToFullscreen",
      heading: "Fill the screen",
      detail: "Undo puts a window back where it was, one move at a time.",
      nextTitle: "Finish"),
  ]

  weak var delegate: SpectacleOnboardingDelegate?
  var onClose: () -> Void = {}

  @Published var step: Step = .permission
  @Published var justGranted = false
  @Published var completedLessons: Set<Int> = []
  @Published var shortcuts: [String: String] = [:]

  private let permission = SpectacleAccessibilityPermission()

  func start() {
    completedLessons = []
    justGranted = false
    var strings: [String: String] = [:]
    for lesson in Self.lessons {
      strings[lesson.shortcutName] = delegate?.onboardingShortcutDisplayString(forShortcutName: lesson.shortcutName)
    }
    strings["UndoLastMove"] = delegate?.onboardingShortcutDisplayString(forShortcutName: "UndoLastMove")
    shortcuts = strings
    if SpectacleAccessibilityPermission.isGranted {
      step = .lesson(0)
    } else {
      step = .permission
      permission.waitUntilGranted(checkingEvery: 1) { [weak self] in
        self?.justGranted = true
        self?.step = .lesson(0)
      }
    }
  }

  func stop() {
    permission.stopWaiting()
  }

  func didPress(_ shortcutName: String) {
    delegate?.onboardingPerformShortcut(named: shortcutName)
    if case .lesson(let index) = step, Self.lessons[index].shortcutName == shortcutName {
      completedLessons.insert(index)
    }
  }

  func next() {
    switch step {
    case .permission:
      step = .lesson(0)
    case .lesson(let index):
      justGranted = false
      step = index + 1 < Self.lessons.count ? .lesson(index + 1) : .done
    case .done:
      onClose()
    }
  }

  var progress: Double {
    switch step {
    case .permission: return 0
    case .lesson(let index): return Double(index + (completedLessons.contains(index) ? 1 : 0)) / Double(Self.lessons.count)
    case .done: return 1
    }
  }
}

private let successGreen = adaptiveColor(light: 0x1E7F4F, dark: 0x5FD68F)
private let successWash = adaptiveColor(light: 0xE6F5EC, dark: 0x1F3A2B)

struct OnboardingView: View {
  @ObservedObject var model: OnboardingModel

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 20) {
        if model.justGranted {
          Banner(text: "Accessibility access is on. Now try a shortcut.")
        }
        Spacer(minLength: 0)
        switch model.step {
        case .permission:
          PermissionStep(model: model)
        case .lesson(let index):
          LessonStep(
            lesson: OnboardingModel.lessons[index],
            shortcut: model.shortcuts[OnboardingModel.lessons[index].shortcutName],
            isComplete: model.completedLessons.contains(index))
        case .done:
          DoneStep()
        }
        Spacer(minLength: 0)
        if model.step != .permission {
          ProgressBar(value: model.progress)
            .frame(width: 220, height: 5)
        }
      }
      .padding(.horizontal, 36)
      .padding(.top, 36)
      .padding(.bottom, 20)

      Divider()

      HStack {
        if model.step != .done {
          Button("Skip the tour") { model.onClose() }
            .buttonStyle(LinkButtonStyle())
        }
        Spacer()
        switch model.step {
        case .permission:
          EmptyView()
        case .lesson(let index):
          Button(OnboardingModel.lessons[index].nextTitle) { model.next() }
            .keyboardShortcut(.defaultAction)
        case .done:
          Button("Open Settings") {
            model.delegate?.onboardingShowSettings()
            model.onClose()
          }
          Button("Done") { model.onClose() }
            .keyboardShortcut(.defaultAction)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 14)
    }
    .frame(minWidth: 460, minHeight: 420)
  }
}

struct Banner: View {
  let text: String

  var body: some View {
    HStack(spacing: 8) {
      Text("✓").font(.system(size: 13, weight: .bold))
      Text(text).font(.system(size: 12.5, weight: .medium))
      Spacer(minLength: 0)
    }
    .foregroundColor(successGreen)
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(RoundedRectangle(cornerRadius: 9).fill(successWash))
  }
}

struct PermissionStep: View {
  @ObservedObject var model: OnboardingModel

  var body: some View {
    VStack(spacing: 14) {
      Text("Let \(appDisplayName) move your windows")
        .font(.system(size: 22, weight: .bold))
        .multilineTextAlignment(.center)
      Text("macOS needs you to turn on Accessibility access for \(appDisplayName). Open System Settings, find \(appDisplayName) under Privacy & Security › Accessibility, and switch it on. This window moves on by itself once it's on.")
        .font(.system(size: 13))
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: 440)
      Button("Open System Settings") {
        model.delegate?.onboardingOpenAccessibilitySettings()
      }
      .keyboardShortcut(.defaultAction)
      .padding(.top, 6)
    }
  }
}

struct LessonStep: View {
  let lesson: OnboardingLesson
  let shortcut: String?
  let isComplete: Bool

  var body: some View {
    VStack(spacing: 14) {
      Text(lesson.heading)
        .font(.system(size: 22, weight: .bold))
        .multilineTextAlignment(.center)
      Text(lesson.detail)
        .font(.system(size: 13))
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: 420)
      if let shortcut = shortcut {
        HStack(spacing: 8) {
          ForEach(Array(keycaps(for: shortcut).enumerated()), id: \.offset) { _, key in
            Keycap(label: key)
          }
        }
        .padding(.top, 8)
      } else {
        Text("This action has no shortcut. You can add one in Settings.")
          .font(.system(size: 12))
          .foregroundColor(.secondary)
      }
      Text(isComplete ? "Nice. Try it again, or move on." : "Press the keys above.")
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(isComplete ? successGreen : .secondary)
    }
  }
}

/// Splits a shortcut's display string into keycaps: one per modifier symbol, then the key.
func keycaps(for shortcut: String) -> [String] {
  let modifiers: Set<Character> = ["⌃", "⌥", "⇧", "⌘"]
  var caps: [String] = []
  var key = ""
  for character in shortcut {
    if modifiers.contains(character) && key.isEmpty {
      caps.append(String(character))
    } else {
      key.append(character)
    }
  }
  if !key.isEmpty {
    caps.append(key)
  }
  return caps
}

struct Keycap: View {
  let label: String

  var body: some View {
    Text(label)
      .font(.system(size: 22, weight: .medium))
      .frame(minWidth: 52, minHeight: 52)
      .padding(.horizontal, label.count > 1 ? 10 : 0)
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(Color(NSColor.controlBackgroundColor))
          .shadow(color: Color.black.opacity(0.18), radius: 0, x: 0, y: 2)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
      )
  }
}

struct DoneStep: View {
  var body: some View {
    VStack(spacing: 14) {
      Text("You're all set")
        .font(.system(size: 22, weight: .bold))
      Text("\(appDisplayName) lives in the menu bar. Click its icon for the layout grid, or right-click it for the full menu. Change any shortcut in Settings.")
        .font(.system(size: 13))
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: 420)
    }
  }
}

struct ProgressBar: View {
  let value: Double

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule().fill(Color.primary.opacity(0.1))
        Capsule()
          .fill(panelAccent)
          .frame(width: geometry.size.width * CGFloat(min(max(value, 0), 1)))
      }
    }
    .animation(.easeOut(duration: 0.2), value: value)
  }
}
