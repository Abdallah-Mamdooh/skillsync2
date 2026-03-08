const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const controller = require('./mentorSession.controller');

// user side
router.post('/', authMiddleware, controller.requestSession);
router.get('/me', authMiddleware, controller.getMySessions);

// mentor side
router.get('/incoming', authMiddleware, controller.getMentorIncomingSessions);

// shared details
router.get('/:sessionId', authMiddleware, controller.getSessionById);

// mentor actions
router.post('/:sessionId/accept', authMiddleware, controller.acceptSession);
router.post('/:sessionId/reject', authMiddleware, controller.rejectSession);

module.exports = router;