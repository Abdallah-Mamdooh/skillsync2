const asyncHandler = require('../../middlewares/async.middleware');
const assessmentService = require('./assessment.service');
const Question = require('./question.model');
const AssessmentSection = require('./assessmentSection.model');

/**
 * GET all assessment sections
 */
const getSections = asyncHandler(async (req, res) => {
  const sections = await AssessmentSection.find().sort('order');

  res.status(200).json({
    success: true,
    data: sections
  });
});

/**
 * GET questions by section
 */
const getQuestionsBySection = asyncHandler(async (req, res) => {
  const { sectionId } = req.params;

  const questions = await Question.find({ sectionId });

  res.status(200).json({
    success: true,
    data: questions
  });
});

/**
 * SUBMIT assessment
 * Supports:
 * - First time submission
 * - Overwrite confirmation
 */
const submitAssessment = asyncHandler(async (req, res) => {
  const { answers, forceOverwrite } = req.body;

  if (!answers || !Array.isArray(answers) || answers.length === 0) {
    return res.status(400).json({
      success: false,
      message: 'Answers are required'
    });
  }

  const results = await assessmentService.submitAssessment(
    req.user._id,
    answers,
    forceOverwrite || false
  );

  // If overwrite confirmation required
  if (results.requiresConfirmation) {
    return res.status(200).json({
      success: true,
      requiresConfirmation: true,
      message: results.message
    });
  }

  res.status(200).json({
    success: true,
    message: 'Assessment completed successfully',
    data: results
  });
});

/**
 * CHOOSE career after assessment
 */
const chooseCareer = asyncHandler(async (req, res) => {
  const { careerId } = req.body;

  if (!careerId) {
    return res.status(400).json({
      success: false,
      message: 'careerId is required'
    });
  }

  const response = await assessmentService.chooseCareer(
    req.user._id,
    careerId
  );

  res.status(200).json({
    success: true,
    message: response.message,
    data: response.data
  });
});

module.exports = {
  getSections,
  getQuestionsBySection,
  submitAssessment,
  chooseCareer
};