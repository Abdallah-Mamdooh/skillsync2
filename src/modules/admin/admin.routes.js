const express = require('express');

const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./admin.controller');

const adminOnly = [authMiddleware, roleMiddleware('admin')];

const missingHandler = (name) => (req, res) => {
  res.status(501).json({
    success: false,
    message: `Admin handler not implemented: ${name}`,
  });
};

const h = (name) => {
  return typeof controller[name] === 'function'
    ? controller[name]
    : missingHandler(name);
};

// Dashboard
router.get('/dashboard-summary', ...adminOnly, h('getDashboardSummary'));

// Analytics
router.get('/analytics/overview', ...adminOnly, h('getAnalyticsOverview'));
router.get('/analytics/user-growth', ...adminOnly, h('getUserGrowthAnalytics'));
router.get('/analytics/mentor-growth', ...adminOnly, h('getMentorGrowthAnalytics'));
router.get('/analytics/session-trends', ...adminOnly, h('getSessionTrendAnalytics'));
router.get('/analytics/top-careers', ...adminOnly, h('getTopCareersAnalytics'));
router.get('/analytics/top-skills', ...adminOnly, h('getTopSkillsAnalytics'));
router.get('/analytics/mentor-behavior', ...adminOnly, h('getMentorBehaviorAnalytics'));

// Users
router.get('/users', ...adminOnly, h('getUsers'));
router.get('/users/:userId', ...adminOnly, h('getUserDetails'));
router.patch('/users/:userId/status', ...adminOnly, validate(['isActive']), h('updateUserStatus'));

// Mentors
router.get('/mentors', ...adminOnly, h('getMentors'));
router.get('/mentors/:mentorProfileId', ...adminOnly, h('getMentorDetails'));
router.patch('/mentors/:mentorProfileId/status', ...adminOnly, h('updateMentorStatus'));

// Mentor Profiles
router.get('/mentor-profiles', ...adminOnly, h('getAllMentorProfiles'));
router.get('/mentor-profiles/pending', ...adminOnly, h('getPendingMentorProfiles'));
router.post('/mentor-profiles/:mentorProfileId/verify', ...adminOnly, h('verifyMentorProfile'));
router.post('/mentor-profiles/:mentorProfileId/unverify', ...adminOnly, h('unverifyMentorProfile'));

// Complaints
router.get('/complaints/open', ...adminOnly, h('getOpenComplaints'));
router.post('/complaints/:feedbackId/status', ...adminOnly, validate(['complaintStatus']), h('updateComplaintStatus'));

// Transactions
router.get('/transactions', ...adminOnly, h('getTransactions'));

// Careers
router.get('/careers', ...adminOnly, h('getCareers'));
router.get('/careers/:careerId', ...adminOnly, h('getCareerDetails'));
router.post('/careers', ...adminOnly, validate(['name']), h('createCareer'));
router.patch('/careers/:careerId', ...adminOnly, h('updateCareer'));
router.delete('/careers/:careerId', ...adminOnly, h('deleteCareer'));
router.get('/careers/:careerId/roadmap', ...adminOnly, h('getCareerRoadmap'));
router.patch(
  '/careers/:careerId/roadmap/steps/:stepId/resources',
  ...adminOnly,
  validate(['resources']),
  h('updateRoadmapStepResources')
);

// Mentor reliability / schedule requests
router.get('/mentor-cancellations/pending', ...adminOnly, h('getPendingMentorCancellations'));
router.post('/mentor-cancellations/:sessionId/review', ...adminOnly, validate(['reviewStatus']), h('reviewMentorCancellation'));
router.get('/mentor-activity-logs', ...adminOnly, h('getMentorActivityLogs'));
router.get('/schedule-change-requests/pending', ...adminOnly, h('getPendingScheduleChangeRequests'));
router.post('/schedule-change-requests/:requestId/approve', ...adminOnly, h('approveScheduleChangeRequest'));
router.post('/schedule-change-requests/:requestId/reject', ...adminOnly, h('rejectScheduleChangeRequest'));
router.get('/mentor-availability-exceptions', ...adminOnly, h('getMentorAvailabilityExceptions'));
router.get('/schedule-change-requests', ...adminOnly, h('getScheduleChangeRequests'));

module.exports = router;