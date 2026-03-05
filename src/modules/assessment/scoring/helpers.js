function safeDivide(a, b) {
  if (!b || b === 0) return 0;
  return a / b;
}

function clamp(n, min, max) {
  return Math.max(min, Math.min(max, n));
}

function normalizeTo100(value, max) {
  if (!max || max <= 0) return 0;
  return clamp((value / max) * 100, 0, 100);
}

function pickTopN(mapObj, n = 3) {
  return Object.entries(mapObj)
    .map(([key, val]) => ({ key, val }))
    .sort((a, b) => b.val - a.val)
    .slice(0, n);
}

module.exports = {
  safeDivide,
  clamp,
  normalizeTo100,
  pickTopN,
};