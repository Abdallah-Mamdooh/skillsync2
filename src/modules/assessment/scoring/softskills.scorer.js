// src/modules/assessment/scoring/softskills.scorer.js

const { LIKERT_SCORE, SOFT_BEHAVIOR_POINTS_BY_QUESTION, SOFT_SJT_POINTS_BY_QUESTION } = require('./constants');
const { normalizeTo100, reverseLikertScore, safeNumber, clamp, safeDivide, toId } = require('./helpers');
const { getCareerProfileByName } = require('./careerProfiles');

function optionKeyFromAnswer(question, selectedIndex) {
  const opt = question.options?.[selectedIndex];
  return opt?.key || null;
}

function scoreSoftSkills({ answersWithQuestions, careers }) {
  const categoryRaw = {};
  const categoryMax = {};

  const likertByCode = {}; // for reliability pairs

  // Collect category raw/max
  for (const item of answersWithQuestions) {
    const q = item.question;
    if (!q || q.category !== 'soft') continue;

    const softCategory = q.meta?.soft?.softCategory || 'general';
    categoryRaw[softCategory] = safeNumber(categoryRaw[softCategory], 0);
    categoryMax[softCategory] = safeNumber(categoryMax[softCategory], 0);

    if (q.answerType === 'likert') {
      const opt = q.options?.[item.selectedOptionIndex];
      const key = opt?.key;
      if (!key || !LIKERT_SCORE[key]) continue;

      let score = LIKERT_SCORE[key]; // 1..5
      if (q.meta?.soft?.isReverse) {
        score = reverseLikertScore(score);
      }

      categoryRaw[softCategory] += score;
      categoryMax[softCategory] += 5;

      likertByCode[q.questionCode] = score;
      continue;
    }

    // behavior / sjt are single (A/B/C/D)
    const key = optionKeyFromAnswer(q, item.selectedOptionIndex);
    if (!key) continue;

    const code = q.questionCode;
    const map =
      SOFT_BEHAVIOR_POINTS_BY_QUESTION[code] ||
      SOFT_SJT_POINTS_BY_QUESTION[code] ||
      null;

    if (!map) continue;

    const pts = safeNumber(map[key], 0); // 0..4
    categoryRaw[softCategory] += pts;
    categoryMax[softCategory] += 4;
  }

  // Category score 0..100
  const categoryScores = {};
  for (const k of Object.keys(categoryRaw)) {
    categoryScores[k] = normalizeTo100(categoryRaw[k], categoryMax[k]);
  }

  // Reliability from reverse pairs in S61–S68:
  // (S61 vs S62), (S63 vs S64), (S65 vs S66), (S67 vs S68)
  const pairs = [
    ['S61', 'S62'],
    ['S63', 'S64'],
    ['S65', 'S66'],
    ['S67', 'S68'],
  ];

  let relSum = 0;
  let relCount = 0;

  for (const [a, b] of pairs) {
    const sa = likertByCode[a];
    const sb = likertByCode[b];
    if (!sa || !sb) continue;

    // they are "opposites", so best consistency is sa ≈ sb (after reverse already applied in seeding)
    const diff = Math.abs(sa - sb); // 0..4
    const pairRel = 1 - (diff / 4);
    relSum += pairRel;
    relCount++;
  }

  const reliability = relCount ? clamp(relSum / relCount, 0, 1) : 0.5;

  // Career soft fit using career profile weights
  const careerSoftFit = {};
  for (const career of careers) {
    const profile = getCareerProfileByName(career.name);
    const weights = profile?.softWeights || null;

    if (!weights) {
      // neutral average
      const values = Object.values(categoryScores);
      const avg = values.length ? values.reduce((s, v) => s + v, 0) / values.length : 50;
      careerSoftFit[toId(career._id)] = avg;
      continue;
    }

    let wSum = 0;
    let scoreSum = 0;

    for (const [cat, w] of Object.entries(weights)) {
      const s = safeNumber(categoryScores[cat], 50);
      scoreSum += s * safeNumber(w, 0);
      wSum += safeNumber(w, 0);
    }

    careerSoftFit[toId(career._id)] = wSum ? (scoreSum / wSum) : 50;
  }

  return {
    categoryScores,
    reliability,
    careerSoftFit,
  };
}

module.exports = { scoreSoftSkills };