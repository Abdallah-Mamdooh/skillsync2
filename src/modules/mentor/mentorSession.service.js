const MentorSession = require('./mentorSession.model');
const MentorProfile = require('./mentorProfile.model');
const User = require('../auth/user.model');
const paymentService = require('../payment/payment.service');
const notificationService = require('../notification/notification.service');
const {
  validateBookingSlot,
  combineDateAndTime,
} = require('./mentorAvailability.service');

const PLATFORM_FEE_PERCENT = 0.2;
const USER_JOIN_GRACE_MINUTES = 5;

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

function addMinutes(date, minutes) {
  return new Date(date.getTime() + minutes * 60 * 1000);
}

function getNow() {
  return new Date();
}

function calculateActualDurationMinutes(startedAt, endedAt) {
  if (!startedAt || !endedAt) return 0;
  const diffMs = new Date(endedAt).getTime() - new Date(startedAt).getTime();
  if (diffMs <= 0) return 0;
  return Math.round(diffMs / 60000);
}

function calculatePricing(mentorProfile, method, durationMinutes) {
  const hourlyRate = Number(mentorProfile.baseRate || 0);
  const multiplier =
    method === 'call'
      ? Number(mentorProfile.callMultiplier || 1.5)
      : Number(mentorProfile.chatMultiplier || 1);

  const subtotal = round2((hourlyRate / 60) * durationMinutes * multiplier);
  const platformFee = round2(subtotal * PLATFORM_FEE_PERCENT);
  const totalAmount = subtotal;
  const mentorNetAmount = round2(totalAmount - platformFee);

  return {
    baseRate: hourlyRate,
    multiplier,
    subtotal,
    platformFee,
    totalAmount,
    mentorNetAmount,
    currency: mentorProfile.currency || 'EGP',
  };
}

