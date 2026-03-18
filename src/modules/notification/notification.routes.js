const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const controller = require('./notification.controller');

router.get('/me', authMiddleware, controller.getMyNotifications);

router.patch(
  '/:notificationId/read',
  authMiddleware,
  controller.markNotificationAsRead
);

router.patch(
  '/read-all',
  authMiddleware,
  controller.markAllNotificationsAsRead
);

module.exports = router;