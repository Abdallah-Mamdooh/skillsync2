const MentorSession = require('./mentorSession.model');
const MentorProfile = require('./mentorProfile.model');
const paymentService = require('../payment/payment.service');
const notificationService = require('../notification/notification.service');
const User = require('../auth/user.model');
const Transaction = require('../payment/transaction.model');
const {
  validateBookingSlot,
  combineDateAndTime,
} = require('./mentorAvailability.service');

const PLATFORM_FEE_PERCENT = 0.2; // 20%

function round2(n) {
  return Math.round((Number(n) || 0) * 100) / 100;
}

function validateDuration(durationMinutes) {
  const d = Number(durationMinutes);

  if (!Number.isInteger(d)) {
    throw new Error('durationMinutes must be an integer');
  }

  if (d < 15 || d > 60) {
    throw new Error('durationMinutes must be between 15 and 60');
  }

  if (d % 5 !== 0) {
    throw new Error('durationMinutes must be in 5-minute increments');
  }

  return d;
}

function validateMethod(method) {
  const m = String(method || '').trim().toLowerCase();

  if (!['chat', 'call'].includes(m)) {
    throw new Error('method must be either chat or call');
  }

  return m;
}

function validateDate(date) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(String(date || ''))) {
    throw new Error('scheduledDate must be in YYYY-MM-DD format');
  }
  return String(date);
}

function validateTime(time) {
  if (!/^\d{2}:\d{2}$/.test(String(time || ''))) {
    throw new Error('scheduledStartTime must be in HH:mm format');
  }
  return String(time);
}

function calculatePricing(mentorProfile, method, durationMinutes) {
  const baseRate = Number(mentorProfile.baseRate || 0);
  const multiplier =
    method === 'call'
      ? Number(mentorProfile.callMultiplier || 1.5)
      : Number(mentorProfile.chatMultiplier || 1);

  const subtotal = round2(baseRate * durationMinutes * multiplier);
  const platformFee = round2(subtotal * PLATFORM_FEE_PERCENT);
  const totalAmount = subtotal;
  const mentorNetAmount = round2(totalAmount - platformFee);

  return {
    baseRate,
    multiplier,
    subtotal,
    platformFee,
    totalAmount,
    mentorNetAmount,
    currency: mentorProfile.currency || 'EGP',
  };
}

async function getMentorProfileForBooking(mentorProfileId, method) {
  const mentorProfile = await MentorProfile.findById(mentorProfileId).populate(
    'userId',
    'fullName email phoneNumber role'
  );

  if (!mentorProfile) {
    throw new Error('Mentor profile not found');
  }

  if (!mentorProfile.isVerified) {
    throw new Error('Mentor is not verified');
  }

  if (!mentorProfile.isAvailable) {
    throw new Error('Mentor is not available');
  }

  if (method === 'chat' && !mentorProfile.supportsChat) {
    throw new Error('This mentor does not support chat sessions');
  }

  if (method === 'call' && !mentorProfile.supportsCall) {
    throw new Error('This mentor does not support call sessions');
  }

  return mentorProfile;
}

async function buildValidatedBooking(userId, payload) {
  const mentorProfileId = payload.mentorProfileId;
  const method = validateMethod(payload.method);
  const durationMinutes = validateDuration(payload.durationMinutes);
  const scheduledDate = validateDate(payload.scheduledDate);
  const scheduledStartTime = validateTime(payload.scheduledStartTime);
  const userNotes = payload.userNotes || '';

  if (!mentorProfileId) {
    throw new Error('mentorProfileId is required');
  }

  const mentorProfile = await getMentorProfileForBooking(mentorProfileId, method);

  const slot = await validateBookingSlot({
    mentorProfileId,
    scheduledDate,
    scheduledStartTime,
    durationMinutes,
  });

  const pricing = calculatePricing(mentorProfile, method, durationMinutes);

  const startAt = combineDateAndTime(scheduledDate, slot.scheduledStartTime);
  const endAt = combineDateAndTime(scheduledDate, slot.scheduledEndTime);

  return {
    mentorProfile,
    method,
    durationMinutes,
    scheduledDate,
    scheduledStartTime: slot.scheduledStartTime,
    scheduledEndTime: slot.scheduledEndTime,
    timezone: slot.timezone,
    startAt,
    endAt,
    userNotes,
    pricing,
  };
}

