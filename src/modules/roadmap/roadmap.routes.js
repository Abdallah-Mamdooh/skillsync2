const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middlewares/auth.middleware');
const controller = require('./roadmap.controller');

router.get('/my-roadmap', authMiddleware, controller.getMyRoadmap);

router.post('/complete-step', authMiddleware, controller.completeStep);
router.post('/toggle-step', authMiddleware, controller.toggleStep);

router.get('/progress', authMiddleware, controller.getProgress);

// ✅ NEW: generate resources for current roadmap
router.post('/generate-resources', authMiddleware, controller.generateResources);

module.exports = router;