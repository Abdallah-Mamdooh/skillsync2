const asyncHandler = require('../../middlewares/async.middleware');
const mentorSessionService = require('./mentorSession.service');

const requestSession = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.requestSession(req.user._id, req.body);
  res.status(201).json({ success: true, data });
});

const createSessionFawryCheckout = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.createSessionFawryCheckout(
    req.user._id,
    req.body
  );
  res.status(201).json({ success: true, data });
});

const createSessionPaymobCheckout = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.createSessionPaymobCheckout(
    req.user._id,
    req.body
  );

  res.status(201).json({ success: true, data });
});

const getMySessions = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.getMySessions(req.user._id);
  res.status(200).json({ success: true, data });
});

const getMentorIncomingSessions = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.getMentorIncomingSessions(req.user._id);
  res.status(200).json({ success: true, data });
});

const getSessionById = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.getSessionById(
    req.params.sessionId,
    req.user._id
  );
  res.status(200).json({ success: true, data });
});

const startSession = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.startSession(
    req.user._id,
    req.params.sessionId
  );
  res.status(200).json({ success: true, data });
});

const joinSession = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.joinSession(
    req.user._id,
    req.params.sessionId
  );
  res.status(200).json({ success: true, data });
});

const completeSession = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.completeSession(
    req.user._id,
    req.params.sessionId
  );
  res.status(200).json({ success: true, data });
});

const cancelSession = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.cancelSession(
    req.user._id,
    req.params.sessionId
  );
  res.status(200).json({ success: true, data });
});

const getSessionTimer = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.getSessionTimer(
    req.user._id,
    req.params.sessionId
  );
  res.status(200).json({ success: true, data });
});

const runLifecycleSweep = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.runLifecycleSweep();
  res.status(200).json({ success: true, data });
});

// kept for compatibility
const acceptSession = asyncHandler(async () => {
  throw new Error('Session accept is disabled in the new booking flow');
});

const rejectSession = asyncHandler(async () => {
  throw new Error('Session reject is disabled in the new booking flow');
});

const expirePendingSessions = asyncHandler(async (req, res) => {
  const data = await mentorSessionService.expirePendingSessions();
  res.status(200).json({ success: true, data });
});

module.exports = {
  requestSession,
  getMySessions,
  getMentorIncomingSessions,
  getSessionById,
  acceptSession,
  rejectSession,
  completeSession,
  startSession,
  expirePendingSessions,
  createSessionFawryCheckout,
  joinSession,
  cancelSession,
  getSessionTimer,
  runLifecycleSweep,
  createSessionPaymobCheckout,
};