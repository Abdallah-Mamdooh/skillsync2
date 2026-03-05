// src/modules/assessment/scoring/helpers.js

function safeDivide(a, b) {
  const A = Number(a);
  const B = Number(b);
  if (!Number.isFinite(A) || !Number.isFinite(B) || B === 0) return 0;
  return A / B;
}

function clamp(n, min, max) {
  const x = Number(n);
  if (!Number.isFinite(x)) return min;
  return Math.max(min, Math.min(max, x));
}

function normalizeTo100(value, max) {
  const v = Number(value);
  const m = Number(max);
  if (!Number.isFinite(v) || !Number.isFinite(m) || m <= 0) return 0;
  return clamp((v / m) * 100, 0, 100);
}

function safeNum(v, fallback = 0) {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

function pickTopN(mapObj, n = 3) {
  return Object.entries(mapObj || {})
    .map(([key, val]) => ({ key, val }))
    .sort((a, b) => b.val - a.val)
    .slice(0, n);
}

module.exports = {
  safeDivide,
  clamp,
  normalizeTo100,
  safeNum,
  pickTopN,
};