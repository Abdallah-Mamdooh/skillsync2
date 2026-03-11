const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./groupEvent.controller');

// public
router.get('/public', controller.getPublicEvents);
router.get('/public/:eventId', controller.getEventById);

// organizer
router.post(
  '/',
  authMiddleware,
  roleMiddleware('mentor'),
  validate(['title', 'meetingLink', 'scheduledAt']),
  controller.createEvent
);

router.put(
  '/:eventId',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.updateEvent
);

router.post(
  '/:eventId/publish',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.publishEvent
);

router.post(
  '/registrations/:registrationId/capture',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.captureEventRegistrationPayment
);

router.post(
  '/registrations/:registrationId/release',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.releaseEventRegistrationPayment
);

router.post(
  '/registrations/:registrationId/attend',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.markRegistrationAttended
);

router.post(
  '/:eventId/complete',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.completeEvent
);

// attendee
router.post(
  '/:eventId/register',
  authMiddleware,
  roleMiddleware('user'),
  controller.registerForEvent
);

router.get('/me/registrations', authMiddleware, controller.getMyEventRegistrations);

module.exports = router;