import AppKit
import SwiftUI

/// What the settings window needs from the Objective-C side: the shortcut recorders, the shortcut
/// labels, and the settings that still live there.
///
/// It is `public` because, without a bridging header, only public declarations are written to the
/// generated `Spectacle-Swift.h` that the Objective-C code imports.
@objc(SpectacleSettingsDataSource)
public protocol SpectacleSettingsDataSource: AnyObject {
  /// The shortcut recorder view for a stored shortcut name, such as "MoveToLeftHalf".
  @objc(settingsShortcutRecorderForShortcutName:)
  func settingsShortcutRecorder(forShortcutName shortcutName: String) -> NSView
  /// The shortcut's display string, such as "⌥⌘←", or nil if it has none.
  @objc(settingsShortcutDisplayStringForShortcutName:)
  func settingsShortcutDisplayString(forShortcutName shortcutName: String) -> String?
  /// Asks for confirmation, then restores every default shortcut.
  @objc(settingsRestoreDefaultShortcuts)
  func settingsRestoreDefaultShortcuts()
  @objc(settingsIsLoginItemEnabled)
  func settingsIsLoginItemEnabled() -> Bool
  @objc(settingsSetLoginItemEnabled:)
  func settingsSetLoginItemEnabled(_ enabled: Bool)
  @objc(settingsIsStatusItemEnabled)
  func settingsIsStatusItemEnabled() -> Bool
  /// Shows or hides the menu bar icon. Hiding it may ask for confirmation first, so callers read
  /// `settingsIsStatusItemEnabled` again afterwards.
  @objc(settingsSetStatusItemEnabled:)
  func settingsSetStatusItemEnabled(_ enabled: Bool)
}

/// The settings window: a Layouts tab with a card for every shortcut and an inspector to change
/// it, and a General tab for launch, menu bar, appearance and HUD options.
@objc(SpectacleSettingsWindowController)
public final class SpectacleSettingsWindowController: NSObject {
  @objc public let window: NSWindow
  private let model: SettingsModel

  @objc(initWithDataSource:)
  public init(dataSource: SpectacleSettingsDataSource) {
    model = SettingsModel(dataSource: dataSource)
    window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 880, height: 580),
      styleMask: [.titled, .closable, .miniaturizable],
      backing: .buffered,
      defer: true
    )
    super.init()
    window.title = "\(appDisplayName) Settings"
    window.isReleasedWhenClosed = false
    window.contentView = NSHostingView(rootView: SettingsView(model: model))
    window.center()
    window.setFrameAutosaveName("SpectacleSettingsWindow")
    model.reload()
  }

  /// Reads shortcuts and settings again, after they change elsewhere.
  @objc public func reload() {
    model.reload()
  }
}

/// The app's name in the new interface. One place to change when the app is renamed.
let appDisplayName = "Lens"

final class SettingsModel: ObservableObject {
  enum Tab: Hashable {
    case layouts
    case general
  }

  weak var dataSource: SpectacleSettingsDataSource?

  @Published var tab: Tab = .layouts
  @Published var selectedShortcutName = ShortcutCatalog.entries[0].shortcutName
  @Published private(set) var displayStrings: [String: String] = [:]
  @Published private(set) var isLoginItemEnabled = false
  @Published private(set) var isStatusItemEnabled = true
  @Published private(set) var appearance = AppearancePreference.system
  @Published private(set) var isSnapHUDEnabled = true

  init(dataSource: SpectacleSettingsDataSource) {
    self.dataSource = dataSource
  }

  func reload() {
    var strings: [String: String] = [:]
    for entry in ShortcutCatalog.entries {
      strings[entry.shortcutName] = dataSource?.settingsShortcutDisplayString(forShortcutName: entry.shortcutName)
    }
    displayStrings = strings
    isLoginItemEnabled = dataSource?.settingsIsLoginItemEnabled() ?? false
    isStatusItemEnabled = dataSource?.settingsIsStatusItemEnabled() ?? true
    appearance = SpectacleAppearance.shared.preference
    isSnapHUDEnabled = SpectacleSnapHUD.isEnabled
    resizeSizes = StoredResizeSizes.current
  }

  var selectedEntry: ShortcutCatalog.Entry {
    ShortcutCatalog.entry(named: selectedShortcutName) ?? ShortcutCatalog.entries[0]
  }

