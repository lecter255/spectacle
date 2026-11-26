import AppKit
import Foundation

/// Applies the user's light, dark or system appearance to the whole app, the snap HUD included.
///
/// The choice is stored in user defaults under `AppearancePreference.defaultsKey`. Nothing stored
/// means "Match System", which leaves `NSApp.appearance` nil so AppKit follows the system setting
/// and switches automatically when it changes.
///
/// It is `public` because, without a bridging header, only public declarations are written to the
/// generated `Spectacle-Swift.h` that the Objective-C code imports.
@objc(SpectacleAppearance)
public final class SpectacleAppearance: NSObject {
  @objc public static let shared = SpectacleAppearance()

  private let userDefaults: UserDefaults
  private var defaultsObserver: NSObjectProtocol?
  private var applied: AppearancePreference?

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
    super.init()
  }

  deinit {
    if let defaultsObserver = defaultsObserver {
      NotificationCenter.default.removeObserver(defaultsObserver)
    }
  }

  /// Applies the stored preference now and again whenever it changes.
  @objc public func start() {
    apply()
    guard defaultsObserver == nil else {
      return
    }
    defaultsObserver = NotificationCenter.default.addObserver(
      forName: UserDefaults.didChangeNotification, object: userDefaults, queue: .main
    ) { [weak self] _ in
      self?.apply()
    }
  }

  var preference: AppearancePreference {
    get { AppearancePreference(storedValue: userDefaults.string(forKey: AppearancePreference.defaultsKey)) }
    set {
      if newValue == .system {
        userDefaults.removeObject(forKey: AppearancePreference.defaultsKey)
      } else {
        userDefaults.set(newValue.rawValue, forKey: AppearancePreference.defaultsKey)
      }
      apply()
    }
  }

  private func apply() {
    let preference = self.preference
    guard preference != applied else {
      return
    }
    applied = preference
    switch preference {
    case .system:
      NSApp.appearance = nil
    case .light:
      NSApp.appearance = NSAppearance(named: .aqua)
    case .dark:
      NSApp.appearance = NSAppearance(named: .darkAqua)
    }
  }
}

/// The status menu's Appearance submenu and "Show Snap HUD" toggle. These live here until the new
/// settings window replaces the old preferences window.
@objc(SpectacleDisplaySettingsMenu)
public final class SpectacleDisplaySettingsMenu: NSObject {
  private let appearanceItems: [(AppearancePreference, NSMenuItem)]
  private let snapHUDItem: NSMenuItem
  private let appearanceItem: NSMenuItem

  @objc public override init() {
    appearanceItems = AppearancePreference.allCases.map { preference in
      (preference, NSMenuItem(title: preference.title, action: nil, keyEquivalent: ""))
    }
    snapHUDItem = NSMenuItem(title: "Show Snap HUD", action: nil, keyEquivalent: "")
    appearanceItem = NSMenuItem(title: "Appearance", action: nil, keyEquivalent: "")
    super.init()
    let submenu = NSMenu(title: "Appearance")
    for (index, (_, item)) in appearanceItems.enumerated() {
      item.target = self
      item.action = #selector(chooseAppearance(_:))
      item.tag = index
      submenu.addItem(item)
    }
    appearanceItem.submenu = submenu
    snapHUDItem.target = self
    snapHUDItem.action = #selector(toggleSnapHUD(_:))
    refresh()
  }

  /// The items to add to the status menu, in order.
  @objc public var menuItems: [NSMenuItem] {
    [snapHUDItem, appearanceItem]
  }

  /// Updates the check marks. Call it before the menu opens.
  @objc public func refresh() {
    let current = SpectacleAppearance.shared.preference
    for (preference, item) in appearanceItems {
      item.state = preference == current ? .on : .off
    }
    snapHUDItem.state = SpectacleSnapHUD.isEnabled ? .on : .off
  }

  @objc private func chooseAppearance(_ sender: NSMenuItem) {
    guard appearanceItems.indices.contains(sender.tag) else {
      return
    }
    SpectacleAppearance.shared.preference = appearanceItems[sender.tag].0
    refresh()
  }

  @objc private func toggleSnapHUD(_ sender: NSMenuItem) {
    SpectacleSnapHUD.isEnabled.toggle()
    refresh()
  }
}
