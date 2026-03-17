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

module.exports = router;