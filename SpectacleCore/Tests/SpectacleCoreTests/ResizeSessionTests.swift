import XCTest

@testable import SpectacleCore

final class ResizeSessionTests: XCTestCase {
  // Arbitrary opaque modifier masks, standing in for CGEventFlags.
  let option: UInt64 = 1 << 19
  let command: UInt64 = 1 << 20
  let control: UInt64 = 1 << 18
  var optionCommand: UInt64 { option | command }

  let screen = Rect(x: 0, y: 4, width: 1440, height: 873)

  func fractions(_ steps: [WindowAction], startingWith action: WindowAction) -> [String] {
    var tracker = ResizeSessionTracker()
    return ([action] + steps).map { "\(tracker.layout(for: $0, heldModifiers: optionCommand).fraction)" }
  }

  func testLeftHalfGrowsWithRightAndShrinksWithLeft() {
    XCTAssertEqual(
      fractions([.rightHalf, .rightHalf, .leftHalf, .leftHalf, .leftHalf], startingWith: .leftHalf),
      ["1/2", "2/3", "3/4", "2/3", "1/2", "1/3"])
  }

  func testRightHalfGrowsWithLeftAndShrinksWithRight() {
    XCTAssertEqual(
      fractions([.leftHalf, .rightHalf, .rightHalf, .rightHalf], startingWith: .rightHalf),
      ["1/2", "2/3", "1/2", "1/3", "1/4"])
  }

  func testTopAndBottomHalvesUseUpAndDown() {
    XCTAssertEqual(fractions([.bottomHalf, .topHalf, .topHalf], startingWith: .topHalf), ["1/2", "2/3", "1/2", "1/3"])
    XCTAssertEqual(fractions([.topHalf, .bottomHalf, .bottomHalf], startingWith: .bottomHalf), ["1/2", "2/3", "1/2", "1/3"])
  }

  func testCornersGrowAndShrinkTheirWidthWithTheOtherCornerOnTheSameRow() {
    XCTAssertEqual(fractions([.upperRight, .upperLeft, .upperLeft], startingWith: .upperLeft), ["1/2", "2/3", "1/2", "1/3"])
    XCTAssertEqual(fractions([.lowerLeft, .lowerRight], startingWith: .lowerRight), ["1/2", "2/3", "1/2"])
  }

  func testSizesStopAtEitherEndWithoutWrapping() {
    XCTAssertEqual(
      fractions([.rightHalf, .rightHalf, .rightHalf, .rightHalf], startingWith: .leftHalf),
      ["1/2", "2/3", "3/4", "3/4", "3/4"])
    XCTAssertEqual(
      fractions([.leftHalf, .leftHalf, .leftHalf, .leftHalf], startingWith: .leftHalf),
      ["1/2", "1/3", "1/4", "1/4", "1/4"])
  }

  func testTheSessionKeepsItsAnchorWhenGrowing() {
    var tracker = ResizeSessionTracker()
    _ = tracker.layout(for: .leftHalf, heldModifiers: optionCommand)
    let grown = tracker.layout(for: .rightHalf, heldModifiers: optionCommand)
    XCTAssertEqual(grown.action, .leftHalf, "growing a left half lays out a wider left half, not a right half")
    let frame = WindowLayout.frame(for: grown.action, window: screen, sourceScreen: screen, destinationScreen: screen, fraction: grown.fraction)
    XCTAssertEqual(frame, Rect(x: 0, y: 4, width: 960, height: 873))
  }

  func testReleasingAModifierEndsTheSessionAndTheNextPressStartsAtOneHalf() {
    var tracker = ResizeSessionTracker()
    _ = tracker.layout(for: .leftHalf, heldModifiers: optionCommand)
    _ = tracker.layout(for: .rightHalf, heldModifiers: optionCommand)
    tracker.modifiersChanged(command)  // let go of option
    XCTAssertNil(tracker.session)
    let next = tracker.layout(for: .rightHalf, heldModifiers: optionCommand)
    XCTAssertEqual(next, ResizeSessionTracker.Layout(action: .rightHalf, fraction: .oneHalf))
    XCTAssertEqual(tracker.session?.action, .rightHalf)
  }

  func testAPressWithFewerModifiersThanTheSessionStartsANewSession() {
    var tracker = ResizeSessionTracker()
    _ = tracker.layout(for: .upperLeft, heldModifiers: control | command)
    let next = tracker.layout(for: .upperRight, heldModifiers: command)
    XCTAssertEqual(next, ResizeSessionTracker.Layout(action: .upperRight, fraction: .oneHalf))
  }

