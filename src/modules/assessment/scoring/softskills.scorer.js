// src/modules/assessment/scoring/softskills.scorer.js
const {
  LIKERT_SCORE,
  SOFT_REVERSE_CODES,
  SOFT_BEHAVIOR_POINTS,
  RELIABILITY_MIN,
  RELIABILITY_MAX,
} = require('./constants');
const { clamp, safeNum } = require('./helpers');
const { getCareerProfileByName } = require('./careerProfiles');

function reverseLikert(raw) {
  // raw is 1..5 -> reversed
  return 6 - raw;
}

function scoreSoftSkills({ answersWithQuestions, careers }) {
  const items = (answersWithQuestions || []).filter((x) => x?.question?.category === 'soft');

  // Category accumulators
  const catSum = {
    communication: 0,
    teamwork: 0,
    adaptability: 0,
    problemSolving: 0,
    leadership: 0,
    timeManagement: 0,
    conflictManagement: 0,
  };
  const catMax = {
    communication: 0,
    teamwork: 0,
    adaptability: 0,
    problemSolving: 0,
    leadership: 0,
    timeManagement: 0,
    conflictManagement: 0,
  };

  // Reliability using reverse vs positive consistency in the Self-Report (S61–S68)
  // Simple: count contradictions (high on positive, high on negative)
  let reliabilityHits = 0;
  let reliabilityChecks = 0;

  for (const item of items) {
    const q = item.question;
    if (!q) continue;

    const code = String(q.questionCode || '');
    const option = q.options?.[item.selectedOptionIndex];
    const key = String(option?.key || '').toUpperCase();

    const softType = q.meta?.soft?.softType; // likert | behavior | sjt
    const cat = q.meta?.soft?.softCategory; // communication, teamwork, ...
    const isReverse = q.meta?.soft?.isReverse === true || SOFT_REVERSE_CODES.has(code);

    if (!catSum[cat]) {
      // if category missing or unknown, skip safely
      continue;
    }

    if (softType === 'likert') {
      let raw = LIKERT_SCORE[key];
      if (!raw) continue;

      if (isReverse) raw = reverseLikert(raw);

      catSum[cat] += raw;
      catMax[cat] += 5;

      // Reliability check only for S61-S68 range
      if (/^S6[1-8]$/.test(code)) {
        reliabilityChecks += 1;

        // "bad" answers are extremes in opposite direction; basic rule:
        // if original was reverse question AND user chose Strongly Agree (A->5), after reversing it's 1 => inconsistency
        // We'll treat low reversed score (<=2) as inconsistency.
        if (raw <= 2) reliabilityHits += 1;
      }
    } else {
      // behavior / sjt: A..D (best..worst)
      const pts = SOFT_BEHAVIOR_POINTS[key];
      if (!pts) continue;

      catSum[cat] += pts;
      catMax[cat] += 4;
    }
  }

  // Category scores 0..100
  const categoryScores = {};
  for (const k of Object.keys(catSum)) {
    const max = catMax[k] || 0;
    categoryScores[k] = max ? Math.round((catSum[k] / max) * 100) : 0;
  }

  // reliability: fewer inconsistencies => higher reliability
  const inconsistencyRate = reliabilityChecks ? reliabilityHits / reliabilityChecks : 0;
  const reliability = clamp(1 - inconsistencyRate, RELIABILITY_MIN, RELIABILITY_MAX);

  // Convert to career-specific soft fit using careerProfiles softWeights
  const careerSoftFit = {};
  for (const career of careers || []) {
    const profile = getCareerProfileByName(career.name);
    const weights = profile?.softWeights || null;

    if (!weights) {
      careerSoftFit[String(career._id)] = Math.round(50 * reliability);
      continue;
    }

    let sum = 0;
    let wsum = 0;

    for (const [cat, w] of Object.entries(weights)) {
      const ww = safeNum(w, 0);
      if (ww <= 0) continue;
      const score = safeNum(categoryScores[cat], 0);
      sum += score * ww;
      wsum += ww;
    }

    const base = wsum ? sum / wsum : 50;
    careerSoftFit[String(career._id)] = Math.round(base * reliability);
  }

  return {
    categoryScores,
    reliability: Number(reliability.toFixed(2)),
    careerSoftFit,
    diagnostics: {
      answered: items.length,
      reliabilityChecks,
      reliabilityHits,
      inconsistencyRate: Number(inconsistencyRate.toFixed(2)),
    },
  };
}

module.exports = { scoreSoftSkills };