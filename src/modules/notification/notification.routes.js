const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const controller = require('./notification.controller');

router.get('/me', authMiddleware, controller.getMyNotifications);
router.get('/me/unread-count', authMiddleware, controller.getUnreadCount);
router.post('/:notificationId/read', authMiddleware, controller.markAsRead);
router.post('/me/read-all', authMiddleware, controller.markAllAsRead);

module.exports = router;