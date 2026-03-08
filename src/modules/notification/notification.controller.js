const asyncHandler = require('../../middlewares/async.middleware');
const notificationService = require('./notification.service');

const getMyNotifications = asyncHandler(async (req, res) => {
  const data = await notificationService.getMyNotifications(req.user._id);

  res.status(200).json({
    success: true,
    data,
  });
});

const getUnreadCount = asyncHandler(async (req, res) => {
  const data = await notificationService.getUnreadCount(req.user._id);

  res.status(200).json({
    success: true,
    data: { unreadCount: data },
  });
});

const markAsRead = asyncHandler(async (req, res) => {
  const data = await notificationService.markAsRead(
    req.user._id,
    req.params.notificationId
  );

  res.status(200).json({
    success: true,
    data,
  });
});

const markAllAsRead = asyncHandler(async (req, res) => {
  const data = await notificationService.markAllAsRead(req.user._id);

  res.status(200).json({
    success: true,
    data,
  });
});

module.exports = {
  getMyNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
};