function buildTimerInfo(session) {
  const now = getNow();
  const timerStarted = Boolean(session.startedAt && session.endAt);

  const endAt = timerStarted ? new Date(session.endAt) : null;
  const noShowDeadline = session.noShowDeadline
    ? new Date(session.noShowDeadline)
    : null;

  const remainingSessionSeconds = endAt
    ? Math.max(0, Math.floor((endAt.getTime() - now.getTime()) / 1000))
    : null;

  const remainingJoinGraceSeconds = noShowDeadline
    ? Math.max(0, Math.floor((noShowDeadline.getTime() - now.getTime()) / 1000))
    : null;

  return {
    startedAt: session.startedAt,
    endAt: timerStarted ? session.endAt : null,
    noShowDeadline: session.noShowDeadline,
    remainingSessionSeconds,
    remainingJoinGraceSeconds,
    timerStarted,
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

async function createScheduledSessionFromBooking(userId, booking) {
  return MentorSession.create({
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
}

async function settleSessionPayout(session, finalizationReason) {
  if (!session) {
    throw new Error('Session is required for settlement');
  }

  if (!['held', 'captured'].includes(session.paymentStatus)) {
    return session;
  }

  if (session.paymentStatus === 'held') {
    await paymentService.captureHeldFunds({
      userId: session.userId,
      sessionId: session._id,
      amount: session.totalAmount,
      currency: session.currency,
    });

    session.paymentStatus = 'captured';
  }

  if (!session.payoutTransferred) {
    await paymentService.creditMentorWallet({
      mentorUserId: session.mentorUserId,
      sessionId: session._id,
      amount: session.mentorNetAmount,
      currency: session.currency,
      reason: finalizationReason,
    });

    session.payoutTransferred = true;
  }

  if (!session.platformFeeLogged && Number(session.platformFee || 0) > 0) {
    await paymentService.addPlatformFeeTransaction({
      userId: session.userId,
      sessionId: session._id,
      amount: session.platformFee,
      currency: session.currency,
      notes: `Platform fee for mentor session ${session._id}`,
    });

    session.platformFeeLogged = true;
  }

  return session;
}

async function releaseSessionHold(session, reason = 'cancelled') {
  if (!session) {
    throw new Error('Session is required for hold release');
  }

  if (session.paymentStatus === 'held') {
    await paymentService.releaseHeldFunds({
      userId: session.userId,
      sessionId: session._id,
      amount: session.totalAmount,
      currency: session.currency,
      reason,
    });

    session.paymentStatus = 'released';
  }

  return session;
}

async function assertSessionParticipant(sessionId, currentUserId) {
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
    throw new Error('You are not authorized to access this session');
  }

  return { session, isRequester, isMentor };
}

async function requestSession(userId, payload) {
  const booking = await buildValidatedBooking(userId, payload);
  const defaultMethod = await paymentService.getDefaultPaymentMethod(userId);

  const session = await createScheduledSessionFromBooking(userId, booking);

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
}

async function createSessionFawryCheckout(userId, payload) {
  const booking = await buildValidatedBooking(userId, payload);

  const session = await createScheduledSessionFromBooking(userId, booking);

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
}
async function createSessionPaymobCheckout(userId, payload) {
  const booking = await buildValidatedBooking(userId, payload);

  const session = await createScheduledSessionFromBooking(userId, booking);

  const user = await User.findById(userId).select(
    'fullName email phoneNumber'
  );

  if (!user) {
    throw new Error('User not found');
  }

  const checkout = await paymentService.createPaymobCheckout({
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
    paymentMethods: payload.paymentMethods || [],
    sessionId: session._id,
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
}

async function getMySessions(userId) {
  const sessions = await MentorSession.find({ userId })
    .populate('mentorProfileId')
    .populate('mentorUserId', 'fullName email phoneNumber')
    .sort({ scheduledDate: -1, scheduledStartTime: -1, createdAt: -1 });

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
    timer: buildTimerInfo(s),
  }));
}

async function getMentorIncomingSessions(mentorUserId) {
  const mentorProfile = await MentorProfile.findOne({ userId: mentorUserId });

  if (!mentorProfile) {
    throw new Error('Mentor profile not found');
  }

  const sessions = await MentorSession.find({
    mentorProfileId: mentorProfile._id,
    status: { $in: ['scheduled', 'started', 'active'] },
    paymentStatus: { $in: ['held', 'captured'] }
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
    startedAt: s.startedAt,
    userJoinedAt: s.userJoinedAt,
    noShowDeadline: s.noShowDeadline,
    userNotes: s.userNotes,
    timer: buildTimerInfo(s),
  }));
}

async function getSessionById(sessionId, currentUserId) {
  const { session } = await assertSessionParticipant(sessionId, currentUserId);

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
    userJoinedAt: session.userJoinedAt,
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
    timer: buildTimerInfo(session),
  };
}

async function startSession(mentorUserId, sessionId) {
  const session = await MentorSession.findById(sessionId)
    .populate('userId', 'fullName')
    .populate('mentorUserId', 'fullName');

  if (!session) {
    throw new Error('Session not found');
  }

  if (String(session.mentorUserId?._id || session.mentorUserId) !== String(mentorUserId)) {
    throw new Error('Only the mentor can start this session');
  }

  if (session.status !== 'scheduled') {
    throw new Error('Only scheduled sessions can be started');
  }

  if (!['held', 'captured'].includes(session.paymentStatus)) {
    throw new Error('Payment must be held before starting the session');
  }

  const now = getNow();

  session.acceptedAt = now;

  // IMPORTANT:
  // Do NOT start timer here.
  // Timer starts on the first real chat message.
  session.startedAt = null;
  session.startAt = null;
  session.endAt = null;

  // mentor opens the session and user gets 5 minutes to join
  session.noShowDeadline = addMinutes(now, USER_JOIN_GRACE_MINUTES);
  session.status = 'started';

  await session.save();

  await notificationService.createNotification({
    userId: session.userId._id || session.userId,
    type: 'mentor_session_started',
    title: 'Session started',
    message: `${session.mentorUserId?.fullName || 'Your mentor'} started the session. Join now.`,
    data: {
      sessionId: session._id,
      noShowDeadline: session.noShowDeadline,
      durationMinutes: session.durationMinutes,
      timerStartsOnFirstMessage: true,
    },
  });

  return {
    sessionId: session._id,
    status: session.status,
    startedAt: session.startedAt,
    noShowDeadline: session.noShowDeadline,
    endAt: session.endAt,
    timerStartsOnFirstMessage: true,
    timer: buildTimerInfo(session),
  };
}

