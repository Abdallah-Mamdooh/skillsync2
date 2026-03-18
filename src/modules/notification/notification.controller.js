const asyncHandler = require('../../middlewares/async.middleware');
const notificationService = require('./notification.service');

const getMyNotifications = asyncHandler(async (req, res) => {
  const data = await notificationService.getMyNotifications(
    req.user._id,
    req.query
  );

  res.status(200).json({
    success: true,
    data,
  });
});

const markNotificationAsRead = asyncHandler(async (req, res) => {
  const data = await notificationService.markAsRead(
    req.user._id,
    req.params.notificationId
  );

  res.status(200).json({
    success: true,
    data,
  });
});

const markAllNotificationsAsRead = asyncHandler(async (req, res) => {
  const data = await notificationService.markAllAsRead(req.user._id);

  res.status(200).json({
    success: true,
    data,
  });
});

module.exports = {
  getMyNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead,
};