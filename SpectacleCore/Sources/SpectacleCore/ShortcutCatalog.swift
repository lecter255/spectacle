/// Every shortcut the app offers, grouped the way the settings window shows them.
///
/// Shortcut names match the keys the app stores shortcuts under ("MoveToLeftHalf" and so on).
public enum ShortcutCatalog {
  public struct Entry: Equatable, Hashable {
    /// The name the shortcut is stored under.
    public var shortcutName: String
    /// The layout it performs, or nil for undo and redo.
    public var action: WindowAction?
    /// The name shown in the settings window.
    public var title: String
  }

  public struct Section: Equatable {
    public var title: String
    public var entries: [Entry]
  }

  public static let sections: [Section] = [
    Section(title: "Halves", entries: [
      entry("MoveToLeftHalf", .leftHalf),
      entry("MoveToRightHalf", .rightHalf),
      entry("MoveToTopHalf", .topHalf),
      entry("MoveToBottomHalf", .bottomHalf),
    ]),
    Section(title: "Corners", entries: [
      entry("MoveToUpperLeft", .upperLeft),
      entry("MoveToUpperRight", .upperRight),
      entry("MoveToLowerLeft", .lowerLeft),
      entry("MoveToLowerRight", .lowerRight),
    ]),
    Section(title: "Center, fill and size", entries: [
      entry("MoveToCenter", .center),
      entry("MoveToFullscreen", .fullscreen),
      entry("MakeLarger", .larger),
      entry("MakeSmaller", .smaller),
    ]),
    Section(title: "Thirds", entries: [
      entry("MoveToNextThird", .nextThird),
      entry("MoveToPreviousThird", .previousThird),
    ]),
    Section(title: "Displays", entries: [
      entry("MoveToNextDisplay", .nextDisplay),
      entry("MoveToPreviousDisplay", .previousDisplay),
    ]),
    Section(title: "History", entries: [
      Entry(shortcutName: "UndoLastMove", action: nil, title: "Undo Last Move"),
      Entry(shortcutName: "RedoLastMove", action: nil, title: "Redo Last Move"),
    ]),
  ]

  public static var entries: [Entry] {
    sections.flatMap(\.entries)
  }

  public static func entry(named shortcutName: String) -> Entry? {
    entries.first { $0.shortcutName == shortcutName }
  }

  private static func entry(_ shortcutName: String, _ action: WindowAction) -> Entry {
    Entry(shortcutName: shortcutName, action: action, title: action.title)
  }
}
