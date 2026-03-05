// src/modules/assessment/scoring/personality.scorer.js

const { LIKERT_SCORE } = require('./constants');
const { safeNumber, safeDivide, clamp } = require('./helpers');
const { getCareerProfileByName } = require('./careerProfiles');

function scorePersonality({ answersWithQuestions, careers }) {
  const dimTotals = {
    EI: { E: 0, I: 0 },
    SN: { S: 0, N: 0 },
    TF: { T: 0, F: 0 },
    JP: { J: 0, P: 0 },
  };

  let answeredCount = 0;

  for (const item of answersWithQuestions) {
    const q = item.question;
    if (!q || q.category !== 'personality') continue;

    const option = q.options?.[item.selectedOptionIndex];
    const key = option?.key; // A..E
    if (!key || !LIKERT_SCORE[key]) continue;

    const score = LIKERT_SCORE[key]; // 1..5
    const dim = q.meta?.personality?.dimension;
    const agreePole = q.meta?.personality?.agreePole; // E/I etc

    if (!dim || !agreePole) continue;

    // AgreePole gets "score", opposite gets reversed (6-score)
    const opposite = dim === 'EI'
      ? (agreePole === 'E' ? 'I' : 'E')
      : dim === 'SN'
      ? (agreePole === 'S' ? 'N' : 'S')
      : dim === 'TF'
      ? (agreePole === 'T' ? 'F' : 'T')
      : (agreePole === 'J' ? 'P' : 'J');

    dimTotals[dim][agreePole] += score;
    dimTotals[dim][opposite] += (6 - score);

    answeredCount++;
  }

  function pickLetter(dim, a, b) {
    return dimTotals[dim][a] >= dimTotals[dim][b] ? a : b;
  }

  const type =
    pickLetter('EI', 'E', 'I') +
    pickLetter('SN', 'S', 'N') +
    pickLetter('TF', 'T', 'F') +
    pickLetter('JP', 'J', 'P');

  const ratios = {};
  let confidenceSum = 0;
  let dimsCounted = 0;

  for (const dim of Object.keys(dimTotals)) {
    const poles = dimTotals[dim];
    const keys = Object.keys(poles);
    const total = poles[keys[0]] + poles[keys[1]];
    if (total <= 0) continue;

    ratios[keys[0]] = safeDivide(poles[keys[0]], total);
    ratios[keys[1]] = safeDivide(poles[keys[1]], total);

    const diff = Math.abs(ratios[keys[0]] - ratios[keys[1]]); // 0..1
    confidenceSum += diff;
    dimsCounted++;
  }

  const confidence = dimsCounted ? clamp(confidenceSum / dimsCounted, 0, 1) : 0;

  // Career personality fit
  const careerPersonalityFit = {};
  for (const career of careers) {
    const profile = getCareerProfileByName(career.name);
    if (!profile?.personality) {
      careerPersonalityFit[String(career._id)] = 50; // neutral
      continue;
    }

    const pref = profile.personality; // {EI:'I', SN:'S'...}
    const dimToPoles = { EI: ['E', 'I'], SN: ['S', 'N'], TF: ['T', 'F'], JP: ['J', 'P'] };

    let sum = 0;
    let count = 0;

    for (const dim of Object.keys(dimToPoles)) {
      const prefer = pref[dim];
      if (!prefer) continue;

      const poleRatio = safeNumber(ratios[prefer], 0.5);
      sum += poleRatio * 100;
      count++;
    }

    careerPersonalityFit[String(career._id)] = count ? (sum / count) : 50;
  }

  return {
    mbtiType: type,
    dimensionRatios: ratios,
    confidence,
    answeredCount,
    careerPersonalityFit,
  };
}

module.exports = { scorePersonality };