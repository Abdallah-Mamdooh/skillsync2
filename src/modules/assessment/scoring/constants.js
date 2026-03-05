// Final mix weights (adjust later easily)
const FINAL_WEIGHTS = {
  technical: 0.55,
  personality: 0.25,
  soft: 0.20,
};

// Likert mapping
const LIKERT_SCORE = { A: 5, B: 4, C: 3, D: 2, E: 1 };

function reverseLikertValue(v) {
  return 6 - v; // 1<->5, 2<->4, 3 stays 3
}

// Soft behavior scoring maps (A best -> D worst)
// We'll use these in softskills.scorer.js
const SOFT_BEHAVIOR_POINTS = {
  communication: { A: 5, B: 3, C: 2, D: 1 },
  teamwork: { A: 5, B: 3, C: 2, D: 1 },
  adaptability: { A: 5, B: 2, C: 3, D: 1 }, // waiting isn't as bad as stopping; tweak later
  problemSolving: { A: 5, B: 3, C: 2, D: 1 },
  leadership: { A: 5, B: 2, C: 1, D: 2 }, // takeover isn't great but not worst; tweak later
  timeManagement: { A: 5, B: 2, C: 1, D: 2 },
  conflictManagement: { A: 2, B: 5, C: 1, D: 2 },
};

module.exports = {
  FINAL_WEIGHTS,
  LIKERT_SCORE,
  reverseLikertValue,
  SOFT_BEHAVIOR_POINTS,
};