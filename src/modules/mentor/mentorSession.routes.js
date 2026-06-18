const express = require('express');

const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./mentorSession.controller');

const bookingValidation = validate([
  'mentorProfileId',
  'method',
  'durationMinutes',
  'scheduledDate',
  'scheduledStartTime',
]);

// User side: wallet/default payment hold booking
router.post(
  '/',
  authMiddleware,
  roleMiddleware('user'),
  bookingValidation,
  controller.requestSession
);

// User side: Paymob checkout booking
router.post(
  '/paymob-checkout',
  authMiddleware,
  roleMiddleware('user'),
  bookingValidation,
  controller.createSessionPaymobCheckout
);

// Legacy compatibility only
router.post(
  '/fawry-checkout',
  authMiddleware,
  roleMiddleware('user'),
  bookingValidation,
  controller.createSessionFawryCheckout
);

// User sessions
router.get('/me', authMiddleware, controller.getMySessions);

// Manual sweeps for testing/admin operations
// Put these before dynamic /:sessionId routes to avoid route confusion
router.post('/lifecycle/run', authMiddleware, controller.runLifecycleSweep);
router.post('/expire-pending/run', authMiddleware, controller.expirePendingSessions);

// Mentor side
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

router.post(
  '/:sessionId/mentor-cancel',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.mentorCancelSession
);

// User side session actions
router.post(
  '/:sessionId/join',
  authMiddleware,
  roleMiddleware('user'),
  controller.joinSession
);

router.post(
  '/:sessionId/cancel',
  authMiddleware,
  roleMiddleware('user'),
  controller.cancelSession
);

// Shared details
router.get('/:sessionId/timer', authMiddleware, controller.getSessionTimer);
router.get('/:sessionId', authMiddleware, controller.getSessionById);

// Kept only for compatibility with old flow
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