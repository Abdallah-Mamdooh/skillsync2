const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./mentorSession.controller');

// user side
router.post(
  '/',
  authMiddleware,
  roleMiddleware('user'),
  validate(['mentorProfileId', 'method', 'durationMinutes']),
  controller.requestSession
);

router.get('/me', authMiddleware, controller.getMySessions);

// mentor side
router.get(
  '/incoming',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.getMentorIncomingSessions
);

// shared details
router.get('/:sessionId', authMiddleware, controller.getSessionById);

// session lifecycle
router.post('/:sessionId/start', authMiddleware, controller.startSession);

// mentor actions
router.post(
  '/:sessionId/accept',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.acceptSession
);

router.post(
  '/:sessionId/reject',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.rejectSession
);

router.post(
  '/:sessionId/complete',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.completeSession
);

// manual expire endpoint for MVP/admin/testing
router.post('/expire-pending/run', authMiddleware, controller.expirePendingSessions);

module.exports = router;