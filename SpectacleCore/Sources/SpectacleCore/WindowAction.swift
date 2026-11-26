/// A window action that moves or resizes the frontmost window.
///
/// The raw values match the Objective-C `kSpectacleWindowAction…` constants, so the two sides can
/// pass actions to each other as strings while the app is being ported to Swift. Undo and redo
/// aren't layout actions (they replay history), so they aren't listed here.
public enum WindowAction: String, CaseIterable {
  case center = "SpectacleWindowActionCenter"
  case fullscreen = "SpectacleWindowActionFullscreen"
  case leftHalf = "SpectacleWindowActionLeftHalf"
  case rightHalf = "SpectacleWindowActionRightHalf"
  case topHalf = "SpectacleWindowActionTopHalf"
  case bottomHalf = "SpectacleWindowActionBottomHalf"
  case upperLeft = "SpectacleWindowActionUpperLeft"
  case upperRight = "SpectacleWindowActionUpperRight"
  case lowerLeft = "SpectacleWindowActionLowerLeft"
  case lowerRight = "SpectacleWindowActionLowerRight"
  case nextDisplay = "SpectacleWindowActionNextDisplay"
  case previousDisplay = "SpectacleWindowActionPreviousDisplay"
  case nextThird = "SpectacleWindowActionNextThird"
  case previousThird = "SpectacleWindowActionPreviousThird"
  case larger = "SpectacleWindowActionLarger"
  case smaller = "SpectacleWindowActionSmaller"
}
