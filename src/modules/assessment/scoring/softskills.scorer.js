// src/modules/assessment/scoring/softskills.scorer.js

const {
  LIKERT_SCORE,
  reverseLikertValue,
  SOFT_BEHAVIOR_POINTS,
  RELIABILITY_MIN,
  RELIABILITY_MAX,
} = require('./constants');

const { clamp, safeNum } = require('./helpers');
const { getCareerProfileByName } = require('./careerProfiles');

function scoreSoftSkills({ answersWithQuestions, careers }) {
  const items = (answersWithQuestions || []).filter(
    (x) => x?.question?.category === 'soft'
  );

  // category buckets (you use these in careerProfiles softWeights)
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

  // reliability from reverse-coded items (only if present)
  let reliabilityChecks = 0;
  let reliabilityBad = 0;

  for (const item of items) {
    const q = item.question;
    const opt = q?.options?.[item.selectedOptionIndex];
    if (!q || !opt) continue;

    const code = String(q.questionCode || '');
    const softType = q?.meta?.soft?.softType; // likert | behavior | sjt
    const category = String(q?.meta?.soft?.softCategory || '').trim();
    const isReverse = q?.meta?.soft?.isReverse === true;

    if (!catSum.hasOwnProperty(category)) continue;

    if (softType === 'likert') {
      const key = String(opt.key || '').toUpperCase();
      let raw = LIKERT_SCORE[key];
      if (!raw) continue;

      if (isReverse) raw = reverseLikertValue(raw);

      catSum[category] += raw;
      catMax[category] += 5;

      // Only count reliability checks on the “Self-report” band if you used S61..S68
      if (/^S6[1-8]$/.test(code) && isReverse) {
        reliabilityChecks += 1;
        // after reversing, low score means inconsistency
        if (raw <= 2) reliabilityBad += 1;
      }
    } else {
      // behavior/sjt: keys A..D
      const key = String(opt.key || '').toUpperCase();
      const map = SOFT_BEHAVIOR_POINTS[category];
      if (!map) continue;

      const pts = map[key];
      if (!pts) continue;

      catSum[category] += pts;
      catMax[category] += 5; // keep consistent scale (pts 1..5)
    }
  }

  // category scores 0..100
  const categoryScores = {};
  for (const k of Object.keys(catSum)) {
    const max = catMax[k] || 0;
    categoryScores[k] = max ? Math.round((catSum[k] / max) * 100) : 0;
  }

  const inconsistencyRate = reliabilityChecks ? reliabilityBad / reliabilityChecks : 0;
  const reliability = clamp(1 - inconsistencyRate, RELIABILITY_MIN, RELIABILITY_MAX);

  // career fit using careerProfiles softWeights
  const careerSoftFit = {};
  for (const career of careers || []) {
    const profile = getCareerProfileByName(career.name);
    const weights = profile?.softWeights;

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
      reliabilityBad,
      inconsistencyRate: Number(inconsistencyRate.toFixed(2)),
    },
  };
}

module.exports = { scoreSoftSkills };