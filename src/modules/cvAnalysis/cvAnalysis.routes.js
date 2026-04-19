const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const { cvUpload } = require('../../middlewares/upload.middleware');
const controller = require('./cvAnalysis.controller');

router.post(
  '/analyze',
  authMiddleware,
  cvUpload.single('file'),
  controller.analyzeMyCv
);

router.get(
  '/me/latest',
  authMiddleware,
  controller.getLatestMyCvAnalysis
);

router.get(
  '/me/history',
  authMiddleware,
  controller.getMyCvAnalysisHistory
);

module.exports = router;