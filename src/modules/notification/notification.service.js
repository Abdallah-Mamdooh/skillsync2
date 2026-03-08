const Notification = require('./notification.model');

const createNotification = async ({ userId, type, title, message, data = {} }) => {
  return Notification.create({
    userId,
    type,
    title,
    message,
    data,
  });
};

const getMyNotifications = async (userId) => {
  return Notification.find({ userId }).sort({ createdAt: -1 });
};

const getUnreadCount = async (userId) => {
  return Notification.countDocuments({
    userId,
    isRead: false,
  });
};

const markAsRead = async (userId, notificationId) => {
  const notification = await Notification.findOne({
    _id: notificationId,
    userId,
  });

  if (!notification) {
    throw new Error('Notification not found');
  }

  notification.isRead = true;
  await notification.save();

  return notification;
};

const markAllAsRead = async (userId) => {
  await Notification.updateMany(
    { userId, isRead: false },
    { $set: { isRead: true } }
  );

  return { message: 'All notifications marked as read' };
};

module.exports = {
  createNotification,
  getMyNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
};