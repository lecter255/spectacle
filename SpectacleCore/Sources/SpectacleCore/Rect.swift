/// A rectangle in screen coordinates, with the origin at the bottom left and y increasing upwards
/// (the AppKit convention used for `NSScreen.visibleFrame`).
///
/// This mirrors `CGRect` without depending on CoreGraphics so the layout code stays portable.
public struct Rect: Hashable, CustomStringConvertible {
  public var x: Double
  public var y: Double
  public var width: Double
  public var height: Double

  public init(x: Double, y: Double, width: Double, height: Double) {
    self.x = x
    self.y = y
    self.width = width
    self.height = height
  }

  /// The same rectangle with a non-negative width and height, like `CGRectStandardize`.
  public var standardized: Rect {
    Rect(
      x: width < 0 ? x + width : x,
      y: height < 0 ? y + height : y,
      width: abs(width),
      height: abs(height))
  }

  public var minX: Double { standardized.x }
  public var minY: Double { standardized.y }
  public var midX: Double { standardized.x + standardized.width / 2 }
  public var midY: Double { standardized.y + standardized.height / 2 }
  public var maxX: Double { standardized.x + standardized.width }
  public var maxY: Double { standardized.y + standardized.height }

  public var isEmpty: Bool { width == 0 || height == 0 }

  /// Whether `other` lies entirely inside this rectangle, like `CGRectContainsRect`.
  public func contains(_ other: Rect) -> Bool {
    if isEmpty || other.isEmpty {
      return false
    }
    return other.minX >= minX && other.minY >= minY && other.maxX <= maxX && other.maxY <= maxY
  }

  /// Whether `other` lies inside this rectangle and their centers are within one point of each
  /// other. Used to recognise "the window is already in this position", allowing for apps that
  /// round their frames slightly differently.
  func isCentered(on other: Rect) -> Bool {
    contains(other) && abs(other.midX - midX) <= 1 && abs(other.midY - midY) <= 1
  }

  /// Whether this rectangle's size fits within `other`'s, ignoring position.
  func fits(within other: Rect) -> Bool {
    width <= other.width && height <= other.height
  }

  public var description: String {
    "{{\(format(x)), \(format(y))}, {\(format(width)), \(format(height))}}"
  }

  private func format(_ value: Double) -> String {
    value == value.rounded() && abs(value) < 1e15 ? String(Int(value)) : String(value)
  }
}

extension Double {
  /// `Math.floor`, which the original JavaScript calculations used throughout.
  var floored: Double { rounded(.down) }

  /// `Math.round`: rounds halves towards positive infinity (so -2.5 becomes -2), unlike
  /// `rounded()`, which rounds them away from zero.
  var roundedHalfUp: Double { (self + 0.5).rounded(.down) }
}
