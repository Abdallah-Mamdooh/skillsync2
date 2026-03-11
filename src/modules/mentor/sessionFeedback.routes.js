const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./sessionFeedback.controller');

// user side
router.post(
  '/',
  authMiddleware,
  roleMiddleware('user'),
  validate(['sessionId', 'mentorRating', 'appRating', 'sessionRating']),
  controller.submitSessionFeedback
);

router.get(
  '/session/:sessionId',
  authMiddleware,
  roleMiddleware('user'),
  controller.getMyFeedbackForSession
);

// mentor side
router.get(
  '/mentor/summary',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.getMentorFeedbackSummary
);

router.get(
  '/mentor/complaints',
  authMiddleware,
  roleMiddleware('mentor'),
  controller.getOpenComplaints
);

module.exports = router;