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

router.post(
  '/paymob-checkout',
  authMiddleware,
  roleMiddleware('user'),
  validate([
    'mentorProfileId',
    'method',
    'durationMinutes',
    'scheduledDate',
    'scheduledStartTime',
  ]),
  controller.createSessionPaymobCheckout
);

router.get('/me', authMiddleware, controller.getMySessions);
router.post('/:sessionId/join', authMiddleware, roleMiddleware('user'), controller.joinSession);
router.post('/:sessionId/cancel', authMiddleware, roleMiddleware('user'), controller.cancelSession);

// mentor side
router.get(
  '/incoming',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.getMentorIncomingSessions
);

router.post(
  '/:sessionId/start',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.startSession
);

router.post(
  '/:sessionId/complete',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.completeSession
);

// shared details
router.get('/:sessionId', authMiddleware, controller.getSessionById);
router.get('/:sessionId/timer', authMiddleware, controller.getSessionTimer);

// manual sweep for testing/admin ops
router.post('/lifecycle/run', authMiddleware, controller.runLifecycleSweep);
router.post('/expire-pending/run', authMiddleware, controller.expirePendingSessions);

// kept only for compatibility
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

module.exports = router;