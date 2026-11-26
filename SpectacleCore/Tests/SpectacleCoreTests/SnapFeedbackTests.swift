import XCTest

@testable import SpectacleCore

final class SnapFeedbackTests: XCTestCase {
  let screen = Rect(x: 0, y: 0, width: 1000, height: 800)

  func testHalfAtStartOfSessionOffersBothDirections() {
    let window = Rect(x: 0, y: 0, width: 500, height: 800)
    let feedback = SnapFeedback.make(
      action: .leftHalf, fraction: .oneHalf, sessionActive: true, window: window, screen: screen)
    XCTAssertEqual(feedback.title, "Left Half")
    XCTAssertEqual(feedback.sizeLabel, "½")
    XCTAssertEqual(feedback.steps, ["¼", "⅓", "½", "⅔", "¾"])
    XCTAssertEqual(feedback.currentStep, 2)
    XCTAssertEqual(feedback.hint, "Again for ⅓ · Opposite for ⅔")
    XCTAssertEqual(feedback.region, Rect(x: 0, y: 0, width: 0.5, height: 1))
  }

  func testEndsOfSessionOfferOnlyOneDirection() {
    let window = Rect(x: 0, y: 0, width: 250, height: 800)
    let smallest = SnapFeedback.make(
      action: .leftHalf, fraction: ResizeSession.sizes[0], sessionActive: true,
      window: window, screen: screen)
    XCTAssertEqual(smallest.hint, "Opposite for ⅓")
    let largest = SnapFeedback.make(
      action: .leftHalf, fraction: ResizeSession.sizes[4], sessionActive: true,
      window: window, screen: screen)
    XCTAssertEqual(largest.hint, "Again for ⅔")
  }

  func testNoHintWithoutSession() {
    let feedback = SnapFeedback.make(
      action: .upperRight, fraction: .oneHalf, sessionActive: false,
      window: Rect(x: 500, y: 400, width: 500, height: 400), screen: screen)
    XCTAssertEqual(feedback.title, "Top Right")
    XCTAssertNil(feedback.hint)
    // Top right in a bottom-left-origin space is the top right in the flipped region too.
    XCTAssertEqual(feedback.region, Rect(x: 0.5, y: 0, width: 0.5, height: 0.5))
  }

  func testNonResizingActionsShowOnlyTheirName() {
    let feedback = SnapFeedback.make(
      action: .center, fraction: .oneHalf, sessionActive: true,
      window: Rect(x: 250, y: 200, width: 500, height: 400), screen: screen)
    XCTAssertEqual(feedback.title, "Center")
    XCTAssertNil(feedback.sizeLabel)
    XCTAssertTrue(feedback.steps.isEmpty)
    XCTAssertNil(feedback.currentStep)
    XCTAssertNil(feedback.hint)
  }

  func testRegionIsRelativeToOffsetScreensAndClamped() {
    let offsetScreen = Rect(x: 1000, y: 100, width: 1000, height: 800)
    let bottomHalf = Rect(x: 1000, y: 100, width: 1000, height: 400)
    XCTAssertEqual(
      SnapFeedback.region(of: bottomHalf, in: offsetScreen), Rect(x: 0, y: 0.5, width: 1, height: 0.5))
    let spilling = Rect(x: 900, y: 0, width: 2000, height: 2000)
    XCTAssertEqual(
      SnapFeedback.region(of: spilling, in: offsetScreen), Rect(x: 0, y: 0, width: 1, height: 1))
  }

  func testEveryActionHasATitle() {
    XCTAssertEqual(Set(WindowAction.allCases.map(\.title)).count, WindowAction.allCases.count)
  }

  func testFractionGlyphs() {
    XCTAssertEqual(Fraction(numerator: 3, denominator: 4).glyph, "¾")
    XCTAssertEqual(Fraction(numerator: 3, denominator: 7).glyph, "3/7")
  }

  func testAppearancePreferenceDefaultsToSystem() {
    XCTAssertEqual(AppearancePreference(storedValue: nil), .system)
    XCTAssertEqual(AppearancePreference(storedValue: "bogus"), .system)
    XCTAssertEqual(AppearancePreference(storedValue: "dark"), .dark)
    XCTAssertEqual(AppearancePreference(storedValue: "light"), .light)
  }
}
