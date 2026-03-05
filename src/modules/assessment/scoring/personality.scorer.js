// src/modules/assessment/scoring/personality.scorer.js
const { getCareerProfileByName } = require('./careerProfiles');

// Likert mapping: A=5..E=1
const LIKERT_SCORE = { A: 5, B: 4, C: 3, D: 2, E: 1 };

function safeNum(n, fallback = 0) {
  const x = Number(n);
  return Number.isFinite(x) ? x : fallback;
}

/**
 * Convert a Likert answer into "points toward agreePole".
 * agreePole is the pole that "Agree" indicates (e.g. E for EI).
 *
 * If agreePole is 'E':
 *  A(5) means strongly E, E(1) means strongly I
 * If agreePole is 'I':
 *  A(5) means strongly I, E(1) means strongly E
 */
function addPolePoints({ dimension, agreePole, selectedKey, totals }) {
  if (!dimension || !agreePole) return;
  const raw = LIKERT_SCORE[String(selectedKey || '').toUpperCase()];
  if (!raw) return;

  const dim = String(dimension).toUpperCase();
  const poleAgree = String(agreePole).toUpperCase();

  // Map dimension -> its poles
  const DIM_POLES = {
    EI: ['E', 'I'],
    SN: ['S', 'N'],
    TF: ['T', 'F'],
    JP: ['J', 'P'],
  };

  const poles = DIM_POLES[dim];
  if (!poles) return;

  const [poleA, poleB] = poles;
  const otherPole = poleAgree === poleA ? poleB : poleA;

  // raw 5 => strong agreePole, raw 1 => strong otherPole
  totals[poleAgree] = safeNum(totals[poleAgree]) + raw;
  totals[otherPole] = safeNum(totals[otherPole]) + (6 - raw);
}

function ratio(a, b) {
  const sum = safeNum(a) + safeNum(b);
  if (sum <= 0) return { a: 0.5, b: 0.5 };
  return { a: safeNum(a) / sum, b: safeNum(b) / sum };
}

/**
 * Personality fit:
 * For each MBTI dimension, compare user's stronger pole with career's preferred pole.
 * Score per dimension: 0..100, then average 4 dims.
 *
 * If user ratio for preferred pole is high => better fit.
 */
function computeCareerFit(dimensionRatios, careerPreferred) {
  const dims = [
    { dim: 'EI', a: 'E', b: 'I' },
    { dim: 'SN', a: 'S', b: 'N' },
    { dim: 'TF', a: 'T', b: 'F' },
    { dim: 'JP', a: 'J', b: 'P' },
  ];

  let sum = 0;
  let count = 0;

  for (const d of dims) {
    const pref = careerPreferred?.[d.dim];
    if (!pref) continue;

    const rA = safeNum(dimensionRatios?.[d.a]);
    const rB = safeNum(dimensionRatios?.[d.b]);

    const prefRatio = pref === d.a ? rA : rB;

    // Convert ratio (0.0..1.0) into 0..100
    const dimScore = Math.round(prefRatio * 100);
    sum += dimScore;
    count += 1;
  }

  if (!count) return 50;
  return Math.round(sum / count);
}

/**
 * scorePersonality
 * Input: answersWithQuestions (ALL sections), careers
 * Output:
 *  - mbtiType
 *  - dimensionRatios (E/I etc)
 *  - confidence (how strong the preferences are)
 *  - careerPersonalityFit {careerId: 0..100}
 */
function scorePersonality({ answersWithQuestions, careers }) {
  const personalityItems = (answersWithQuestions || []).filter(
    (x) => x?.question?.category === 'personality'
  );

  // totals by pole
  const totals = { E: 0, I: 0, S: 0, N: 0, T: 0, F: 0, J: 0, P: 0 };

  for (const item of personalityItems) {
    const q = item.question;
    const option = q.options?.[item.selectedOptionIndex];
    const selectedKey = option?.key; // 'A'..'E'

    const dimension = q.meta?.personality?.dimension;
    const agreePole = q.meta?.personality?.agreePole;

    addPolePoints({ dimension, agreePole, selectedKey, totals });
  }

  // ratios
  const EI = ratio(totals.E, totals.I);
  const SN = ratio(totals.S, totals.N);
  const TF = ratio(totals.T, totals.F);
  const JP = ratio(totals.J, totals.P);

  const dimensionRatios = {
    E: EI.a, I: EI.b,
    S: SN.a, N: SN.b,
    T: TF.a, F: TF.b,
    J: JP.a, P: JP.b,
  };

  // mbti letters = higher ratio wins
  const mbtiType =
    (dimensionRatios.E >= dimensionRatios.I ? 'E' : 'I') +
    (dimensionRatios.S >= dimensionRatios.N ? 'S' : 'N') +
    (dimensionRatios.T >= dimensionRatios.F ? 'T' : 'F') +
    (dimensionRatios.J >= dimensionRatios.P ? 'J' : 'P');

  // confidence: average distance from 0.5 in each dimension
  const confDims = [
    Math.abs(dimensionRatios.E - 0.5) * 2,
    Math.abs(dimensionRatios.S - 0.5) * 2,
    Math.abs(dimensionRatios.T - 0.5) * 2,
    Math.abs(dimensionRatios.J - 0.5) * 2,
  ];
  const confidence = Number((confDims.reduce((a, b) => a + b, 0) / confDims.length).toFixed(2));

  // career fit
  const careerPersonalityFit = {};
  for (const career of careers || []) {
    const profile = getCareerProfileByName(career.name);
    const preferred = profile?.personality || null;
    careerPersonalityFit[String(career._id)] = computeCareerFit(dimensionRatios, preferred);
  }

  return {
    mbtiType,
    dimensionRatios,
    confidence,
    careerPersonalityFit,
    diagnostics: {
      answered: personalityItems.length,
      totals,
    },
  };
}

module.exports = { scorePersonality };