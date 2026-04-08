const {
  LIKERT_SCORE,
  SOFT_BEHAVIOR_POINTS_BY_QUESTION,
  SOFT_SJT_POINTS_BY_QUESTION,
} = require('./constants');
const {
  normalizeTo100,
  reverseLikertScore,
  safeNumber,
  clamp,
  toId,
} = require('./helpers');
const { getCareerProfileByName } = require('./careerProfiles');

function optionKeyFromAnswer(question, selectedIndex) {
  const option = question.options?.[selectedIndex];
  return option?.key || null;
}

function isSoftQuestion(question) {
  const category = String(question?.category || '').toLowerCase();
  return category === 'soft' || category === 'soft-skills';
}

function scoreSoftSkills({ answersWithQuestions, careers }) {
  const categoryRaw = {};
  const categoryMax = {};

  const likertByCode = {};

  for (const item of answersWithQuestions) {
    const q = item.question;
    if (!q || !isSoftQuestion(q)) continue;

    const softCategory = q.meta?.soft?.softCategory || 'general';

    categoryRaw[softCategory] = safeNumber(categoryRaw[softCategory], 0);
    categoryMax[softCategory] = safeNumber(categoryMax[softCategory], 0);

    if (q.answerType === 'likert') {
      const option = q.options?.[item.selectedOptionIndex];
      const key = option?.key;

      if (!key || !LIKERT_SCORE[key]) continue;

      let score = LIKERT_SCORE[key];
      if (q.meta?.soft?.isReverse) {
        score = reverseLikertScore(score);
      }

      categoryRaw[softCategory] += score;
      categoryMax[softCategory] += 5;

      likertByCode[q.questionCode] = score;
      continue;
    }

    const key = optionKeyFromAnswer(q, item.selectedOptionIndex);
    if (!key) continue;

    const code = q.questionCode;
    const pointsMap =
      SOFT_BEHAVIOR_POINTS_BY_QUESTION[code] ||
      SOFT_SJT_POINTS_BY_QUESTION[code] ||
      null;

    if (!pointsMap) continue;

    const points = safeNumber(pointsMap[key], 0);
    categoryRaw[softCategory] += points;
    categoryMax[softCategory] += 4;
  }

  const categoryScores = {};
  for (const category of Object.keys(categoryRaw)) {
    categoryScores[category] = normalizeTo100(
      categoryRaw[category],
      categoryMax[category]
    );
  }

  // reliability from reverse pairs
  const pairs = [
    ['S61', 'S62'],
    ['S63', 'S64'],
    ['S65', 'S66'],
    ['S67', 'S68'],
  ];

  let reliabilitySum = 0;
  let reliabilityCount = 0;

  for (const [a, b] of pairs) {
    const scoreA = likertByCode[a];
    const scoreB = likertByCode[b];

    if (scoreA === undefined || scoreB === undefined) continue;

    const diff = Math.abs(scoreA - scoreB); // 0..4
    const pairReliability = 1 - diff / 4;

    reliabilitySum += pairReliability;
    reliabilityCount += 1;
  }

  const reliability = reliabilityCount
    ? clamp(reliabilitySum / reliabilityCount, 0, 1)
    : 0.5;

  const careerSoftFit = {};

  for (const career of careers) {
    const profile = getCareerProfileByName(career.name);
    const weights = profile?.softWeights || null;

    if (!weights) {
      const values = Object.values(categoryScores);
      const average = values.length
        ? values.reduce((sum, value) => sum + value, 0) / values.length
        : 50;

      careerSoftFit[toId(career._id)] = average;
      continue;
    }

    let weightedScoreSum = 0;
    let totalWeight = 0;

    for (const [category, weight] of Object.entries(weights)) {
      const score = safeNumber(categoryScores[category], 50);
      const safeWeight = safeNumber(weight, 0);

      weightedScoreSum += score * safeWeight;
      totalWeight += safeWeight;
    }

    careerSoftFit[toId(career._id)] = totalWeight
      ? weightedScoreSum / totalWeight
      : 50;
  }

  return {
    categoryScores,
    reliability,
    careerSoftFit,
  };
}

module.exports = { scoreSoftSkills };