// src/modules/assessment/scoring/technical.scorer.js

const { normalizeTo100, safeNumber, toId } = require('./helpers');

function getCareerWeightForOption(option, careerId) {
  const list = option?.careerWeights || [];
  const found = list.find((x) => String(x.careerId) === String(careerId));
  return safeNumber(found?.weight, 0);
}

function scoreTechnical({ answersWithQuestions, careers }) {
  const rawByCareer = {};
  const maxByCareer = {};
  careers.forEach((c) => {
    rawByCareer[toId(c._id)] = 0;
    maxByCareer[toId(c._id)] = 0;
  });

  let totalTech = 0;
  let correctCount = 0;

  for (const item of answersWithQuestions) {
    const q = item.question;
    if (!q || q.category !== 'technical') continue;

    totalTech++;

    const selected = q.options?.[item.selectedOptionIndex];
    if (!selected) continue;

    const isCorrect = selected.isCorrect === true;
    if (isCorrect) correctCount++;

    const multiplier = safeNumber(q.meta?.technical?.multiplier, 1);

    // For normalization fairness: per career, max for this question = max weight among options
    for (const career of careers) {
      const cid = toId(career._id);

      // max possible for this career on this question
      let maxW = 0;
      for (const opt of q.options || []) {
        const w = getCareerWeightForOption(opt, cid);
        if (w > maxW) maxW = w;
      }
      maxByCareer[cid] += maxW * multiplier;

      // add only if correct (MCQ)
      if (isCorrect) {
        const w = getCareerWeightForOption(selected, cid);
        rawByCareer[cid] += w * multiplier;
      }
    }
  }

  const careerTechnicalScores = {};
  for (const career of careers) {
    const cid = toId(career._id);
    careerTechnicalScores[cid] = normalizeTo100(rawByCareer[cid], maxByCareer[cid]);
  }

  const confidence = totalTech ? (correctCount / totalTech) : 0;

  return {
    careerTechnicalScores,
    diagnostics: {
      totalTech,
      correctCount,
      technicalConfidence: confidence,
    },
  };
}

module.exports = { scoreTechnical };