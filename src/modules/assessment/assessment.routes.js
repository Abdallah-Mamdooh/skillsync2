const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middlewares/auth.middleware');
const controller = require('./assessment.controller');

router.get('/sections', authMiddleware, controller.getSections);

router.get(
  '/questions/:sectionId',
  authMiddleware,
  controller.getQuestionsBySection
);

router.post(
  '/submit',
  authMiddleware,
  controller.submitAssessment
);



router.post(
  '/choose-career',
  authMiddleware,
  controller.chooseCareer
);

module.exports = router;
