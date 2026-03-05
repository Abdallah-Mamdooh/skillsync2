// src/modules/assessment/scoring/constants.js

const FINAL_WEIGHTS = {
  technical: 0.55,
  personality: 0.25,
  soft: 0.20,
};

const LIKERT_SCORE = { A: 5, B: 4, C: 3, D: 2, E: 1 };

// Soft behavior (S69–S74): A best
const SOFT_BEHAVIOR_POINTS_DEFAULT = { A: 4, B: 2, C: 1, D: 0 };

// Conflict SJT (S75): B best
const SOFT_SJT_POINTS_BY_QUESTION = {
  S75: { A: 1, B: 4, C: 0, D: 0 },
};

const SOFT_BEHAVIOR_POINTS_BY_QUESTION = {
  // S69–S74 (A best)
  S69: SOFT_BEHAVIOR_POINTS_DEFAULT,
  S70: SOFT_BEHAVIOR_POINTS_DEFAULT,
  S71: SOFT_BEHAVIOR_POINTS_DEFAULT,
  S72: SOFT_BEHAVIOR_POINTS_DEFAULT,
  S73: SOFT_BEHAVIOR_POINTS_DEFAULT,
  S74: SOFT_BEHAVIOR_POINTS_DEFAULT,
};

module.exports = {
  FINAL_WEIGHTS,
  LIKERT_SCORE,
  SOFT_BEHAVIOR_POINTS_BY_QUESTION,
  SOFT_SJT_POINTS_BY_QUESTION,
};