import Foundation
import XCTest

@testable import SpectacleCore

/// Replays every case from the app's XCTest calculation specs
/// (`SpectacleSpecs/Sources/*CalculationSpec.m`) against `WindowLayout`, so the Swift port must
/// match the original calculations exactly. Reading the specs, rather than copying their numbers
/// here, keeps the two suites from drifting apart.
final class SpecCaseTests: XCTestCase {
  struct Step {
    var input: Rect
    var action: WindowAction
    var expected: Rect
  }

  struct SpecCase {
    var file: String
    var name: String
    var sourceScreen: Rect
    var destinationScreen: Rect
    var steps: [Step]
    var callCount: Int
  }

  static let repositoryRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()  // SpectacleCoreTests
    .deletingLastPathComponent()  // Tests
    .deletingLastPathComponent()  // SpectacleCore
    .deletingLastPathComponent()  // repository root

  static let number = #"(-?[\d.]+)f?"#
  static let cgRect = #"CGRectMake\(\s*\#(number),\s*\#(number),\s*\#(number),\s*\#(number)\s*\)"#

  static func rect(_ match: NSTextCheckingResult, in source: String, startingAt group: Int) -> Rect {
    let values = (group..<(group + 4)).map { index -> Double in
      let range = Range(match.range(at: index), in: source)!
      return Double(source[range])!
    }
    return Rect(x: values[0], y: values[1], width: values[2], height: values[3])
  }

  static func loadCases() throws -> [SpecCase] {
    let specsDirectory = repositoryRoot.appendingPathComponent("SpectacleSpecs/Sources")
    let files = try FileManager.default.contentsOfDirectory(atPath: specsDirectory.path)
      .filter { $0.hasSuffix("CalculationSpec.m") }
      .sorted()
    let testPattern = try NSRegularExpression(pattern: #"-\s*\(void\)\s*(test\w+)\s*\{([\s\S]*?)\n\}"#)
    let stepPattern = try NSRegularExpression(
      pattern: #"calculateWindowRect:\s*\#(cgRect)[\s\S]*?action:\s*k(SpectacleWindowAction\w+)\s*\];\s*"#
        + #"SpectacleAssertEqualRects\(\s*result\.windowRect,\s*\#(cgRect)\s*\)"#)
    let callPattern = try NSRegularExpression(pattern: "calculateWindowRect:")

    var cases: [SpecCase] = []
    for file in files {
      let source = try String(contentsOf: specsDirectory.appendingPathComponent(file), encoding: .utf8)
      func frame(_ name: String) throws -> Rect {
        let pattern = try NSRegularExpression(pattern: "\(name)\\s*=\\s*\(cgRect)")
        let fullRange = NSRange(source.startIndex..., in: source)
        guard let match = pattern.firstMatch(in: source, range: fullRange) else {
          throw NSError(domain: "SpecCaseTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(file) has no \(name)"])
        }
        return rect(match, in: source, startingAt: 1)
      }
      let sourceScreen = try frame("visibleFrameSourceScreen")
      let destinationScreen = try frame("visibleFrameDestinationScreen")
      for test in testPattern.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
        let name = String(source[Range(test.range(at: 1), in: source)!])
        let bodyRange = test.range(at: 2)
        let steps = stepPattern.matches(in: source, range: bodyRange).map { match -> Step in
          let actionName = String(source[Range(match.range(at: 5), in: source)!])
          guard let action = WindowAction(rawValue: actionName) else {
            fatalError("\(file) \(name) uses unknown action \(actionName)")
          }
          return Step(
            input: rect(match, in: source, startingAt: 1),
            action: action,
            expected: rect(match, in: source, startingAt: 6))
        }
        let callCount = callPattern.numberOfMatches(in: source, range: bodyRange)
        cases.append(SpecCase(
          file: file, name: name, sourceScreen: sourceScreen, destinationScreen: destinationScreen,
          steps: steps, callCount: callCount))
      }
    }
    return cases
  }

  func testEveryCalculationSpecCaseMatches() throws {
    let cases = try Self.loadCases()
    XCTAssertGreaterThanOrEqual(Set(cases.map(\.file)).count, 16, "expected at least 16 calculation specs")
    XCTAssertGreaterThan(cases.count, 50, "expected the specs to contain more test cases")
    var stepCount = 0
    for specCase in cases {
      let label = "\(specCase.file) \(specCase.name)"
      // Guard against the parser silently skipping a step written in a new style.
      XCTAssertEqual(specCase.steps.count, specCase.callCount, "\(label): every calculateWindowRect: call should have a parsed assertion")
      for step in specCase.steps {
        let actual = WindowLayout.frame(
          for: step.action, window: step.input,
          sourceScreen: specCase.sourceScreen, destinationScreen: specCase.destinationScreen)
        XCTAssertEqual(actual, step.expected, "\(label): \(step.action) from \(step.input)")
        stepCount += 1
      }
    }
    XCTAssertGreaterThan(stepCount, 100)
  }
}