const requestSession = async (userId, payload) => {
  const booking = await buildValidatedBooking(userId, payload);
  const defaultMethod = await paymentService.getDefaultPaymentMethod(userId);

  const session = await MentorSession.create({
    userId,
    mentorProfileId: booking.mentorProfile._id,
    mentorUserId: booking.mentorProfile.userId._id,
    method: booking.method,
    durationMinutes: booking.durationMinutes,
    scheduledDate: booking.scheduledDate,
    scheduledStartTime: booking.scheduledStartTime,
    scheduledEndTime: booking.scheduledEndTime,
    timezone: booking.timezone,
    startAt: booking.startAt,
    endAt: booking.endAt,
    baseRate: booking.pricing.baseRate,
    multiplier: booking.pricing.multiplier,
    subtotal: booking.pricing.subtotal,
    platformFee: booking.pricing.platformFee,
    totalAmount: booking.pricing.totalAmount,
    mentorNetAmount: booking.pricing.mentorNetAmount,
    currency: booking.pricing.currency,
    status: 'scheduled',
    paymentStatus: 'hold_pending',
    requestedAt: new Date(),
    userNotes: booking.userNotes,
  });

  await paymentService.holdFunds({
    userId,
    sessionId: session._id,
    amount: booking.pricing.totalAmount,
    paymentMethodId: defaultMethod?._id || null,
    currency: booking.pricing.currency,
  });

  session.paymentStatus = 'held';
  await session.save();

  await notificationService.createNotification({
    userId: booking.mentorProfile.userId._id,
    type: 'mentor_session_booked',
    title: 'New booked session',
    message: `A new ${booking.method} session was booked for ${booking.scheduledDate} at ${booking.scheduledStartTime}.`,
    data: {
      sessionId: session._id,
      mentorProfileId: booking.mentorProfile._id,
      method: booking.method,
      durationMinutes: booking.durationMinutes,
      scheduledDate: booking.scheduledDate,
      scheduledStartTime: booking.scheduledStartTime,
      scheduledEndTime: booking.scheduledEndTime,
      totalAmount: booking.pricing.totalAmount,
      currency: booking.pricing.currency,
    },
  });

  await notificationService.createNotification({
    userId,
    type: 'payment_held',
    title: 'Payment placed on hold',
    message: `An amount of ${booking.pricing.totalAmount} ${booking.pricing.currency} was placed on hold for your booked session.`,
    data: {
      sessionId: session._id,
      amount: booking.pricing.totalAmount,
      currency: booking.pricing.currency,
      paymentStatus: 'held',
    },
  });

  return {
    sessionId: session._id,
    mentor: {
      id: booking.mentorProfile._id,
      userId: booking.mentorProfile.userId._id,
      fullName: booking.mentorProfile.userId.fullName,
      email: booking.mentorProfile.userId.email,
    },
    method: session.method,
    durationMinutes: session.durationMinutes,
    scheduledDate: session.scheduledDate,
    scheduledStartTime: session.scheduledStartTime,
    scheduledEndTime: session.scheduledEndTime,
    timezone: session.timezone,
    pricing: booking.pricing,
    status: session.status,
    paymentStatus: session.paymentStatus,
  };
};

