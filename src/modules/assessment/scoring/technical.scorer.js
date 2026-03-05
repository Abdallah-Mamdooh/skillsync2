// src/modules/assessment/scoring/technical.scorer.js
const { normalizeTo100, safeNum } = require('./helpers');

function scoreTechnical({ answersWithQuestions, careers }) {
  const items = (answersWithQuestions || []).filter(
    (x) => x?.question?.category === 'technical'
  );

  const careerRaw = {};
  const careerMax = {};

  for (const c of careers || []) {
    careerRaw[String(c._id)] = 0;
    careerMax[String(c._id)] = 0;
  }

  let baseCorrectCount = 0;
  let specialtyCorrectCount = 0;
  let baseTotal = 0;
  let specialtyTotal = 0;

  for (const item of items) {
    const q = item.question;
    if (!q) continue;

    const selected = q.options?.[item.selectedOptionIndex];
    const multiplier = safeNum(q.meta?.technical?.multiplier, 1);

    const isSpecialty = q.meta?.technical?.isSpecialty === true || String(q.questionCode || '').startsWith('TS-');

    // correctness diagnostics
    const correctIndex = q.options?.findIndex((o) => o.isCorrect === true);
    const isCorrect = correctIndex >= 0 && item.selectedOptionIndex === correctIndex;

    if (isSpecialty) {
      specialtyTotal += 1;
      if (isCorrect) specialtyCorrectCount += 1;
    } else {
      baseTotal += 1;
      if (isCorrect) baseCorrectCount += 1;
    }

    // Add to max per career: take BEST weight among options for that career (fair max)
    for (const c of careers || []) {
      const id = String(c._id);
      let best = 0;

      for (const opt of q.options || []) {
        const cw = (opt.careerWeights || []).find((w) => String(w.careerId) === id);
        const wv = safeNum(cw?.weight, 0);
        if (wv > best) best = wv;
      }

      careerMax[id] += best * multiplier;
    }

    // Add to raw per career using selected option
    for (const w of selected?.careerWeights || []) {
      const id = String(w.careerId);
      if (careerRaw[id] !== undefined) {
        careerRaw[id] += safeNum(w.weight, 0) * multiplier;
      }
    }
  }

  const careerTechnicalScores = {};
  for (const c of careers || []) {
    const id = String(c._id);
    careerTechnicalScores[id] = normalizeTo100(careerRaw[id], careerMax[id]);
  }

  // confidence based on correctness ratio (simple)
  const totalAnswered = items.length || 1;
  const correct = baseCorrectCount + specialtyCorrectCount;
  const technicalConfidence = Number((correct / totalAnswered).toFixed(2));

  return {
    careerTechnicalScores,
    diagnostics: {
      answered: items.length,
      baseCorrectCount,
      specialtyCorrectCount,
      baseTotal,
      specialtyTotal,
      technicalConfidence,
    },
  };
}

module.exports = { scoreTechnical };