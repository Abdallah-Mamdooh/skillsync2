const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const controller = require('./mentor.controller');

// public mentor listing/details
router.get('/public', controller.getPublicMentors);
router.get('/public/:mentorId', controller.getMentorById);

// mentor's own profile
router.post('/me', authMiddleware, controller.createMentorProfile);
router.put('/me', authMiddleware, controller.updateMentorProfile);
router.get('/me', authMiddleware, controller.getMyMentorProfile);

module.exports = router;