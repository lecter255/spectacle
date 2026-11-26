/// Makes a window larger or smaller while keeping it in contact with any screen edges it touches.
enum WindowResizer {
  /// Windows within this many points of a screen edge count as touching it.
  static let edgeTolerance: Double = 5

  static func resize(_ window: Rect, screen: Rect, by sizeOffset: Double) -> Rect {
    let halfOffset = (sizeOffset / 2).floored
    var resized = window
    resized.width += sizeOffset
    resized.x -= halfOffset
    resized = adjustedHorizontally(original: window, resized: resized, screen: screen)
    if resized.width >= screen.width {
      resized.width = screen.width
    }
    resized.height += sizeOffset
    resized.y -= halfOffset
    resized = adjustedVertically(original: window, resized: resized, screen: screen)
    if resized.height >= screen.height {
      resized.height = screen.height
      resized.y = window.y
    }
    if touchesAllEdges(window, screen) && sizeOffset < 0 {
      resized = Rect(
        x: window.x - halfOffset,
        y: window.y - halfOffset,
        width: window.width + sizeOffset,
        height: window.height + sizeOffset)
    }
    if isTooSmall(resized, screen) {
      resized = window
    }
    return resized
  }

  private static func isTouching(_ gap: Double) -> Bool {
    abs(gap) <= edgeTolerance
  }

  private static func touchesLeft(_ window: Rect, _ screen: Rect) -> Bool {
    isTouching(window.x - screen.x)
  }

  private static func touchesRight(_ window: Rect, _ screen: Rect) -> Bool {
    isTouching(window.maxX - screen.maxX)
  }

  private static func touchesTop(_ window: Rect, _ screen: Rect) -> Bool {
    isTouching(window.maxY - screen.maxY)
  }

  private static func touchesBottom(_ window: Rect, _ screen: Rect) -> Bool {
    isTouching(window.y - screen.y)
  }

  private static func touchesAllEdges(_ window: Rect, _ screen: Rect) -> Bool {
    touchesLeft(window, screen) && touchesRight(window, screen)
      && touchesTop(window, screen) && touchesBottom(window, screen)
  }

  private static func adjustedHorizontally(original: Rect, resized: Rect, screen: Rect) -> Rect {
    var adjusted = resized
    if touchesRight(original, screen) {
      adjusted.x = screen.maxX - adjusted.width
      if touchesLeft(original, screen) {
        adjusted.width = screen.width
      }
    }
    if touchesLeft(original, screen) {
      adjusted.x = screen.x
    }
    return adjusted
  }

  private static func adjustedVertically(original: Rect, resized: Rect, screen: Rect) -> Rect {
    var adjusted = resized
    if touchesTop(original, screen) {
      adjusted.y = screen.maxY - adjusted.height
      if touchesBottom(original, screen) {
        adjusted.height = screen.height
      }
    }
    if touchesBottom(original, screen) {
      adjusted.y = screen.y
    }
    return adjusted
  }

  /// Smaller never shrinks a window to a quarter of the screen's width or height or less.
  private static func isTooSmall(_ window: Rect, _ screen: Rect) -> Bool {
    window.width <= (screen.width / 4).floored || window.height <= (screen.height / 4).floored
  }
}
