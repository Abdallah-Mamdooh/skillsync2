const Notification = require('./notification.model');

const NOTIFICATION_TYPES = {
  // auth / account
  ACCOUNT_STATUS_UPDATED: 'account_status_updated',
  PASSWORD_RESET_REQUESTED: 'password_reset_requested',
  PASSWORD_CHANGED: 'password_changed',

  // roadmap / assessment
  ASSESSMENT_COMPLETED: 'assessment_completed',
  CAREER_SELECTED: 'career_selected',
  ROADMAP_STEP_COMPLETED: 'roadmap_step_completed',
  ROADMAP_STEP_UNCOMPLETED: 'roadmap_step_uncompleted',
  SKILL_ADDED: 'skill_added',

  // mentor sessions
  MENTOR_SESSION_BOOKED: 'mentor_session_booked',
  MENTOR_SESSION_STARTED: 'mentor_session_started',
  USER_JOINED_SESSION: 'user_joined_session',
  MENTOR_SESSION_COMPLETED: 'mentor_session_completed',
  MENTOR_SESSION_CANCELLED: 'mentor_session_cancelled',
  MENTOR_SESSION_USER_NO_SHOW: 'mentor_session_user_no_show',
  MENTOR_PAYOUT_COMPLETED: 'mentor_payout_completed',
  MENTOR_PAYOUT_REVERSED: 'mentor_payout_reversed',

  // chat
  CHAT_MESSAGE_RECEIVED: 'chat_message_received',

  // payments
  PAYMENT_HELD: 'payment_held',
  PAYMENT_CAPTURED: 'payment_captured',
  PAYMENT_RELEASED: 'payment_released',
  PAYMENT_REFUNDED: 'payment_refunded',
  PAYMENT_FAILED: 'payment_failed',

  // events
  EVENT_PUBLISHED: 'event_published',
  EVENT_REGISTERED: 'event_registered',
  EVENT_PAYMENT_CAPTURED: 'event_payment_captured',
  EVENT_PAYMENT_RELEASED: 'event_payment_released',
  EVENT_CANCELLED: 'event_cancelled',
  EVENT_COMPLETED: 'event_completed',

  // admin / mentor verification
  MENTOR_VERIFIED: 'mentor_verified',
  MENTOR_UNVERIFIED: 'mentor_unverified',
  MENTOR_STATUS_UPDATED: 'mentor_status_updated',

  // complaints
  COMPLAINT_SUBMITTED: 'complaint_submitted',
  COMPLAINT_STATUS_UPDATED: 'complaint_status_updated',

  // misc
  GENERAL: 'general',
};

async function createNotification({
  userId,
  type,
  title,
  message,
  data = {},
}) {
  if (!userId) {
    throw new Error('userId is required');
  }

  if (!type) {
    throw new Error('type is required');
  }

  if (!title) {
    throw new Error('title is required');
  }

  if (!message) {
    throw new Error('message is required');
  }

  return Notification.create({
    userId,
    type,
    title,
    message,
    data,
    isRead: false,
    readAt: null,
  });
}

async function createManyNotifications(items = []) {
  if (!Array.isArray(items) || items.length === 0) {
    return [];
  }

  const docs = items.map((item) => {
    if (!item.userId || !item.type || !item.title || !item.message) {
      throw new Error(
        'Each notification item must include userId, type, title, and message'
      );
    }

    return {
      userId: item.userId,
      type: item.type,
      title: item.title,
      message: item.message,
      data: item.data || {},
      isRead: false,
      readAt: null,
    };
  });

  return Notification.insertMany(docs);
}

async function getMyNotifications(userId, query = {}) {
  const {
    isRead = '',
    type = '',
    page = 1,
    limit = 20,
  } = query;

  const filters = { userId };

  if (isRead !== '') {
    filters.isRead = String(isRead) === 'true';
  }

  if (type) {
    filters.type = type;
  }

  const skip = (Number(page) - 1) * Number(limit);

  const [items, total, unreadCount] = await Promise.all([
    Notification.find(filters)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(Number(limit)),
    Notification.countDocuments(filters),
    Notification.countDocuments({ userId, isRead: false }),
  ]);

  return {
    items,
    unreadCount,
    pagination: {
      page: Number(page),
      limit: Number(limit),
      total,
      pages: Math.ceil(total / Number(limit)),
    },
  };
}

async function markAsRead(userId, notificationId) {
  const notification = await Notification.findOne({
    _id: notificationId,
    userId,
  });

  if (!notification) {
    throw new Error('Notification not found');
  }

  if (!notification.isRead) {
    notification.isRead = true;
    notification.readAt = new Date();
    await notification.save();
  }

  return notification;
}

async function markAllAsRead(userId) {
  const result = await Notification.updateMany(
    {
      userId,
      isRead: false,
    },
    {
      $set: {
        isRead: true,
        readAt: new Date(),
      },
    }
  );

  return {
    modifiedCount: result.modifiedCount || 0,
  };
}

module.exports = {
  NOTIFICATION_TYPES,
  createNotification,
  createManyNotifications,
  getMyNotifications,
  markAsRead,
  markAllAsRead,
};