  func testExtraModifiersDoNotEndTheSession() {
    var tracker = ResizeSessionTracker()
    _ = tracker.layout(for: .leftHalf, heldModifiers: optionCommand)
    tracker.modifiersChanged(optionCommand | control)
    XCTAssertEqual(tracker.layout(for: .rightHalf, heldModifiers: optionCommand | control).fraction, Fraction(numerator: 2, denominator: 3))
  }

  func testAnActionOutsideTheSessionStartsOverWithThatAction() {
    var tracker = ResizeSessionTracker()
    _ = tracker.layout(for: .leftHalf, heldModifiers: optionCommand)
    _ = tracker.layout(for: .rightHalf, heldModifiers: optionCommand)
    // Up arrow during a left-half session: a fresh top half.
    XCTAssertEqual(tracker.layout(for: .topHalf, heldModifiers: optionCommand), ResizeSessionTracker.Layout(action: .topHalf, fraction: .oneHalf))
    XCTAssertEqual(tracker.session?.action, .topHalf)
    // Fullscreen ends the session altogether.
    XCTAssertEqual(tracker.layout(for: .fullscreen, heldModifiers: optionCommand).action, .fullscreen)
    XCTAssertNil(tracker.session)
  }

  func testAPressWithNoModifiersHeldDoesNotStartASession() {
    var tracker = ResizeSessionTracker()
    XCTAssertEqual(tracker.layout(for: .leftHalf, heldModifiers: 0).fraction, .oneHalf)
    XCTAssertNil(tracker.session)
    XCTAssertEqual(tracker.layout(for: .leftHalf, heldModifiers: 0).fraction, .oneHalf)
  }

  func testOnlyHalvesAndCornersStartSessions() {
    for action in WindowAction.allCases {
      let expected: Set<WindowAction> = [.leftHalf, .rightHalf, .topHalf, .bottomHalf, .upperLeft, .upperRight, .lowerLeft, .lowerRight]
      XCTAssertEqual(ResizeSession(action: action) != nil, expected.contains(action), "\(action)")
    }
  }
}

final class ResizeSizePreferenceTests: XCTestCase {
  let quarter = Fraction(numerator: 1, denominator: 4)
  let third = Fraction(numerator: 1, denominator: 3)
  let twoThirds = Fraction(numerator: 2, denominator: 3)
  let threeQuarters = Fraction(numerator: 3, denominator: 4)

  func testNothingStoredMeansEverySize() {
    XCTAssertEqual(ResizeSizePreference.sizes(fromStored: nil), ResizeSession.sizes)
  }

  func testStoredSizesAlwaysKeepAHalfAndIgnoreJunk() {
    XCTAssertEqual(
      ResizeSizePreference.sizes(fromStored: ["3/4", "bogus", "1/3"]), [third, .oneHalf, threeQuarters])
    XCTAssertEqual(ResizeSizePreference.sizes(fromStored: []), [.oneHalf])
  }

  func testStoredValueRoundTrips() {
    let stored = ResizeSizePreference.storedValue(for: [threeQuarters, quarter])
    XCTAssertEqual(stored, ["1/4", "1/2", "3/4"])
    XCTAssertEqual(ResizeSizePreference.sizes(fromStored: stored), [quarter, .oneHalf, threeQuarters])
  }

  func testSessionStepsOnlyThroughChosenSizes() {
    var tracker = ResizeSessionTracker()
    tracker.sizes = [.oneHalf, twoThirds]
    let held: UInt64 = 1 << 20
    XCTAssertEqual(tracker.layout(for: .leftHalf, heldModifiers: held).fraction, .oneHalf)
    // Shrinking stops at 1/2, the smallest chosen size.
    XCTAssertEqual(tracker.layout(for: .leftHalf, heldModifiers: held).fraction, .oneHalf)
    XCTAssertEqual(tracker.layout(for: .rightHalf, heldModifiers: held).fraction, twoThirds)
    XCTAssertEqual(tracker.layout(for: .rightHalf, heldModifiers: held).fraction, twoThirds)
  }

  func testFeedbackUsesChosenSizes() {
    let feedback = SnapFeedback.make(
      action: .leftHalf, fraction: .oneHalf, sessionActive: true,
      window: Rect(x: 0, y: 0, width: 500, height: 800), screen: Rect(x: 0, y: 0, width: 1000, height: 800),
      sizes: [.oneHalf, twoThirds])
    XCTAssertEqual(feedback.steps, ["½", "⅔"])
    XCTAssertEqual(feedback.currentStep, 0)
    XCTAssertEqual(feedback.hint, "Opposite for ⅔")
  }
}
