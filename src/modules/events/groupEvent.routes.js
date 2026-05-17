const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./groupEvent.controller');

// ====================
// Public event browsing
// ====================

router.get('/public', controller.getPublicEvents);
router.get('/public/:eventId', controller.getEventById);

// ====================
// Mentor event request flow
// ====================

router.post(
  '/',
  authMiddleware,
  roleMiddleware('mentor'),
  validate(['title']),
  controller.createEvent
);

router.get(
  '/me/created',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.getMyCreatedEvents
);

router.put(
  '/:eventId',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.updateEvent
);

router.post(
  '/:eventId/submit',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.submitEventRequest
);

// ====================
// Admin event review flow
// ====================

router.get(
  '/admin/requests/pending',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getPendingEventRequests
);

router.get(
  '/admin/all',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getAllAdminEvents
);

router.post(
  '/admin/:eventId/approve',
  authMiddleware,
  roleMiddleware('admin'),
  controller.approveEventRequest
);

router.post(
  '/admin/:eventId/reject',
  authMiddleware,
  roleMiddleware('admin'),
  controller.rejectEventRequest
);

router.post(
  '/admin/:eventId/publish',
  authMiddleware,
  roleMiddleware('admin'),
  controller.publishEvent
);

// ====================
// Mentor event operation flow
// ====================

router.post(
  '/:eventId/cancel',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.cancelEvent
);

router.post(
  '/:eventId/complete',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.completeEvent
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

// ====================
// User registration flow
// ====================

router.post(
  '/:eventId/register',
  authMiddleware,
  roleMiddleware('user'),
  controller.registerForEvent
);

router.post(
  '/:eventId/register/fawry-checkout',
  authMiddleware,
  roleMiddleware('user'),
  controller.registerForEventWithFawry
);

router.post(
  '/:eventId/register/paymob-checkout',
  authMiddleware,
  roleMiddleware('user'),
  controller.registerForEventWithPaymob
);
router.get(
  '/me/registrations',
  authMiddleware,
  controller.getMyEventRegistrations
);

module.exports = router;