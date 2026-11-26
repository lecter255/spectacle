// Loads Spectacle's bundled window position calculations into a sandbox that mimics the
// JavaScriptCore environment set up by SpectacleWindowPositionCalculator.m, so the geometry can be
// tested with Node on any platform, without Xcode.
import { readdirSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const here = dirname(fileURLToPath(import.meta.url));
export const repoRoot = join(here, '..', '..');
export const calculationsDir = join(repoRoot, 'Spectacle', 'Resources', 'Window Position Calculations');

// CoreGraphics helpers exposed to the scripts. Rects use the same {x, y, width, height} shape that
// JSValue's valueWithRect: produces.
const standardize = (r) => ({
  x: r.width < 0 ? r.x + r.width : r.x,
  y: r.height < 0 ? r.y + r.height : r.y,
  width: Math.abs(r.width),
  height: Math.abs(r.height),
});
const isEmpty = (r) => r.width === 0 || r.height === 0;
const cg = {
  CGRectGetMinX: (r) => standardize(r).x,
  CGRectGetMinY: (r) => standardize(r).y,
  CGRectGetMidX: (r) => standardize(r).x + standardize(r).width / 2,
  CGRectGetMidY: (r) => standardize(r).y + standardize(r).height / 2,
  CGRectGetMaxX: (r) => standardize(r).x + standardize(r).width,
  CGRectGetMaxY: (r) => standardize(r).y + standardize(r).height,
  CGRectEqualToRect: (a, b) => {
    const s = standardize(a), t = standardize(b);
    return s.x === t.x && s.y === t.y && s.width === t.width && s.height === t.height;
  },
  CGRectContainsRect: (a, b) => {
    const s = standardize(a), t = standardize(b);
    if (isEmpty(s) || isEmpty(t)) return false;
    return t.x >= s.x && t.y >= s.y && t.x + t.width <= s.x + s.width && t.y + t.height <= s.y + s.height;
  },
};

// CGRect fields are doubles; JSValue's toRect: reads x, y, width and height as numbers.
const toRect = (value) => ({
  x: Number(value.x),
  y: Number(value.y),
  width: Number(value.width),
  height: Number(value.height),
});

export function loadCalculations() {
  const calculations = new Map();
  const errors = [];
  const sandbox = {
    ...cg,
    windowPositionCalculationRegistry: {
      registerWindowPositionCalculationWithAction(calculation, action) {
        calculations.set(action, calculation);
      },
    },
  };
  vm.createContext(sandbox);
  const scripts = readdirSync(calculationsDir).filter((name) => name.endsWith('.js')).sort();
  for (const name of scripts) {
    try {
      vm.runInContext(readFileSync(join(calculationsDir, name), 'utf8'), sandbox, { filename: name });
    } catch (error) {
      errors.push(`${name}: ${error.message}`);
    }
  }
  return {
    errors,
    actions: [...calculations.keys()],
    calculate(windowRect, visibleFrameOfSourceScreen, visibleFrameOfDestinationScreen, action) {
      const calculation = calculations.get(action);
      if (!calculation) {
        throw new Error(`No calculation registered for ${action}`);
      }
      return toRect(calculation({ ...windowRect }, { ...visibleFrameOfSourceScreen }, { ...visibleFrameOfDestinationScreen }));
    },
  };
}

export const rect = (x, y, width, height) => ({ x, y, width, height });
