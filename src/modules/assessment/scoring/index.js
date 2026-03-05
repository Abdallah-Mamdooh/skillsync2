// src/modules/assessment/scoring/index.js
/**
 * Scoring engine (MVP+):
 * 1) Primary scoring: use options[].careerWeights if present.
 * 2) Fallback scoring: if totalScore == 0, use user selectedInterests to produce meaningful roadmap suggestions.
 *
 * Output keeps backward compatibility:
 * - scoresArray: [{careerId, totalScore, percentage, name}]
 * - rankedCareers: same array sorted desc
 */

// src/modules/assessment/scoring/index.js
const { FINAL_WEIGHTS } = require('./constants');
const { round1, clamp } = require('./helpers');

const { scorePersonality } = require('./personality.scorer');
const { scoreTechnical } = require('./technical.scorer');
const { scoreSoftSkills } = require('./softskills.scorer');





function norm(str) {
  return String(str || '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

// Interest -> likely careers by NAME (matches your Career.name from roadmap import)
const INTEREST_TO_CAREER_NAMES = {
  web: ['frontend', 'backend', 'full stack', 'react', 'angular', 'vue', 'nodejs'],
  data_ai: ['data analyst', 'data engineer', 'machine learning', 'ai engineer', 'ai data scientist', 'mlops'],
  devops: ['devops', 'aws', 'kubernetes', 'terraform', 'linux'],
  security: ['cyber security', 'api security best practices'],
  design: ['ux design', 'design system'],
  product: ['product manager'],
  qa: ['qa'],
  mobile_game: ['android', 'ios', 'game developer'],
};

function scoreAssessment({ answersWithQuestions, careers, selectedInterests = [] }) {
  // -------------------- 1) Primary scoring by careerWeights --------------------
  const careerScores = {};
  careers.forEach((c) => {
    careerScores[String(c._id)] = 0;
  });

  for (const item of answersWithQuestions || []) {
    const { question, selectedOptionIndex } = item;
    if (!question) continue;

    const option = question.options?.[selectedOptionIndex];
    if (!option) continue;

    for (const w of option.careerWeights || []) {
      const key = String(w.careerId);
      if (careerScores[key] !== undefined) {
        careerScores[key] += Number(w.weight || 0);
      }
    }
  }

  let totalScore = Object.values(careerScores).reduce((sum, v) => sum + v, 0);

  // -------------------- 2) Fallback: interest-based scoring if weights give 0 --------------------
  // This ensures the user ALWAYS gets roadmap suggestions even if MCQs don't have careerWeights.
  if (!totalScore || totalScore <= 0) {
    const interests = Array.isArray(selectedInterests) ? selectedInterests : [];

    // Build a set of candidate career names based on interests
    const candidateNames = new Set();
    for (const interest of interests) {
      const list = INTEREST_TO_CAREER_NAMES[interest] || [];
      list.forEach((n) => candidateNames.add(norm(n)));
    }

    // Assign base points:
    // - candidate careers get higher points
    // - non-candidates still get some points (so ranking is stable)
    careers.forEach((c) => {
      const nameN = norm(c.name);
      const isCandidate = candidateNames.size === 0 ? true : candidateNames.has(nameN);

      // You can tune these later
      careerScores[String(c._id)] = isCandidate ? 10 : 3;
    });

    totalScore = Object.values(careerScores).reduce((sum, v) => sum + v, 0);
  }

  // -------------------- 3) Format output --------------------
  const scoresArray = careers.map((career) => {
    const key = String(career._id);
    const score = careerScores[key] || 0;

    const percentage =
      totalScore === 0 ? 0 : Math.round((score / totalScore) * 100);

    return {
      careerId: career._id,
      name: career.name,        // ✅ add name so frontend can show it easily
      totalScore: score,
      percentage,
      // keep compatibility fields
      finalScore: percentage,   // ✅ optional (some UI uses finalScore)
    };
  });

  scoresArray.sort((a, b) => b.percentage - a.percentage);

function scoreAssessment({ answersWithQuestions, careers }) {
  const personalityResult = scorePersonality({ answersWithQuestions, careers });
  const technicalResult = scoreTechnical({ answersWithQuestions, careers });
  const softSkillsResult = scoreSoftSkills({ answersWithQuestions, careers });

  const rankedCareers = (careers || []).map((career) => {
    const id = String(career._id);

    const technical = technicalResult.careerTechnicalScores[id] ?? 0;
    const personality = personalityResult.careerPersonalityFit[id] ?? 50;
    const soft = softSkillsResult.careerSoftFit[id] ?? 50;

    const finalScore =
      technical * FINAL_WEIGHTS.technical +
      personality * FINAL_WEIGHTS.personality +
      soft * FINAL_WEIGHTS.soft;

    return {
      careerId: career._id,
      name: career.name,
      finalScore: round1(clamp(finalScore, 0, 100)),
      technical: round1(clamp(technical, 0, 100)),
      personality: round1(clamp(personality, 0, 100)),
      soft: round1(clamp(soft, 0, 100)),
    };
  });

  rankedCareers.sort((a, b) => b.finalScore - a.finalScore);

  // For backward compatibility: also create "scoresArray" like old format
  const scoresArray = rankedCareers.map((x) => ({
    careerId: x.careerId,
    totalScore: x.finalScore, // kept name for your old schema
    percentage: Math.round(x.finalScore),
  }));


  return {
    rankedCareers,
    personalityResult,
    technicalResult,
    personalityResult,
    softSkillsResult,
    weights: FINAL_WEIGHTS,
    totalScore,
    scoresArray,
    rankedCareers: scoresArray,
  };
}
}
module.exports = { scoreAssessment };