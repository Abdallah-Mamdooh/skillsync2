const asyncHandler = require('../../middlewares/async.middleware');
const assessmentService = require('./assessment.service');

const getSections = asyncHandler(async (req, res) => {
  const sections = await assessmentService.getSections();
  res.status(200).json({ success: true, data: sections });
});

const getQuestionsBySection = asyncHandler(async (req, res) => {
  const { sectionId } = req.params;
  const questions = await assessmentService.getQuestionsBySection(
    sectionId,
    req.user._id
  );

  res.status(200).json({
    success: true,
    data: questions,
  });
});

const getMyAssessmentResult = asyncHandler(async (req, res) => {
  const result = await assessmentService.getMyAssessmentResult(req.user._id);
  res.status(200).json({
    success: true,
    data: result,
  });
});

const submitAssessment = asyncHandler(async (req, res) => {
  const result = await assessmentService.submitAssessment(req.user._id, req.body);
  res.status(200).json({ success: true, data: result });
});

const chooseCareer = asyncHandler(async (req, res) => {
  const { careerId } = req.body;

  if (!careerId) {
    return res.status(400).json({
      success: false,
      message: 'careerId is required',
    });
  }

  const result = await assessmentService.chooseCareer(req.user._id, careerId);
  res.status(200).json({ success: true, data: result });
});

const saveInterests = asyncHandler(async (req, res) => {
  const result = await assessmentService.saveInterests(req.user._id, req.body);
  res.status(200).json({
    success: true,
    data: result,
  });
});

module.exports = {
  getSections,
  getQuestionsBySection,
  getMyAssessmentResult,
  submitAssessment,
  chooseCareer,
  saveInterests,
};