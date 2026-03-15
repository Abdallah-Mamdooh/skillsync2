const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./admin.controller');

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

module.exports = router;