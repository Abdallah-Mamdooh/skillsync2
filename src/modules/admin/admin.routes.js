const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./admin.controller');

router.get(
  '/dashboard-summary',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getDashboardSummary
);

router.get(
  '/analytics/overview',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getAnalyticsOverview
);

router.get(
  '/analytics/user-growth',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getUserGrowthAnalytics
);

router.get(
  '/analytics/mentor-growth',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getMentorGrowthAnalytics
);

router.get(
  '/analytics/session-trends',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getSessionTrendAnalytics
);

router.get(
  '/analytics/top-careers',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getTopCareersAnalytics
);

router.get(
  '/analytics/top-skills',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getTopSkillsAnalytics
);

router.get(
  '/careers',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getCareers
);

router.get(
  '/careers/:careerId',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getCareerDetails
);

router.post(
  '/careers',
  authMiddleware,
  roleMiddleware('admin'),
  validate(['name']),
  controller.createCareer
);

router.patch(
  '/careers/:careerId',
  authMiddleware,
  roleMiddleware('admin'),
  controller.updateCareer
);

router.delete(
  '/careers/:careerId',
  authMiddleware,
  roleMiddleware('admin'),
  controller.deleteCareer
);

router.get(
  '/careers/:careerId/roadmap',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getCareerRoadmap
);

router.patch(
  '/careers/:careerId/roadmap/steps/:stepId/resources',
  authMiddleware,
  roleMiddleware('admin'),
  validate(['resources']),
  controller.updateRoadmapStepResources
);
router.get(
  '/users',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getUsers
);

router.get(
  '/users/:userId',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getUserDetails
);

router.patch(
  '/users/:userId/status',
  authMiddleware,
  roleMiddleware('admin'),
  validate(['isActive']),
  controller.updateUserStatus
);

router.get(
  '/mentors',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getMentors
);

router.get(
  '/mentors/:mentorProfileId',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getMentorDetails
);

router.patch(
  '/mentors/:mentorProfileId/status',
  authMiddleware,
  roleMiddleware('admin'),
  controller.updateMentorStatus
);

router.get(
  '/mentor-profiles',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getAllMentorProfiles
);

router.get(
  '/mentor-profiles/pending',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getPendingMentorProfiles
);

router.post(
  '/mentor-profiles/:mentorProfileId/verify',
  authMiddleware,
  roleMiddleware('admin'),
  controller.verifyMentorProfile
);

router.post(
  '/mentor-profiles/:mentorProfileId/unverify',
  authMiddleware,
  roleMiddleware('admin'),
  controller.unverifyMentorProfile
);

router.get(
  '/complaints/open',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getOpenComplaints
);

router.post(
  '/complaints/:feedbackId/status',
  authMiddleware,
  roleMiddleware('admin'),
  validate(['complaintStatus']),
  controller.updateComplaintStatus
);

router.get(
  '/transactions',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getTransactions
);

router.get(
  '/mentor-cancellations/pending',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getPendingMentorCancellations
);

router.post(
  '/mentor-cancellations/:sessionId/review',
  authMiddleware,
  roleMiddleware('admin'),
  validate(['reviewStatus']),
  controller.reviewMentorCancellation
);
router.get(
  '/mentor-activity-logs',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getMentorActivityLogs
);

router.get(
  '/schedule-change-requests/pending',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getPendingScheduleChangeRequests
);

router.post(
  '/schedule-change-requests/:requestId/approve',
  authMiddleware,
  roleMiddleware('admin'),
  controller.approveScheduleChangeRequest
);

router.post(
  '/schedule-change-requests/:requestId/reject',
  authMiddleware,
  roleMiddleware('admin'),
  controller.rejectScheduleChangeRequest
);

router.get(
  '/mentor-availability-exceptions',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getMentorAvailabilityExceptions
);

router.get(
  '/schedule-change-requests',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getScheduleChangeRequests
);
module.exports = router;