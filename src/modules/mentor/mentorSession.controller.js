const asyncHandler = require('../../middlewares/async.middleware');
const mentorSessionService = require('./mentorSession.service');

const requestSession = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.requestSession(req.user._id, req.body);

  res.status(201).json({
    success: true,
    data,
  });
});

const createSessionFawryCheckout = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.createSessionFawryCheckout(
    req.user._id,
    req.body
  );

  res.status(201).json({
    success: true,
    data,
  });
});

const createSessionPaymobCheckout = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.createSessionPaymobCheckout(
    req.user._id,
    req.body
  );

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

const startSession = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.startSession(
    req.user._id,
    req.params.sessionId
  );

  res.status(200).json({
    success: true,
    data,
  });
});

const joinSession = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.joinSession(
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

const cancelSession = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.cancelSession(
    req.user._id,
    req.params.sessionId
  );

  res.status(200).json({
    success: true,
    data,
  });
});

const mentorCancelSession = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.mentorCancelSession(
    req.user._id,
    req.params.sessionId,
    req.body
  );

  res.status(200).json({
    success: true,
    data,
  });
});

const getSessionTimer = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.getSessionTimer(
    req.user._id,
    req.params.sessionId
  );

  res.status(200).json({
    success: true,
    data,
  });
});

const runLifecycleSweep = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.runLifecycleSweep();

  res.status(200).json({
    success: true,
    data,
  });
});

const expirePendingSessions = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.expirePendingSessions();

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

module.exports = {
  requestSession,
  createSessionFawryCheckout,
  createSessionPaymobCheckout,
  getMySessions,
  getMentorIncomingSessions,
  getSessionById,
  startSession,
  joinSession,
  completeSession,
  cancelSession,
  mentorCancelSession,
  getSessionTimer,
  runLifecycleSweep,
  expirePendingSessions,
  acceptSession,
  rejectSession,
};