async function joinSession(userId, sessionId) {
  const { session, isRequester } = await assertSessionParticipant(sessionId, userId);

  if (!isRequester) {
    throw new Error('Only the user can join the session');
  }

  if (!['started', 'active'].includes(session.status)) {
    throw new Error('This session is not open for joining');
  }

  if (
    session.noShowDeadline &&
    !session.userJoinedAt &&
    new Date() > new Date(session.noShowDeadline)
  ) {
    throw new Error('The join window has expired');
  }

  let timerStartedNow = false;

  if (!session.userJoinedAt) {
    session.userJoinedAt = getNow();
  }

  // For CALL sessions, joining starts the real session timer
  if (session.method === 'call' && !session.startedAt) {
    const now = getNow();
    session.startedAt = now;
    session.startAt = now;
    session.endAt = addMinutes(now, session.durationMinutes);
    timerStartedNow = true;
  }

  session.status = 'active';
  await session.save();

  await notificationService.createNotification({
    userId: session.mentorUserId._id || session.mentorUserId,
    type: 'user_joined_session',
    title: 'User joined session',
    message: `${session.userId?.fullName || 'The user'} joined the session.`,
    data: {
      sessionId: session._id,
      userJoinedAt: session.userJoinedAt,
      timerStartedNow,
      method: session.method,
    },
  });

  return {
    sessionId: session._id,
    status: session.status,
    userJoinedAt: session.userJoinedAt,
    timerStartedNow,
    timer: buildTimerInfo(session),
  };
}

async function finalizeSession(session, finalizationReason, options = {}) {
  const now = getNow();

  if (['completed', 'cancelled', 'expired', 'user_no_show'].includes(session.status) && session.payoutTransferred) {
    return session;
  }

  if (finalizationReason === 'user_no_show') {
    session.status = 'user_no_show';
    session.finalizationReason = 'user_no_show';
    session.endedAt = session.noShowDeadline || now;
    session.actualDurationMinutes = 0;
  } else if (finalizationReason === 'cancelled') {
    session.status = 'cancelled';
    session.finalizationReason = 'cancelled';
    session.endedAt = now;
    session.actualDurationMinutes = 0;
  } else {
    session.status = 'completed';
    session.finalizationReason =
      finalizationReason === 'manual_complete' ? 'manual_complete' : 'normal_end';
    session.endedAt = options.endedAt || now;
    session.actualDurationMinutes = calculateActualDurationMinutes(
      session.startedAt,
      session.endedAt
    );
  }

  if (finalizationReason === 'cancelled') {
    await releaseSessionHold(session, 'cancelled');
  } else {
    await settleSessionPayout(session, finalizationReason);
  }

  await session.save();

  if (session.status === 'completed') {
    await notificationService.createNotification({
      userId: session.userId,
      type: 'mentor_session_completed',
      title: 'Session completed',
      message: 'Your mentor session has been completed successfully.',
      data: {
        sessionId: session._id,
        endedAt: session.endedAt,
        paymentStatus: session.paymentStatus,
      },
    });

    await notificationService.createNotification({
      userId: session.mentorUserId,
      type: 'mentor_payout_completed',
      title: 'Mentor payout completed',
      message: `${session.mentorNetAmount} ${session.currency} was transferred to your wallet.`,
      data: {
        sessionId: session._id,
        mentorNetAmount: session.mentorNetAmount,
        currency: session.currency,
      },
    });
  }

  if (session.status === 'user_no_show') {
    await notificationService.createNotification({
      userId: session.userId,
      type: 'mentor_session_user_no_show',
      title: 'Session ended due to no-show',
      message:
        'You did not join the session within 5 minutes after the mentor started. The payment is not refundable.',
      data: {
        sessionId: session._id,
        noShowDeadline: session.noShowDeadline,
      },
    });

    await notificationService.createNotification({
      userId: session.mentorUserId,
      type: 'mentor_session_user_no_show',
      title: 'User did not join',
      message:
        'The user did not join within the allowed 5-minute window. The session was closed as a no-show.',
      data: {
        sessionId: session._id,
      },
    });
  }

  if (session.status === 'cancelled') {
    await notificationService.createNotification({
      userId: session.userId,
      type: 'mentor_session_cancelled',
      title: 'Session cancelled',
      message: 'Your booked session was cancelled and any held amount was released.',
      data: {
        sessionId: session._id,
      },
    });

    await notificationService.createNotification({
      userId: session.mentorUserId,
      type: 'mentor_session_cancelled',
      title: 'Session cancelled',
      message: 'A booked session was cancelled by the user before it started.',
      data: {
        sessionId: session._id,
      },
    });
  }

  return session;
}

