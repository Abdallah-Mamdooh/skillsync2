const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middlewares/auth.middleware');
const controller = require('./roadmap.controller');

router.get('/my-roadmap', authMiddleware, controller.getUserRoadmap);

router.post('/complete-step', authMiddleware, controller.completeStep);

router.get('/progress', authMiddleware, controller.getProgressPercentage);

module.exports = router;
