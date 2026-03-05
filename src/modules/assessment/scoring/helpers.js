// src/modules/assessment/scoring/helpers.js

function clamp(n, min, max) {
  return Math.max(min, Math.min(max, n));
}

function safeNumber(x, fallback = 0) {
  const n = Number(x);
  return Number.isFinite(n) ? n : fallback;
}

function safeDivide(a, b) {
  const A = safeNumber(a, 0);
  const B = safeNumber(b, 0);
  return B === 0 ? 0 : A / B;
}

function normalizeTo100(value, max) {
  return clamp(Math.round(safeDivide(value, max) * 100), 0, 100);
}

function reverseLikertScore(rawLikertScore) {
  // 1..5 -> 5..1
  return 6 - rawLikertScore;
}

function toId(x) {
  return String(x || '');
}

module.exports = {
  clamp,
  safeNumber,
  safeDivide,
  normalizeTo100,
  reverseLikertScore,
  toId,
};