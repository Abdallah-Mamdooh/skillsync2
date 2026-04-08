const { normalizeTo100, safeNumber, toId } = require('./helpers');

function getCareerWeightForOption(option, careerId) {
  const list = Array.isArray(option?.careerWeights) ? option.careerWeights : [];
  const found = list.find((x) => String(x.careerId) === String(careerId));
  return safeNumber(found?.weight, 0);
}

function isAnswerCorrect(question, selectedOptionIndex) {
  if (!question) return false;

  // preferred source: question.correctOptionIndex
  if (
    typeof question.correctOptionIndex === 'number' &&
    !Number.isNaN(question.correctOptionIndex)
  ) {
    return Number(selectedOptionIndex) === Number(question.correctOptionIndex);
  }

  // fallback source: option.isCorrect
  const selected = question.options?.[selectedOptionIndex];
  return selected?.isCorrect === true;
}

function scoreTechnical({ answersWithQuestions, careers, selectedInterests = [] }) {
  const rawByCareer = {};
  const maxByCareer = {};

  careers.forEach((career) => {
    const cid = toId(career._id);
    rawByCareer[cid] = 0;
    maxByCareer[cid] = 0;
  });

  let totalTech = 0;
  let correctCount = 0;

  let baseCount = 0;
  let baseCorrectCount = 0;

  let specialtyCount = 0;
  let specialtyCorrectCount = 0;

  for (const item of answersWithQuestions) {
    const q = item.question;
    if (!q || q.category !== 'technical') continue;

    totalTech += 1;

    const selected = q.options?.[item.selectedOptionIndex];
    if (!selected) continue;

    const isSpecialty =
      q?.meta?.technical?.isSpecialty === true ||
      String(q.questionCode || '').startsWith('TS-');

    const multiplier = safeNumber(q?.meta?.technical?.multiplier, 1);
    const isCorrect = isAnswerCorrect(q, item.selectedOptionIndex);

    if (isSpecialty) {
      specialtyCount += 1;
      if (isCorrect) specialtyCorrectCount += 1;
    } else {
      baseCount += 1;
      if (isCorrect) baseCorrectCount += 1;
    }

    if (isCorrect) {
      correctCount += 1;
    }

    for (const career of careers) {
      const cid = toId(career._id);

      let maxWeightForQuestion = 0;
      for (const option of q.options || []) {
        const weight = getCareerWeightForOption(option, cid);
        if (weight > maxWeightForQuestion) {
          maxWeightForQuestion = weight;
        }
      }

      maxByCareer[cid] += maxWeightForQuestion * multiplier;

      if (isCorrect) {
        const selectedWeight = getCareerWeightForOption(selected, cid);
        rawByCareer[cid] += selectedWeight * multiplier;
      }
    }
  }

  const careerTechnicalScores = {};
  for (const career of careers) {
    const cid = toId(career._id);
    careerTechnicalScores[cid] = normalizeTo100(rawByCareer[cid], maxByCareer[cid]);
  }

  const technicalConfidence = totalTech ? correctCount / totalTech : 0;

  return {
    careerTechnicalScores,
    diagnostics: {
      totalTech,
      correctCount,
      baseCount,
      baseCorrectCount,
      specialtyCount,
      specialtyCorrectCount,
      technicalConfidence,
      selectedInterests,
    },
  };
}

module.exports = { scoreTechnical };