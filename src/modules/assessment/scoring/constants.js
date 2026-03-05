// src/modules/assessment/scoring/constants.js

// Final mix weights (adjust later easily)
const FINAL_WEIGHTS = {
  technical: 0.55,
  personality: 0.25,
  soft: 0.20,
};

// Likert mapping A..E
const LIKERT_SCORE = { A: 5, B: 4, C: 3, D: 2, E: 1 };

// Reverse score helper (1<->5, 2<->4, 3 stays 3)
function reverseLikertValue(v) {
  return 6 - v;
}

// Soft behavior scoring maps (A best -> D worst)
const SOFT_BEHAVIOR_POINTS = {
  communication: { A: 5, B: 3, C: 2, D: 1 },
  teamwork: { A: 5, B: 3, C: 2, D: 1 },
  adaptability: { A: 5, B: 2, C: 3, D: 1 },
  problemSolving: { A: 5, B: 3, C: 2, D: 1 },
  leadership: { A: 5, B: 2, C: 1, D: 2 },
  timeManagement: { A: 5, B: 2, C: 1, D: 2 },
  conflictManagement: { A: 2, B: 5, C: 1, D: 2 },
};

// Reliability clamp for softskills (we don’t want 0 or 1 extremes in MVP)
const RELIABILITY_MIN = 0.55;
const RELIABILITY_MAX = 0.95;

module.exports = {
  FINAL_WEIGHTS,
  LIKERT_SCORE,
  reverseLikertValue,
  SOFT_BEHAVIOR_POINTS,
  RELIABILITY_MIN,
  RELIABILITY_MAX,
};