const createSessionFawryCheckout = async (userId, payload) => {
  const booking = await buildValidatedBooking(userId, payload);

  const session = await MentorSession.create({
    userId,
    mentorProfileId: booking.mentorProfile._id,
    mentorUserId: booking.mentorProfile.userId._id,
    method: booking.method,
    durationMinutes: booking.durationMinutes,
    scheduledDate: booking.scheduledDate,
    scheduledStartTime: booking.scheduledStartTime,
    scheduledEndTime: booking.scheduledEndTime,
    timezone: booking.timezone,
    startAt: booking.startAt,
    endAt: booking.endAt,
    baseRate: booking.pricing.baseRate,
    multiplier: booking.pricing.multiplier,
    subtotal: booking.pricing.subtotal,
    platformFee: booking.pricing.platformFee,
    totalAmount: booking.pricing.totalAmount,
    mentorNetAmount: booking.pricing.mentorNetAmount,
    currency: booking.pricing.currency,
    status: 'scheduled',
    paymentStatus: 'hold_pending',
    requestedAt: new Date(),
    userNotes: booking.userNotes,
  });

  const user = await User.findById(userId).select(
    'fullName email phoneNumber'
  );

  if (!user) {
    throw new Error('User not found');
  }

  const checkout = await paymentService.createFawryCheckout({
    user: {
      _id: user._id,
      fullName: user.fullName,
      email: user.email,
      phoneNumber: user.phoneNumber,
    },
    amount: booking.pricing.totalAmount,
    purpose: 'hold',
    entityType: 'mentor_session',
    entityId: session._id,
    description: `Mentor session payment - ${booking.method} - ${booking.durationMinutes} minutes`,
    paymentMethod: payload.paymentMethod || '',
  });

  await notificationService.createNotification({
    userId: booking.mentorProfile.userId._id,
    type: 'mentor_session_booked',
    title: 'New booked session',
    message: `A new ${booking.method} session was booked for ${booking.scheduledDate} at ${booking.scheduledStartTime}.`,
    data: {
      sessionId: session._id,
      mentorProfileId: booking.mentorProfile._id,
      method: booking.method,
      durationMinutes: booking.durationMinutes,
      scheduledDate: booking.scheduledDate,
      scheduledStartTime: booking.scheduledStartTime,
      scheduledEndTime: booking.scheduledEndTime,
      totalAmount: booking.pricing.totalAmount,
      currency: booking.pricing.currency,
    },
  });

  return {
    sessionId: session._id,
    mentor: {
      id: booking.mentorProfile._id,
      userId: booking.mentorProfile.userId._id,
      fullName: booking.mentorProfile.userId.fullName,
      email: booking.mentorProfile.userId.email,
    },
    method: session.method,
    durationMinutes: session.durationMinutes,
    scheduledDate: session.scheduledDate,
    scheduledStartTime: session.scheduledStartTime,
    scheduledEndTime: session.scheduledEndTime,
    timezone: session.timezone,
    pricing: booking.pricing,
    status: session.status,
    paymentStatus: session.paymentStatus,
    checkout,
  };
};

// keep these existing list/detail methods, but include scheduled timing
const getMySessions = async (userId) => {
  const sessions = await MentorSession.find({ userId })
    .populate('mentorProfileId')
    .populate('mentorUserId', 'fullName email phoneNumber')
    .sort({ createdAt: -1 });

  return sessions.map((s) => ({
    id: s._id,
    mentor: {
      profileId: s.mentorProfileId?._id || null,
      userId: s.mentorUserId?._id || null,
      fullName: s.mentorUserId?.fullName || '',
      email: s.mentorUserId?.email || '',
      phoneNumber: s.mentorUserId?.phoneNumber || '',
      headline: s.mentorProfileId?.headline || '',
      specialization: s.mentorProfileId?.specialization || [],
    },
    method: s.method,
    durationMinutes: s.durationMinutes,
    scheduledDate: s.scheduledDate,
    scheduledStartTime: s.scheduledStartTime,
    scheduledEndTime: s.scheduledEndTime,
    timezone: s.timezone,
    totalAmount: s.totalAmount,
    currency: s.currency,
    status: s.status,
    paymentStatus: s.paymentStatus,
    requestedAt: s.requestedAt,
    startedAt: s.startedAt,
    endedAt: s.endedAt,
    meetingProvider: s.meetingProvider,
    meetingLink: s.meetingLink,
    userNotes: s.userNotes,
  }));
};