  func recorder(for shortcutName: String) -> NSView {
    dataSource?.settingsShortcutRecorder(forShortcutName: shortcutName) ?? NSView()
  }

  var loginItemBinding: Binding<Bool> {
    Binding(get: { self.isLoginItemEnabled }, set: { enabled in
      self.dataSource?.settingsSetLoginItemEnabled(enabled)
      self.reload()
    })
  }

  var statusItemBinding: Binding<Bool> {
    Binding(get: { self.isStatusItemEnabled }, set: { enabled in
      self.dataSource?.settingsSetStatusItemEnabled(enabled)
      self.reload()
    })
  }

  var appearanceBinding: Binding<AppearancePreference> {
    Binding(get: { self.appearance }, set: { preference in
      SpectacleAppearance.shared.preference = preference
      self.reload()
    })
  }

  var snapHUDBinding: Binding<Bool> {
    Binding(get: { self.isSnapHUDEnabled }, set: { enabled in
      SpectacleSnapHUD.isEnabled = enabled
      self.reload()
    })
  }

  @Published private(set) var resizeSizes = StoredResizeSizes.current

  func sizeBinding(_ fraction: Fraction) -> Binding<Bool> {
    Binding(get: { self.resizeSizes.contains(fraction) }, set: { enabled in
      var sizes = self.resizeSizes.filter { $0 != fraction }
      if enabled {
        sizes.append(fraction)
      }
      StoredResizeSizes.current = sizes
      self.reload()
    })
  }

  func restoreDefaults() {
    dataSource?.settingsRestoreDefaultShortcuts()
    reload()
  }
}

struct SettingsView: View {
  @ObservedObject var model: SettingsModel

  var body: some View {
    VStack(spacing: 0) {
      Picker("", selection: $model.tab) {
        Text("Layouts").tag(SettingsModel.Tab.layouts)
        Text("General").tag(SettingsModel.Tab.general)
      }
      .pickerStyle(SegmentedPickerStyle())
      .labelsHidden()
      .frame(width: 240)
      .padding(.vertical, 12)

      Divider()

      switch model.tab {
      case .layouts:
        HStack(spacing: 0) {
          ShortcutGrid(model: model)
          Divider()
          ShortcutInspector(model: model)
            .frame(width: 290)
        }
      case .general:
        GeneralSettings(model: model)
      }
    }
    .frame(minWidth: 880, minHeight: 580)
  }
}

struct ShortcutGrid: View {
  @ObservedObject var model: SettingsModel
  private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        ForEach(ShortcutCatalog.sections, id: \.title) { section in
          VStack(alignment: .leading, spacing: 8) {
            Text(section.title)
              .font(.system(size: 11, weight: .semibold))
              .foregroundColor(.secondary)
            LazyVGrid(columns: columns, spacing: 12) {
              ForEach(section.entries, id: \.shortcutName) { entry in
                ShortcutCard(
                  entry: entry,
                  shortcut: model.displayStrings[entry.shortcutName],
                  isSelected: entry.shortcutName == model.selectedShortcutName
                ) {
                  model.selectedShortcutName = entry.shortcutName
                }
              }
            }
          }
        }
      }
      .padding(20)
    }
  }
}

struct ShortcutIcon: View {
  let entry: ShortcutCatalog.Entry
  let isHighlighted: Bool

  var body: some View {
    if let action = entry.action {
      TileIcon(action: action, isCurrent: isHighlighted)
    } else {
      ZStack {
        RoundedRectangle(cornerRadius: 4)
          .strokeBorder(Color.secondary.opacity(isHighlighted ? 0.9 : 0.5), lineWidth: 1.25)
        Text(entry.shortcutName == "UndoLastMove" ? "↶" : "↷")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(isHighlighted ? panelAccent : .secondary)
      }
    }
  }
}

struct ShortcutCard: View {
  let entry: ShortcutCatalog.Entry
  let shortcut: String?
  let isSelected: Bool
  let onSelect: () -> Void

