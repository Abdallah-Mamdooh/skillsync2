const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const controller = require('./dashboardCompat.controller');

router.get(
  '/dashboard/stats',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getDashboardStatsCompat
);

router.get(
  '/users',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getUsersCompat
);

router.put(
  '/users/:userId',
  authMiddleware,
  roleMiddleware('admin'),
  controller.updateUserCompat
);

router.delete(
  '/users/:userId',
  authMiddleware,
  roleMiddleware('admin'),
  controller.deleteUserCompat
);

router.get(
  '/mentors',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getMentorsCompat
);

router.put(
  '/mentors/:mentorId',
  authMiddleware,
  roleMiddleware('admin'),
  controller.updateMentorCompat
);

router.delete(
  '/mentors/:mentorId',
  authMiddleware,
  roleMiddleware('admin'),
  controller.deleteMentorCompat
);

router.get(
  '/careerpaths',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getCareerPathsCompat
);

router.post(
  '/careerpaths',
  authMiddleware,
  roleMiddleware('admin'),
  controller.createCareerPathCompat
);

router.put(
  '/careerpaths/:careerPathId',
  authMiddleware,
  roleMiddleware('admin'),
  controller.updateCareerPathCompat
);

router.delete(
  '/careerpaths/:careerPathId',
  authMiddleware,
  roleMiddleware('admin'),
  controller.deleteCareerPathCompat
);

router.get(
  '/feedback',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getFeedbackCompat
);

router.put(
  '/feedback/:feedbackId',
  authMiddleware,
  roleMiddleware('admin'),
  controller.updateFeedbackCompat
);

router.delete(
  '/feedback/:feedbackId',
  authMiddleware,
  roleMiddleware('admin'),
  controller.deleteFeedbackCompat
);

router.get(
  '/analytics',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getAnalyticsCompat
);

router.get(
  '/payments',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getPaymentsCompat
);

router.get(
  '/payments/summary',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getPaymentsSummaryCompat
);

router.get(
  '/settings',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getSettingsCompat
);

router.patch(
  '/settings',
  authMiddleware,
  roleMiddleware('admin'),
  controller.updateSettingsCompat
);

router.get(
  '/settings/security-logs',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getSettingsSecurityLogsCompat
);

router.get(
  '/settings',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getSettingsCompat
);

router.patch(
  '/settings',
  authMiddleware,
  roleMiddleware('admin'),
  controller.updateSettingsCompat
);

router.get(
  '/settings/security-logs',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getSettingsSecurityLogsCompat
);


router.get(
  '/events/requests/pending',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getPendingEventRequestsCompat
);

router.get(
  '/events',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getEventsCompat
);

router.post(
  '/events/:eventId/approve',
  authMiddleware,
  roleMiddleware('admin'),
  controller.approveEventRequestCompat
);

router.post(
  '/events/:eventId/reject',
  authMiddleware,
  roleMiddleware('admin'),
  controller.rejectEventRequestCompat
);

router.post(
  '/events/:eventId/publish',
  authMiddleware,
  roleMiddleware('admin'),
  controller.publishEventCompat
);
module.exports = router;