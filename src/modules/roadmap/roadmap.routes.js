const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middlewares/auth.middleware');
const controller = require('./roadmap.controller');

router.get('/my-roadmap', authMiddleware, controller.getMyRoadmap);
router.post('/toggle-step', authMiddleware, controller.toggleStep);
router.get('/progress', authMiddleware, controller.getProgress);
router.post('/generate-resources', authMiddleware, controller.generateResources);

// ✅ new
router.get('/recent-completions', authMiddleware, controller.getRecentCompletions);

module.exports = router;