// src/modules/assessment/scoring/technical.scorer.js

const { normalizeTo100, safeNum } = require('./helpers');

/**
 * Technical scoring (MVP but correct):
 * - For each answered technical question:
 *   - If selected option isCorrect -> add points
 *   - If option has careerWeights -> add weighted points per career
 *   - Else -> add generic points equally (so technical still matters)
 *
 * Then normalize per career to 0..100.
 */
function scoreTechnical({ answersWithQuestions, careers }) {
  const items = (answersWithQuestions || []).filter(
    (x) => x?.question?.category === 'technical'
  );

  const careerScore = {};
  const careerMax = {};
  for (const c of careers || []) {
    careerScore[String(c._id)] = 0;
    careerMax[String(c._id)] = 0;
  }

  let baseCorrect = 0;
  let specialtyCorrect = 0;

  for (const item of items) {
    const q = item.question;
    const opt = q?.options?.[item.selectedOptionIndex];
    if (!q || !opt) continue;

    const isCorrect = opt.isCorrect === true;
    const multiplier = safeNum(q?.meta?.technical?.multiplier, 1);
    const isSpecialty = q?.meta?.technical?.isSpecialty === true;

    // define "points this question contributes if correct"
    const questionPoints = 10 * multiplier; // arbitrary but stable

    // max always increases (fairness)
    for (const c of careers || []) {
      careerMax[String(c._id)] += questionPoints;
    }

    if (!isCorrect) continue;

    if (isSpecialty) specialtyCorrect += 1;
    else baseCorrect += 1;

    const weights = Array.isArray(opt.careerWeights) ? opt.careerWeights : [];

    if (weights.length) {
      // distribute per career by weights
      for (const w of weights) {
        const id = String(w.careerId);
        if (careerScore[id] === undefined) continue;
        careerScore[id] += safeNum(w.weight, 0) * multiplier;
      }
    } else {
      // no careerWeights => give everyone equal credit for correctness
      for (const c of careers || []) {
        careerScore[String(c._id)] += questionPoints;
      }
    }
  }

  // normalize to 0..100
  const careerTechnicalScores = {};
  for (const c of careers || []) {
    const id = String(c._id);
    careerTechnicalScores[id] = Math.round(normalizeTo100(careerScore[id], careerMax[id]));
  }

  // confidence: how many answered + correctness rate
  const answered = items.length;
  const correct = baseCorrect + specialtyCorrect;
  const confidence = answered ? Math.min(1, correct / answered) : 0;

  return {
    careerTechnicalScores,
    diagnostics: {
      answered,
      baseCorrectCount: baseCorrect,
      specialtyCorrectCount: specialtyCorrect,
      technicalConfidence: Number(confidence.toFixed(2)),
    },
  };
}

module.exports = { scoreTechnical };