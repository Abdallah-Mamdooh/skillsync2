const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const controller = require('./settings.controller');

// user settings
router.get('/me', authMiddleware, controller.getMySettings);
router.patch('/me', authMiddleware, controller.updateMySettings);

// app settings (admin only)
router.get(
  '/app',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getAppSettings
);

router.patch(
  '/app',
  authMiddleware,
  roleMiddleware('admin'),
  controller.updateAppSettings
);

module.exports = router;