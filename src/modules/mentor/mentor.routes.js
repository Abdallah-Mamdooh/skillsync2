const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const controller = require('./mentor.controller');

// public mentor listing/details
router.get('/public', controller.getPublicMentors);
router.get('/public/:mentorId', controller.getMentorById);

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

module.exports = router;