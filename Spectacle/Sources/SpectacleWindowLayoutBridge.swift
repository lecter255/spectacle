import CoreGraphics
import Foundation

/// Exposes SpectacleCore's `WindowLayout` to the Objective-C side of the app while the rest of it
/// is ported to Swift. SpectacleCore itself stays free of CoreGraphics and Objective-C so it can be
/// built and tested on any platform; the conversions live here.
///
/// It is `public` because, without a bridging header, only public declarations are written to the
/// generated `Spectacle-Swift.h` that the Objective-C code imports.
@objc(SpectacleWindowLayoutBridge)
public final class SpectacleWindowLayoutBridge: NSObject {
  /// The frame for the window after performing `actionName` (a `kSpectacleWindowAction…`
  /// constant), or `CGRect.null` if the action isn't a layout action (undo, redo, none).
  ///
  /// For halves and corners the window takes `fractionNumerator / fractionDenominator` of the
  /// screen along the action's axis; a plain press passes 1/2. Other actions ignore the fraction.
  @objc(frameForAction:windowRect:visibleFrameOfSourceScreen:visibleFrameOfDestinationScreen:fractionNumerator:fractionDenominator:)
  public static func frame(
    forAction actionName: String,
    windowRect: CGRect,
    visibleFrameOfSourceScreen: CGRect,
    visibleFrameOfDestinationScreen: CGRect,
    fractionNumerator: Double,
    fractionDenominator: Double
  ) -> CGRect {
    guard let action = WindowAction(rawValue: actionName), fractionDenominator != 0 else {
      return .null
    }
    let frame = WindowLayout.frame(
      for: action,
      window: Rect(windowRect),
      sourceScreen: Rect(visibleFrameOfSourceScreen),
      destinationScreen: Rect(visibleFrameOfDestinationScreen),
      fraction: Fraction(numerator: fractionNumerator, denominator: fractionDenominator))
    return CGRect(x: frame.x, y: frame.y, width: frame.width, height: frame.height)
  }
}

/// Exposes SpectacleCore's `ScreenSelection` to the Objective-C `SpectacleScreenDetector`.
/// Screens are passed as frames (`NSValue`-wrapped rects) and returned as indices, or -1 for none.
@objc(SpectacleScreenSelectionBridge)
public final class SpectacleScreenSelectionBridge: NSObject {
  @objc(screenIndexContainingWindowRect:screenFrames:primaryScreenHeight:fallbackIndex:)
  public static func screenIndex(
    containingWindowRect windowRect: CGRect,
    screenFrames: [NSValue],
    primaryScreenHeight: CGFloat,
    fallbackIndex: Int
  ) -> Int {
    ScreenSelection.screenIndex(
      containing: Rect(windowRect),
      screens: screenFrames.map { Rect($0.rectValue) },
      primaryScreenHeight: Double(primaryScreenHeight),
      fallback: fallbackIndex >= 0 ? fallbackIndex : nil) ?? -1
  }

  @objc(adjacentScreenIndexTo:screenFrames:next:)
  public static func adjacentScreenIndex(to index: Int, screenFrames: [NSValue], next: Bool) -> Int {
    ScreenSelection.adjacentScreenIndex(
      to: index,
      in: screenFrames.map { Rect($0.rectValue) },
      direction: next ? .next : .previous) ?? -1
  }
}

/// Converts AppKit and CoreGraphics rects for SpectacleCore. Shared by every Swift file in the app.
extension Rect {
  init(_ rect: CGRect) {
    self.init(
      x: Double(rect.origin.x),
      y: Double(rect.origin.y),
      width: Double(rect.size.width),
      height: Double(rect.size.height))
  }
}
