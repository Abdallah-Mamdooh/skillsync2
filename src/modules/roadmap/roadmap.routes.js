const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middlewares/auth.middleware');
const controller = require('./roadmap.controller');

router.get('/my-roadmap', authMiddleware, controller.getMyRoadmap);

router.post('/complete-step', authMiddleware, controller.completeStep);

router.get('/progress', authMiddleware, controller.getProgress);

module.exports = router;