const getMentorIncomingSessions = async (mentorUserId) => {
  const mentorProfile = await MentorProfile.findOne({ userId: mentorUserId });

  if (!mentorProfile) {
    throw new Error('Mentor profile not found');
  }

  const sessions = await MentorSession.find({
    mentorProfileId: mentorProfile._id,
    status: { $in: ['scheduled', 'started', 'active'] },
  })
    .populate('userId', 'fullName email phoneNumber role skills cvUrl')
    .sort({ scheduledDate: 1, scheduledStartTime: 1 });

  return sessions.map((s) => ({
    id: s._id,
    requester: {
      id: s.userId?._id || null,
      fullName: s.userId?.fullName || '',
      email: s.userId?.email || '',
      phoneNumber: s.userId?.phoneNumber || '',
      role: s.userId?.role || '',
      skills: s.userId?.skills || [],
      cvUrl: s.userId?.cvUrl || '',
    },
    method: s.method,
    durationMinutes: s.durationMinutes,
    scheduledDate: s.scheduledDate,
    scheduledStartTime: s.scheduledStartTime,
    scheduledEndTime: s.scheduledEndTime,
    timezone: s.timezone,
    totalAmount: s.totalAmount,
    currency: s.currency,
    status: s.status,
    paymentStatus: s.paymentStatus,
    requestedAt: s.requestedAt,
    userNotes: s.userNotes,
  }));
};

const getSessionById = async (sessionId, currentUserId) => {
  const session = await MentorSession.findById(sessionId)
    .populate('userId', 'fullName email phoneNumber role skills cvUrl')
    .populate('mentorUserId', 'fullName email phoneNumber')
    .populate('mentorProfileId');

  if (!session) {
    throw new Error('Session not found');
  }

  const isRequester = String(session.userId?._id) === String(currentUserId);
  const isMentor = String(session.mentorUserId?._id) === String(currentUserId);

  if (!isRequester && !isMentor) {
    throw new Error('You are not authorized to view this session');
  }

  return {
    id: session._id,
    requester: {
      id: session.userId?._id || null,
      fullName: session.userId?.fullName || '',
      email: session.userId?.email || '',
      phoneNumber: session.userId?.phoneNumber || '',
      role: session.userId?.role || '',
      skills: session.userId?.skills || [],
      cvUrl: session.userId?.cvUrl || '',
    },
    mentor: {
      profileId: session.mentorProfileId?._id || null,
      userId: session.mentorUserId?._id || null,
      fullName: session.mentorUserId?.fullName || '',
      email: session.mentorUserId?.email || '',
      phoneNumber: session.mentorUserId?.phoneNumber || '',
      headline: session.mentorProfileId?.headline || '',
      specialization: session.mentorProfileId?.specialization || [],
      isVerified: session.mentorProfileId?.isVerified || false,
    },
    method: session.method,
    durationMinutes: session.durationMinutes,
    scheduledDate: session.scheduledDate,
    scheduledStartTime: session.scheduledStartTime,
    scheduledEndTime: session.scheduledEndTime,
    timezone: session.timezone,
    startAt: session.startAt,
    endAt: session.endAt,
    noShowDeadline: session.noShowDeadline,
    baseRate: session.baseRate,
    multiplier: session.multiplier,
    subtotal: session.subtotal,
    platformFee: session.platformFee,
    totalAmount: session.totalAmount,
    mentorNetAmount: session.mentorNetAmount,
    currency: session.currency,
    status: session.status,
    paymentStatus: session.paymentStatus,
    requestedAt: session.requestedAt,
    acceptedAt: session.acceptedAt,
    startedAt: session.startedAt,
    endedAt: session.endedAt,
    meetingProvider: session.meetingProvider,
    meetingLink: session.meetingLink,
    chatRoomId: session.chatRoomId,
    userNotes: session.userNotes,
  };
};

// keep old methods for now; lifecycle will be rewritten in the next batch
const acceptSession = async () => {
  throw new Error('Session accept is disabled in the new booking flow');
};

const rejectSession = async () => {
  throw new Error('Session reject is disabled in the new booking flow');
};

const completeSession = async () => {
  throw new Error('Manual complete will be handled in the next lifecycle update');
};

const startSession = async () => {
  throw new Error('Session start will be rewritten in the next lifecycle update');
};

const expirePendingSessions = async () => {
  return { expiredCount: 0 };
};

module.exports = {
  requestSession,
  getMySessions,
  getMentorIncomingSessions,
  getSessionById,
  acceptSession,
  rejectSession,
  completeSession,
  startSession,
  expirePendingSessions,
  createSessionFawryCheckout,
};