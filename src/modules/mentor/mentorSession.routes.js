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
  validate([
    'mentorProfileId',
    'method',
    'durationMinutes',
    'scheduledDate',
    'scheduledStartTime',
  ]),
  controller.requestSession
);

router.post(
  '/fawry-checkout',
  authMiddleware,
  roleMiddleware('user'),
  validate([
    'mentorProfileId',
    'method',
    'durationMinutes',
    'scheduledDate',
    'scheduledStartTime',
  ]),
  controller.createSessionFawryCheckout
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

// kept mounted for compatibility; lifecycle rewrite comes next
router.post('/:sessionId/start', authMiddleware, controller.startSession);
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

router.post('/expire-pending/run', authMiddleware, controller.expirePendingSessions);

module.exports = router;