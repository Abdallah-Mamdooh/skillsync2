// src/modules/assessment/scoring/index.js

const { FINAL_WEIGHTS } = require('./constants');
const { scorePersonality } = require('./personality.scorer');
const { scoreTechnical } = require('./technical.scorer');
const { scoreSoftSkills } = require('./softskills.scorer');

function scoreAssessment({ answersWithQuestions, careers }) {
  // Run each scorer
  const personality = scorePersonality({ answersWithQuestions, careers });
  const technical = scoreTechnical({ answersWithQuestions, careers });
  const soft = scoreSoftSkills({ answersWithQuestions, careers });

  // Combine per career
  const scoresArray = (careers || []).map((career) => {
    const id = String(career._id);

    const technicalScore = technical.careerTechnicalScores?.[id] ?? 0;
    const personalityScore = personality.careerPersonalityFit?.[id] ?? 0;
    const softScore = soft.careerSoftFit?.[id] ?? 0;

    const finalScore =
      technicalScore * FINAL_WEIGHTS.technical +
      personalityScore * FINAL_WEIGHTS.personality +
      softScore * FINAL_WEIGHTS.soft;

    return {
      careerId: career._id,
      name: career.name,
      finalScore: Math.round(finalScore),

      // breakdown (frontend will show these)
      technical: Math.round(technicalScore),
      personality: Math.round(personalityScore),
      soft: Math.round(softScore),
    };
  });

  scoresArray.sort((a, b) => b.finalScore - a.finalScore);

  return {
    scoresArray,
    personalityResult: personality,
    technicalResult: technical,
    softSkillsResult: soft,
  };
}

module.exports = { scoreAssessment };