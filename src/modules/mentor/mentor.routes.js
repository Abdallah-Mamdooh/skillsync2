const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./mentor.controller');

// public mentor listing/details
router.get('/public', controller.getPublicMentors);
router.get('/public/:mentorId', controller.getMentorById);
router.get('/public/:mentorId/available-slots', controller.getMentorAvailableSlots);

// mentor's own profile
router.post(
  '/me',
  authMiddleware,
  roleMiddleware('mentor'),
  validate(['baseRate']),
  controller.createMentorProfile
);

router.put(
  '/me',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.updateMentorProfile
);

router.get(
  '/me',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.getMyMentorProfile
);

router.patch(
  '/me/availability-status',
  authMiddleware,
  roleMiddleware('mentor'),
  validate(['availabilityStatus']),
  controller.updateMentorAvailabilityStatus
);

router.post(
  '/breaks/expire',
  authMiddleware,
  roleMiddleware('admin'),
  controller.expireFinishedBreaks
);
router.post(
  '/me/schedule-change-request',
  authMiddleware,
  roleMiddleware('mentor'),
  validate(['requestedAvailability', 'effectiveFrom']),
  controller.submitScheduleChangeRequest
);
router.post(
  '/schedule-change-requests/apply-due',
  authMiddleware,
  roleMiddleware('admin'),
  controller.applyApprovedScheduleChanges
);

router.post(
  '/me/availability-exceptions',
  authMiddleware,
  roleMiddleware('mentor'),
  validate(['unavailableFrom', 'unavailableTo']),
  controller.createAvailabilityException
);

router.get(
  '/me/availability-exceptions',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.getMyAvailabilityExceptions
);

router.delete(
  '/me/availability-exceptions/:exceptionId',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.removeAvailabilityException
);

router.get(
  '/me/schedule-change-requests',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.getMyScheduleChangeRequests
);
module.exports = router;