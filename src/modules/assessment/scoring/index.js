// src/modules/assessment/scoring/index.js

const { FINAL_WEIGHTS } = require('./constants');
const { clamp, toId } = require('./helpers');
const { scorePersonality } = require('./personality.scorer');
const { scoreTechnical } = require('./technical.scorer');
const { scoreSoftSkills } = require('./softskills.scorer');

function scoreAssessment({ answersWithQuestions, careers }) {
  const personality = scorePersonality({ answersWithQuestions, careers });
  const technical = scoreTechnical({ answersWithQuestions, careers });
  const softSkills = scoreSoftSkills({ answersWithQuestions, careers });

  const rankedCareers = careers.map((career) => {
    const cid = toId(career._id);

    const technicalScore = technical.careerTechnicalScores[cid] ?? 0;
    const personalityScore = personality.careerPersonalityFit[cid] ?? 50;
    const softScore = softSkills.careerSoftFit[cid] ?? 50;

    const final =
      technicalScore * FINAL_WEIGHTS.technical +
      personalityScore * FINAL_WEIGHTS.personality +
      softScore * FINAL_WEIGHTS.soft;

    return {
      careerId: career._id,
      name: career.name,
      finalScore: clamp(final, 0, 100),
      technical: clamp(technicalScore, 0, 100),
      personality: clamp(personalityScore, 0, 100),
      soft: clamp(softScore, 0, 100),
    };
  });

  rankedCareers.sort((a, b) => b.finalScore - a.finalScore);

  return {
    rankedCareers,
    personalityResult: personality,
    technicalResult: technical,
    softSkillsResult: softSkills,
  };
}

module.exports = { scoreAssessment };