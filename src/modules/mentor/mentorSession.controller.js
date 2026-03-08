const asyncHandler = require('../../middlewares/async.middleware');
const mentorSessionService = require('./mentorSession.service');

const requestSession = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.requestSession(req.user._id, req.body);

  res.status(201).json({
    success: true,
    data,
  });
});

const getMySessions = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.getMySessions(req.user._id);

  res.status(200).json({
    success: true,
    data,
  });
});

const getMentorIncomingSessions = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.getMentorIncomingSessions(req.user._id);

  res.status(200).json({
    success: true,
    data,
  });
});

const getSessionById = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.getSessionById(
    req.params.sessionId,
    req.user._id
  );

  res.status(200).json({
    success: true,
    data,
  });
});

const acceptSession = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.acceptSession(
    req.user._id,
    req.params.sessionId,
    req.body
  );

  res.status(200).json({
    success: true,
    data,
  });
});

const rejectSession = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.rejectSession(
    req.user._id,
    req.params.sessionId
  );

  res.status(200).json({
    success: true,
    data,
  });
});


const completeSession = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.completeSession(
    req.user._id,
    req.params.sessionId
  );

  res.status(200).json({
    success: true,
    data,
  });
});
module.exports = {
  requestSession,
  getMySessions,
  getMentorIncomingSessions,
  getSessionById,
  acceptSession,
  rejectSession,
  completeSession,
};