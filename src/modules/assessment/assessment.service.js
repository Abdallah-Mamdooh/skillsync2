const UserAssessmentResult = require('./userAssessmentResult.model');
const Question = require('./question.model');
const Career = require('../career/career.model');

/**
 * Submit Assessment
 */
const submitAssessment = async (userId, answers, forceOverwrite = false) => {

  const existing = await UserAssessmentResult.findOne({ userId });

  if (existing && !forceOverwrite) {
    return {
      requiresConfirmation: true,
      message:
        'You have already completed the assessment. Submitting again will overwrite previous results.'
    };
  }

  // Delete old result if overwrite confirmed
  if (existing && forceOverwrite) {
    await UserAssessmentResult.deleteOne({ userId });
  }

  // Load all careers
  const careers = await Career.find();
  if (!careers.length) {
    throw new Error('No careers found in system');
  }

  // Initialize score map
  const careerScores = {};
  careers.forEach(c => {
    careerScores[c._id] = 0;
  });

  // Process answers
  for (const answer of answers) {
    const question = await Question.findById(answer.questionId);
    if (!question) continue;

    const selectedOption =
      question.options[answer.selectedOptionIndex];

    if (!selectedOption) continue;

    // Add weighted score
    for (const weight of selectedOption.careerWeights) {
      if (careerScores[weight.careerId] !== undefined) {
        careerScores[weight.careerId] += weight.weight;
      }
    }
  }

  // Calculate total possible score
  const totalScore = Object.values(careerScores).reduce(
    (sum, val) => sum + val,
    0
  );

  // Convert to percentage
  const scoresArray = careers.map(career => {
    const score = careerScores[career._id] || 0;

    return {
      careerId: career._id,
      totalScore: score,
      percentage:
        totalScore === 0
          ? 0
          : Math.round((score / totalScore) * 100)
    };
  });

  // Sort descending
  scoresArray.sort((a, b) => b.percentage - a.percentage);

  // Save result
  const saved = await UserAssessmentResult.create({
    userId,
    scores: scoresArray
  });

  return saved;
};

/**
 * Choose Career
 */
const { initializeProgress } = require('../roadmap/roadmap.service');

const chooseCareer = async (userId, careerId) => {

  const result = await UserAssessmentResult.findOne({ userId });

  if (!result) {
    throw new Error('Assessment not completed');
  }

  result.chosenCareer = careerId;
  await result.save();

  // Reset and initialize roadmap progress
  await initializeProgress(userId);

  return { message: 'Career selected and roadmap initialized' };
};


module.exports = {
  submitAssessment,
  chooseCareer
};