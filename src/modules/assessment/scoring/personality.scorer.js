// src/modules/assessment/scoring/personality.scorer.js

const { LIKERT_SCORE } = require('./constants');
const { clamp, safeNum } = require('./helpers');
const { getCareerProfileByName } = require('./careerProfiles');

function scorePersonality({ answersWithQuestions, careers }) {
  const items = (answersWithQuestions || []).filter(
    (x) => x?.question?.category === 'personality'
  );

  // Dimension sums
  const dims = {
    EI: { E: 0, I: 0, max: 0 },
    SN: { S: 0, N: 0, max: 0 },
    TF: { T: 0, F: 0, max: 0 },
    JP: { J: 0, P: 0, max: 0 },
  };

  for (const item of items) {
    const q = item.question;
    const opt = q?.options?.[item.selectedOptionIndex];
    const key = String(opt?.key || '').toUpperCase();
    const raw = LIKERT_SCORE[key];
    if (!raw) continue;

    const dim = q?.meta?.personality?.dimension; // EI, SN, TF, JP
    const agreePole = q?.meta?.personality?.agreePole; // e.g. E or I

    if (!dims[dim] || !agreePole) continue;

    // Agree = raw is high => push toward agreePole
    // Disagree = raw low => push toward opposite pole
    const opposite = dim === 'EI'
      ? (agreePole === 'E' ? 'I' : 'E')
      : dim === 'SN'
        ? (agreePole === 'S' ? 'N' : 'S')
        : dim === 'TF'
          ? (agreePole === 'T' ? 'F' : 'T')
          : (agreePole === 'J' ? 'P' : 'J');

    // raw is 1..5. Convert to signed “lean” around 3.
    // 5->+2, 4->+1, 3->0, 2->-1, 1->-2
    const lean = raw - 3;

    if (lean > 0) dims[dim][agreePole] += lean;
    if (lean < 0) dims[dim][opposite] += Math.abs(lean);

    dims[dim].max += 2; // max lean magnitude per question
  }

  // Ratios + MBTI
  const dimensionRatios = {};
  const letters = [];

  for (const dimKey of Object.keys(dims)) {
    const d = dims[dimKey];
    const poles = Object.keys(d).filter((k) => k !== 'max');

    const p1 = poles[0];
    const p2 = poles[1];

    const total = safeNum(d[p1], 0) + safeNum(d[p2], 0);
    const r1 = total ? d[p1] / total : 0.5;
    const r2 = total ? d[p2] / total : 0.5;

    dimensionRatios[p1] = Number(r1.toFixed(2));
    dimensionRatios[p2] = Number(r2.toFixed(2));

    letters.push(d[p1] >= d[p2] ? p1 : p2);
  }

  const mbtiType = letters.join('');

  // Confidence: average distance from 50/50 (0..1)
  const confParts = [];
  for (const [a, b] of [['E','I'], ['S','N'], ['T','F'], ['J','P']]) {
    const ra = safeNum(dimensionRatios[a], 0.5);
    const rb = safeNum(dimensionRatios[b], 0.5);
    confParts.push(Math.abs(ra - rb)); // 0..1
  }
  const confidence = clamp(confParts.reduce((s, x) => s + x, 0) / confParts.length, 0, 1);

  // Career fit using profile preferred poles
  const careerPersonalityFit = {};
  for (const career of careers || []) {
    const profile = getCareerProfileByName(career.name);
    if (!profile?.personality) {
      careerPersonalityFit[String(career._id)] = Math.round(50 + confidence * 20);
      continue;
    }

    const pref = profile.personality; // { EI:'I', SN:'N', TF:'T', JP:'J' }

    // Fit = average ratio for preferred poles (0..1) => (0..100)
    const preferRatios = [];
    for (const dim of ['EI','SN','TF','JP']) {
      const pole = pref[dim];
      preferRatios.push(safeNum(dimensionRatios[pole], 0.5));
    }

    const base = preferRatios.reduce((s, x) => s + x, 0) / preferRatios.length; // 0..1
    const score = Math.round(base * 100);

    careerPersonalityFit[String(career._id)] = score;
  }

  return {
    mbtiType,
    dimensionRatios,
    confidence: Number(confidence.toFixed(2)),
    careerPersonalityFit,
    diagnostics: { answered: items.length },
  };
}

module.exports = { scorePersonality };