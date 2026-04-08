const { LIKERT_SCORE } = require('./constants');
const { safeNumber, safeDivide, clamp } = require('./helpers');
const { getCareerProfileByName } = require('./careerProfiles');

const DIMENSION_POLES = {
  EI: ['E', 'I'],
  SN: ['S', 'N'],
  TF: ['T', 'F'],
  JP: ['J', 'P'],
};

function getOppositePole(dimension, pole) {
  const poles = DIMENSION_POLES[dimension];
  if (!poles) return null;
  return poles[0] === pole ? poles[1] : poles[0];
}

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

    const score = LIKERT_SCORE[key]; // A=5 .. E=1
    const dimension = q.meta?.personality?.dimension;

    // support both old and new naming so nothing breaks
    const targetPole =
      q.meta?.personality?.targetPole || q.meta?.personality?.agreePole;

    if (!dimension || !DIMENSION_POLES[dimension] || !targetPole) continue;
    if (!DIMENSION_POLES[dimension].includes(targetPole)) continue;

    const oppositePole = getOppositePole(dimension, targetPole);
    if (!oppositePole) continue;

    // target pole gets direct score, opposite pole gets reversed score
    dimTotals[dimension][targetPole] += score;
    dimTotals[dimension][oppositePole] += 6 - score;

    answeredCount += 1;
  }

  function pickLetter(dimension, firstPole, secondPole) {
    return dimTotals[dimension][firstPole] >= dimTotals[dimension][secondPole]
      ? firstPole
      : secondPole;
  }

  const mbtiType =
    pickLetter('EI', 'E', 'I') +
    pickLetter('SN', 'S', 'N') +
    pickLetter('TF', 'T', 'F') +
    pickLetter('JP', 'J', 'P');

  const dimensionRatios = {};
  let confidenceSum = 0;
  let countedDimensions = 0;

  for (const dimension of Object.keys(dimTotals)) {
    const poles = dimTotals[dimension];
    const [firstPole, secondPole] = DIMENSION_POLES[dimension];

    const total = safeNumber(poles[firstPole]) + safeNumber(poles[secondPole]);
    if (total <= 0) continue;

    const firstRatio = safeDivide(poles[firstPole], total);
    const secondRatio = safeDivide(poles[secondPole], total);

    dimensionRatios[firstPole] = firstRatio;
    dimensionRatios[secondPole] = secondRatio;

    const diff = Math.abs(firstRatio - secondRatio); // 0..1
    confidenceSum += diff;
    countedDimensions += 1;
  }

  const confidence = countedDimensions
    ? clamp(confidenceSum / countedDimensions, 0, 1)
    : 0;

  const careerPersonalityFit = {};

  for (const career of careers) {
    const profile = getCareerProfileByName(career.name);

    if (!profile?.personality) {
      careerPersonalityFit[String(career._id)] = 50;
      continue;
    }

    const preferred = profile.personality; // { EI:'I', SN:'N', ... }

    let sum = 0;
    let count = 0;

    for (const dimension of Object.keys(DIMENSION_POLES)) {
      const preferredPole = preferred[dimension];
      if (!preferredPole) continue;

      const poleRatio = safeNumber(dimensionRatios[preferredPole], 0.5);
      sum += poleRatio * 100;
      count += 1;
    }

    careerPersonalityFit[String(career._id)] = count ? sum / count : 50;
  }

  return {
    mbtiType,
    dimensionRatios,
    confidence,
    answeredCount,
    careerPersonalityFit,
  };
}

module.exports = { scorePersonality };