  var body: some View {
    Button(action: onSelect) {
      VStack(alignment: .leading, spacing: 8) {
        ShortcutIcon(entry: entry, isHighlighted: isSelected)
          .frame(width: 48, height: 32)
        Text(entry.title)
          .font(.system(size: 12.5, weight: .semibold))
          .foregroundColor(.primary)
          .lineLimit(1)
        ShortcutChip(text: shortcut)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(isSelected ? panelAccentWash : Color.primary.opacity(0.04))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .strokeBorder(isSelected ? panelAccent : Color.primary.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
      )
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
  }
}

struct ShortcutChip: View {
  let text: String?

  var body: some View {
    Text(text ?? "None")
      .font(.system(size: 11.5, weight: .medium))
      .foregroundColor(text == nil ? .secondary : .primary)
      .padding(.horizontal, 7)
      .padding(.vertical, 3)
      .background(RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.08)))
  }
}

struct ShortcutInspector: View {
  @ObservedObject var model: SettingsModel

  var body: some View {
    let entry = model.selectedEntry
    VStack(alignment: .leading, spacing: 16) {
      Text(entry.title)
        .font(.system(size: 17, weight: .bold))
      ShortcutIcon(entry: entry, isHighlighted: true)
        .frame(width: 150, height: 100)
        .frame(maxWidth: .infinity)
      VStack(alignment: .leading, spacing: 6) {
        Text("Shortcut")
          .font(.system(size: 11, weight: .semibold))
          .foregroundColor(.secondary)
        RecorderHost(view: model.recorder(for: entry.shortcutName))
          .id(entry.shortcutName)
          .frame(width: 200, height: 24)
        Text("Click to change. Click × to clear.")
          .font(.system(size: 11))
          .foregroundColor(.secondary)
      }
      if let action = entry.action, action.resizeMirror != nil {
        VStack(alignment: .leading, spacing: 6) {
          Text("Press again for")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
          ForEach(ResizeSession.sizes, id: \.self) { fraction in
            Toggle(isOn: model.sizeBinding(fraction)) {
              HStack(spacing: 8) {
                Text(fraction.glyph)
                  .font(.system(size: 13, weight: .semibold))
                  .frame(width: 18)
                Text(sizeName(fraction))
              }
            }
            .disabled(fraction == .oneHalf)
          }
          Text("Halves and corners start at ½. Keep the keys held and press again to shrink, or press the opposite side to grow. Applies to every half and corner.")
            .font(.system(size: 11))
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      Spacer()
    }
    .padding(20)
  }
}

private func sizeName(_ fraction: Fraction) -> String {
  switch fraction.storedValue {
  case "1/4": return "One quarter"
  case "1/3": return "One third"
  case "1/2": return "Half (always on)"
  case "2/3": return "Two thirds"
  case "3/4": return "Three quarters"
  default: return fraction.storedValue
  }
}

/// Hosts an existing AppKit view, such as a shortcut recorder, in SwiftUI.
struct RecorderHost: NSViewRepresentable {
  let view: NSView

  func makeNSView(context: Context) -> NSView {
    view
  }

  func updateNSView(_ nsView: NSView, context: Context) {}
}

struct GeneralSettings: View {
  @ObservedObject var model: SettingsModel

  var body: some View {
    VStack(alignment: .leading, spacing: 22) {
      SettingsGroup(title: "Startup") {
        Toggle("Launch \(appDisplayName) at login", isOn: model.loginItemBinding)
        Toggle("Show icon in the menu bar", isOn: model.statusItemBinding)
      }
      SettingsGroup(title: "Look") {
        HStack {
          Text("Appearance")
          Picker("", selection: model.appearanceBinding) {
            ForEach(AppearancePreference.allCases, id: \.self) { preference in
              Text(preference.title).tag(preference)
            }
          }
          .pickerStyle(SegmentedPickerStyle())
          .labelsHidden()
          .frame(width: 300)
        }
        Toggle("Show the snap HUD after each move", isOn: model.snapHUDBinding)
      }
      SettingsGroup(title: "Shortcuts") {
        Button("Restore Default Shortcuts…") {
          model.restoreDefaults()
        }
      }
      Spacer()
      Text("\(appDisplayName) is based on Spectacle by Eric Czarny, released under the MIT License.")
        .font(.system(size: 11))
        .foregroundColor(.secondary)
    }
    .padding(28)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

struct SettingsGroup<Content: View>: View {
  let title: String
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.secondary)
      VStack(alignment: .leading, spacing: 8, content: content)
    }
  }
}
