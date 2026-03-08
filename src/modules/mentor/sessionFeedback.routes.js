const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const controller = require('./sessionFeedback.controller');

// user side
router.post('/', authMiddleware, controller.submitSessionFeedback);
router.get('/session/:sessionId', authMiddleware, controller.getMyFeedbackForSession);

// mentor side
router.get('/mentor/summary', authMiddleware, controller.getMentorFeedbackSummary);
router.get('/mentor/complaints', authMiddleware, controller.getOpenComplaints);

module.exports = router;