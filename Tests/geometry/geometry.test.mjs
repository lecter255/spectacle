// Runs every window position case from the XCTest calculation specs against the bundled
// JavaScript, plus a few invariants, using Node's built-in test runner:
//
//   node --test Tests/geometry/
//
// The cases are read straight from SpectacleSpecs/Sources/*CalculationSpec.m so the two suites
// can't drift apart: add a case to the XCTest spec and it runs here too.
import assert from 'node:assert/strict';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { test } from 'node:test';

import { loadCalculations, rect, repoRoot } from './harness.mjs';

const specsDir = join(repoRoot, 'SpectacleSpecs', 'Sources');
const num = String.raw`(-?[\d.]+)f?`;
const cgRect = String.raw`CGRectMake\(\s*${num},\s*${num},\s*${num},\s*${num}\s*\)`;
const toRect = (m, i) => rect(...m.slice(i, i + 4).map(Number));

function parseSpec(source) {
  const frame = (name) => {
    const m = source.match(new RegExp(String.raw`${name}\s*=\s*${cgRect}`));
    return m && toRect(m, 1);
  };
  const source_ = frame('visibleFrameSourceScreen');
  const destination = frame('visibleFrameDestinationScreen');
  const cases = [];
  const testPattern = /-\s*\(void\)\s*(test\w+)\s*\{([\s\S]*?)\n\}/g;
  const stepPattern = new RegExp(
    String.raw`calculateWindowRect:\s*${cgRect}[\s\S]*?action:\s*(kSpectacleWindowAction\w+)\s*\];\s*` +
      String.raw`SpectacleAssertEqualRects\(\s*result\.windowRect,\s*${cgRect}\s*\)`,
    'g',
  );
  for (const [, name, body] of source.matchAll(testPattern)) {
    const steps = [...body.matchAll(stepPattern)].map((m) => ({
      input: toRect(m, 1),
      action: m[5].replace(/^k/, ''),
      expected: toRect(m, 6),
    }));
    const calls = (body.match(/calculateWindowRect:/g) || []).length;
    cases.push({ name, steps, calls });
  }
  return { source: source_, destination, cases };
}

const { calculate, errors, actions } = loadCalculations();

test('all bundled scripts evaluate without errors', () => {
  assert.deepEqual(errors, []);
});

const specFiles = readdirSync(specsDir).filter((name) => name.endsWith('CalculationSpec.m')).sort();

test('calculation specs were found', () => {
  assert.ok(specFiles.length >= 16, `expected at least 16 calculation specs, found ${specFiles.length}`);
});

for (const file of specFiles) {
  const spec = parseSpec(readFileSync(join(specsDir, file), 'utf8'));
  for (const { name, steps, calls } of spec.cases) {
    test(`${file.replace('Spec.m', '')} ${name}`, () => {
      // Guard against the parser silently skipping a step written in a new style.
      assert.equal(steps.length, calls, 'every calculateWindowRect: call should have a parsed assertion');
      for (const { input, action, expected } of steps) {
        assert.deepEqual(calculate(input, spec.source, spec.destination, action), expected, `${action} from ${JSON.stringify(input)}`);
      }
    });
  }
}

// Invariants over a grid of screens and starting windows.
const screens = [
  rect(0, 4, 1440, 873), // 13" MacBook Air with menu bar and Dock
  rect(0, 25, 1512, 919), // 14" MacBook Pro
  rect(-1920, 0, 1920, 1055), // external display to the left
  rect(1440, -300, 2560, 1415), // external display to the right, offset vertically
  rect(0, 0, 1081, 1897), // portrait display with an odd width
];
const tilingActions = [
  'SpectacleWindowActionLeftHalf',
  'SpectacleWindowActionRightHalf',
  'SpectacleWindowActionTopHalf',
  'SpectacleWindowActionBottomHalf',
  'SpectacleWindowActionUpperLeft',
  'SpectacleWindowActionUpperRight',
  'SpectacleWindowActionLowerLeft',
  'SpectacleWindowActionLowerRight',
  'SpectacleWindowActionNextThird',
  'SpectacleWindowActionPreviousThird',
  'SpectacleWindowActionFullscreen',
  'SpectacleWindowActionCenter',
];
const contains = (outer, inner) =>
  inner.x >= outer.x && inner.y >= outer.y &&
  inner.x + inner.width <= outer.x + outer.width &&
  inner.y + inner.height <= outer.y + outer.height;

test('every tiling action is registered', () => {
  for (const action of tilingActions) {
    assert.ok(actions.includes(action), `${action} is not registered`);
  }
});

test('tiling actions keep windows on screen, with whole-pixel frames, even when repeated', () => {
  for (const screen of screens) {
    const start = rect(screen.x + 100, screen.y + 100, Math.floor(screen.width / 2.5), Math.floor(screen.height / 2.5));
    for (const action of tilingActions) {
      let window = start;
      // Repeating an action cycles through sizes (1/2 -> 2/3 -> 1/3); check the whole cycle.
      for (let i = 0; i < 4; i++) {
        window = calculate(window, screen, screen, action);
        assert.ok(contains(screen, window), `${action} #${i + 1} on ${JSON.stringify(screen)} produced ${JSON.stringify(window)}`);
        for (const key of ['x', 'y', 'width', 'height']) {
          assert.ok(Number.isInteger(window[key]), `${action} produced a fractional ${key}: ${window[key]}`);
        }
        assert.ok(window.width > 0 && window.height > 0, `${action} produced an empty window`);
      }
    }
  }
});

test('repeating a half or corner action cycles through distinct sizes and returns to the start', () => {
  // The number of sizes in the cycle (1/2, 2/3, 1/3, ...) is a product decision, so only check
  // that the cycle has at least three distinct sizes and comes back to where it started.
  const screen = screens[0];
  const cycling = tilingActions.slice(0, 8);
  for (const action of cycling) {
    const first = calculate(rect(200, 200, 500, 300), screen, screen, action);
    const seen = [first];
    let window = calculate(first, screen, screen, action);
    while (JSON.stringify(window) !== JSON.stringify(first)) {
      assert.ok(!seen.some((r) => JSON.stringify(r) === JSON.stringify(window)), `${action}: cycle repeats ${JSON.stringify(window)} before returning to the start`);
      assert.ok(seen.length < 12, `${action}: cycle never returns to the start`);
      seen.push(window);
      window = calculate(window, screen, screen, action);
    }
    assert.ok(seen.length >= 3, `${action}: expected at least 3 sizes in the cycle, got ${seen.length}`);
  }
});

test('larger then smaller stays on screen and never grows past it', () => {
  for (const screen of screens) {
    let window = rect(screen.x + 200, screen.y + 150, Math.floor(screen.width / 2), Math.floor(screen.height / 2));
    for (let i = 0; i < 60; i++) {
      window = calculate(window, screen, screen, 'SpectacleWindowActionLarger');
      assert.ok(window.width <= screen.width && window.height <= screen.height, `grew past the screen: ${JSON.stringify(window)}`);
    }
    for (let i = 0; i < 60; i++) {
      window = calculate(window, screen, screen, 'SpectacleWindowActionSmaller');
      assert.ok(window.width > screen.width / 4 && window.height > screen.height / 4, `shrank below a quarter: ${JSON.stringify(window)}`);
    }
  }
});