async function completeSession(mentorUserId, sessionId) {
  const session = await MentorSession.findById(sessionId);

  if (!session) {
    throw new Error('Session not found');
  }

  if (String(session.mentorUserId) !== String(mentorUserId)) {
    throw new Error('Only the mentor can complete this session');
  }

  if (!['started', 'active'].includes(session.status)) {
    throw new Error('Only started/active sessions can be completed');
  }

  const finalized = await finalizeSession(session, 'manual_complete');
  return {
    sessionId: finalized._id,
    status: finalized.status,
    paymentStatus: finalized.paymentStatus,
    endedAt: finalized.endedAt,
    actualDurationMinutes: finalized.actualDurationMinutes,
  };
}

async function cancelSession(userId, sessionId) {
  const session = await MentorSession.findById(sessionId);

  if (!session) {
    throw new Error('Session not found');
  }

  if (String(session.userId) !== String(userId)) {
    throw new Error('Only the user can cancel this session');
  }

  if (session.status !== 'scheduled') {
    throw new Error('Only scheduled sessions can be cancelled');
  }

  const finalized = await finalizeSession(session, 'cancelled');

  return {
    sessionId: finalized._id,
    status: finalized.status,
    paymentStatus: finalized.paymentStatus,
    endedAt: finalized.endedAt,
  };
}

async function getSessionTimer(currentUserId, sessionId) {
  const { session } = await assertSessionParticipant(sessionId, currentUserId);

  return {
    sessionId: session._id,
    status: session.status,
    timer: buildTimerInfo(session),
  };
}

async function runLifecycleSweep() {
  const now = getNow();
  let noShowClosed = 0;
  let completedClosed = 0;

  // sessions opened by mentor but user never joined/sent first message in time
  const noShowSessions = await MentorSession.find({
    status: 'started',
    userJoinedAt: null,
    noShowDeadline: { $lte: now },
  });

  for (const session of noShowSessions) {
    await finalizeSession(session, 'user_no_show');
    noShowClosed += 1;
  }

  // only ACTIVE sessions should auto-complete by endAt
  const endedSessions = await MentorSession.find({
    status: 'active',
    endAt: { $ne: null, $lte: now },
  });

  for (const session of endedSessions) {
    await finalizeSession(session, 'normal_end', {
      endedAt: session.endAt || now,
    });
    completedClosed += 1;
  }

  return {
    noShowClosed,
    completedClosed,
    checkedAt: now,
  };
}

// disabled in your new flow
async function acceptSession() {
  throw new Error('Session accept is disabled in the new booking flow');
}

async function rejectSession() {
  throw new Error('Session reject is disabled in the new booking flow');
}

async function expirePendingSessions() {
  return runLifecycleSweep();
}

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
  createSessionPaymobCheckout,
  joinSession,
  cancelSession,
  getSessionTimer,
  runLifecycleSweep,
};