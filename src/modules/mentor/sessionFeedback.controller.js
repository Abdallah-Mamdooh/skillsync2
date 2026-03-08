const asyncHandler = require('../../middlewares/async.middleware');
const feedbackService = require('./sessionFeedback.service');

const submitSessionFeedback = asyncHandler(async (req, res) => {
  const data = await feedbackService.submitSessionFeedback(req.user._id, req.body);

  res.status(201).json({
    success: true,
    data,
  });
});

const getMyFeedbackForSession = asyncHandler(async (req, res) => {
  const data = await feedbackService.getMyFeedbackForSession(
    req.user._id,
    req.params.sessionId
  );

  res.status(200).json({
    success: true,
    data,
  });
});

const getMentorFeedbackSummary = asyncHandler(async (req, res) => {
  const data = await feedbackService.getMentorFeedbackSummary(req.user._id);

  res.status(200).json({
    success: true,
    data,
  });
});

const getOpenComplaints = asyncHandler(async (req, res) => {
  const data = await feedbackService.getOpenComplaints(req.user._id);

  res.status(200).json({
    success: true,
    data,
  });
});

module.exports = {
  submitSessionFeedback,
  getMyFeedbackForSession,
  getMentorFeedbackSummary,
  getOpenComplaints,
};