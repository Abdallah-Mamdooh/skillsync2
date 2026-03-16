const MentorSession = require('./mentorSession.model');
const MentorProfile = require('./mentorProfile.model');
const paymentService = require('../payment/payment.service');
const PLATFORM_FEE_PERCENT = 0.2; // 20%
const notificationService = require('../notification/notification.service');
const User = require('../auth/user.model');
const Transaction = require('../payment/transaction.model');

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

function calculatePricing(mentorProfile, method, durationMinutes) {
  const baseRate = Number(mentorProfile.baseRate || 0);
  const multiplier =
    method === 'call'
      ? Number(mentorProfile.callMultiplier || 1.5)
      : Number(mentorProfile.chatMultiplier || 1);

  const subtotal = round2(baseRate * durationMinutes * multiplier);
  const platformFee = round2(subtotal * PLATFORM_FEE_PERCENT);

  // User pays totalAmount; mentor later gets mentorNetAmount
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

const requestSession = async (userId, payload) => {
  const mentorProfileId = payload.mentorProfileId;
  const method = validateMethod(payload.method);
  const durationMinutes = validateDuration(payload.durationMinutes);
  const userNotes = payload.userNotes || '';
  const defaultMethod = await paymentService.getDefaultPaymentMethod(userId);

  await paymentService.holdFunds({
    userId,
    sessionId: session._id,
    amount: pricing.totalAmount,
    paymentMethodId: defaultMethod?._id || null,
    currency: pricing.currency,
  });

  session.paymentStatus = 'held';
  await session.save();

    await notificationService.createNotification({
    userId: mentorProfile.userId._id,
    type: 'mentor_session_requested',
    title: 'New session request',
    message: `You received a new ${method} session request for ${durationMinutes} minutes.`,
    data: {
      sessionId: session._id,
      mentorProfileId: mentorProfile._id,
      method,
      durationMinutes,
      totalAmount: pricing.totalAmount,
      currency: pricing.currency,
    },
  });

  await notificationService.createNotification({
    userId,
    type: 'payment_held',
    title: 'Payment placed on hold',
    message: `An amount of ${pricing.totalAmount} ${pricing.currency} was placed on hold for your session request.`,
    data: {
      sessionId: session._id,
      amount: pricing.totalAmount,
      currency: pricing.currency,
      paymentStatus: 'held',
    },
  });
  if (!mentorProfileId) {
    throw new Error('mentorProfileId is required');
  }

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

  const pricing = calculatePricing(mentorProfile, method, durationMinutes);
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

  const session = await MentorSession.create({
    userId,
    mentorProfileId: mentorProfile._id,
    mentorUserId: mentorProfile.userId._id,
    method,
    durationMinutes,

    baseRate: pricing.baseRate,
    multiplier: pricing.multiplier,
    subtotal: pricing.subtotal,
    platformFee: pricing.platformFee,
    totalAmount: pricing.totalAmount,
    mentorNetAmount: pricing.mentorNetAmount,
    currency: pricing.currency,

    status: 'pending',
    paymentStatus: 'hold_pending',

    requestedAt: new Date(),
    expiresAt,

    userNotes,
  });

  return {
    sessionId: session._id,
    mentor: {
      id: mentorProfile._id,
      userId: mentorProfile.userId._id,
      fullName: mentorProfile.userId.fullName,
      email: mentorProfile.userId.email,
    },
    method: session.method,
    durationMinutes: session.durationMinutes,
    pricing,
    status: session.status,
    paymentStatus: session.paymentStatus,
    expiresAt: session.expiresAt,
  };
};

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
    totalAmount: s.totalAmount,
    currency: s.currency,
    status: s.status,
    paymentStatus: s.paymentStatus,
    requestedAt: s.requestedAt,
    acceptedAt: s.acceptedAt,
    startedAt: s.startedAt,
    endedAt: s.endedAt,
    expiresAt: s.expiresAt,
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
    status: { $in: ['pending', 'accepted', 'active'] },
  })
    .populate('userId', 'fullName email phoneNumber role skills cvUrl')
    .sort({ createdAt: -1 });

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
    totalAmount: s.totalAmount,
    currency: s.currency,
    status: s.status,
    paymentStatus: s.paymentStatus,
    requestedAt: s.requestedAt,
    expiresAt: s.expiresAt,
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
    expiresAt: session.expiresAt,
    meetingProvider: session.meetingProvider,
    meetingLink: session.meetingLink,
    chatRoomId: session.chatRoomId,
    userNotes: session.userNotes,
  };
};

const acceptSession = async (mentorUserId, sessionId, payload = {}) => {
  const mentorProfile = await MentorProfile.findOne({ userId: mentorUserId });

  if (!mentorProfile) {
    throw new Error('Mentor profile not found');
  }

  const session = await MentorSession.findById(sessionId);
  if (!session) {
    throw new Error('Session not found');
  }

  if (String(session.mentorProfileId) !== String(mentorProfile._id)) {
    throw new Error('You are not allowed to accept this session');
  }

  if (session.status !== 'pending') {
    throw new Error('Only pending sessions can be accepted');
  }

  if (session.expiresAt && new Date() > new Date(session.expiresAt)) {
    session.status = 'expired';
    await session.save();
    throw new Error('Session request has expired');
  }

  session.status = 'accepted';
  session.acceptedAt = new Date();

  // for calls, mentor may provide external meeting link
  if (session.method === 'call') {
    session.meetingProvider = payload.meetingProvider || 'other';
    session.meetingLink = payload.meetingLink || '';
  }

  await session.save();

    await notificationService.createNotification({
    userId: session.userId,
    type: 'mentor_session_accepted',
    title: 'Session accepted',
    message: 'Your mentor accepted the session request.',
    data: {
      sessionId: session._id,
      method: session.method,
      meetingProvider: session.meetingProvider,
      meetingLink: session.meetingLink,
      status: session.status,
    },
  });

  return {
    id: session._id,
    status: session.status,
    acceptedAt: session.acceptedAt,
    meetingProvider: session.meetingProvider,
    meetingLink: session.meetingLink,
  };
};

const rejectSession = async (mentorUserId, sessionId) => {
  const mentorProfile = await MentorProfile.findOne({ userId: mentorUserId });

  if (!mentorProfile) {
    throw new Error('Mentor profile not found');
  }

  const session = await MentorSession.findById(sessionId);
  if (!session) {
    throw new Error('Session not found');
  }

  if (String(session.mentorProfileId) !== String(mentorProfile._id)) {
    throw new Error('You are not allowed to reject this session');
  }

  if (!['pending', 'accepted'].includes(session.status)) {
    throw new Error('Only pending or accepted sessions can be rejected');
  }

  session.status = 'rejected';
  await session.save();

    await notificationService.createNotification({
    userId: session.userId,
    type: 'mentor_session_rejected',
    title: 'Session rejected',
    message: 'Your mentor rejected the session request.',
    data: {
      sessionId: session._id,
      status: session.status,
    },
  });

  if (session.paymentStatus === 'released') {
    await notificationService.createNotification({
      userId: session.userId,
      type: 'payment_released',
      title: 'Held payment released',
      message: `Your held payment of ${session.totalAmount} ${session.currency} was released back to your wallet.`,
      data: {
        sessionId: session._id,
        amount: session.totalAmount,
        currency: session.currency,
        paymentStatus: session.paymentStatus,
      },
    });
  }



    if (session.paymentStatus === 'held') {
    await paymentService.releaseHeldFunds({
      userId: session.userId,
      sessionId: session._id,
      amount: session.totalAmount,
      currency: session.currency,
    });

    session.paymentStatus = 'released';
    await session.save();
  }

  return {
    id: session._id,
    status: session.status,
  };
};

const completeSession = async (mentorUserId, sessionId) => {
  const mentorProfile = await MentorProfile.findOne({ userId: mentorUserId });

  if (!mentorProfile) {
    throw new Error('Mentor profile not found');
  }

  const session = await MentorSession.findById(sessionId);
  if (!session) {
    throw new Error('Session not found');
  }

  if (String(session.mentorProfileId) !== String(mentorProfile._id)) {
    throw new Error('You are not allowed to complete this session');
  }

  if (!['accepted', 'active'].includes(session.status)) {
    throw new Error('Only accepted or active sessions can be completed');
  }

  const endedAt = new Date();
  session.endedAt = endedAt;
  session.status = 'completed';

  // calculate actual duration
  if (session.startedAt) {
    const ms = endedAt.getTime() - new Date(session.startedAt).getTime();
    session.actualDurationMinutes = Math.max(1, Math.ceil(ms / 60000));
  } else {
    session.actualDurationMinutes = session.durationMinutes;
  }

   // Finalize payment depending on how the session was funded
  if (session.paymentStatus === 'held') {
    const externalPaidTx = await Transaction.findOne({
      sessionId: session._id,
      provider: 'fawry',
      entityType: 'mentor_session',
      status: 'completed',
    }).sort({ createdAt: -1 });

    if (externalPaidTx) {
      // Fawry path:
      // money already came externally, so do NOT capture wallet funds again
      await paymentService.creditMentorWallet({
        mentorUserId: session.mentorUserId,
        sessionId: session._id,
        amount: session.mentorNetAmount,
        currency: session.currency,
      });

      await paymentService.addPlatformFeeTransaction({
        userId: session.userId,
        sessionId: session._id,
        amount: session.platformFee,
        currency: session.currency,
      });

      session.paymentStatus = 'captured';
    } else {
      // Internal wallet path:
      await paymentService.captureHeldFunds({
        userId: session.userId,
        sessionId: session._id,
        amount: session.totalAmount,
        currency: session.currency,
      });

      await paymentService.creditMentorWallet({
        mentorUserId: session.mentorUserId,
        sessionId: session._id,
        amount: session.mentorNetAmount,
        currency: session.currency,
      });

      await paymentService.addPlatformFeeTransaction({
        userId: session.userId,
        sessionId: session._id,
        amount: session.platformFee,
        currency: session.currency,
      });

      session.paymentStatus = 'captured';
    }
  }

  await session.save();

  // update mentor stats
  mentorProfile.totalSessions = Number(mentorProfile.totalSessions || 0) + 1;
  await mentorProfile.save();

    await notificationService.createNotification({
    userId: session.userId,
    type: 'mentor_session_completed',
    title: 'Session completed',
    message: `Your session has been completed and payment of ${session.totalAmount} ${session.currency} was captured.`,
    data: {
      sessionId: session._id,
      totalAmount: session.totalAmount,
      mentorNetAmount: session.mentorNetAmount,
      platformFee: session.platformFee,
      currency: session.currency,
      paymentStatus: session.paymentStatus,
      endedAt: session.endedAt,
    },
  });

  await notificationService.createNotification({
    userId: session.mentorUserId,
    type: 'mentor_session_completed',
    title: 'Session completed',
    message: `Session completed. ${session.mentorNetAmount} ${session.currency} has been added to your wallet.`,
    data: {
      sessionId: session._id,
      mentorNetAmount: session.mentorNetAmount,
      currency: session.currency,
      endedAt: session.endedAt,
    },
  });

  return {
    id: session._id,
    status: session.status,
    paymentStatus: session.paymentStatus,
    endedAt: session.endedAt,
    actualDurationMinutes: session.actualDurationMinutes,
    totalAmount: session.totalAmount,
    mentorNetAmount: session.mentorNetAmount,
    platformFee: session.platformFee,
    currency: session.currency,
  };
};

const startSession = async (currentUserId, sessionId) => {
  const session = await MentorSession.findById(sessionId);

  if (!session) {
    throw new Error('Session not found');
  }

  const isUser = String(session.userId) === String(currentUserId);
  const isMentor = String(session.mentorUserId) === String(currentUserId);

  if (!isUser && !isMentor) {
    throw new Error('You are not allowed to start this session');
  }

  if (session.status !== 'accepted') {
    throw new Error('Only accepted sessions can be started');
  }

  session.status = 'active';
  session.startedAt = new Date();

  await session.save();
  await notificationService.createNotification({
    userId: session.userId,
    type: 'mentor_session_started',
    title: 'Session started',
    message: 'Your mentor session has started.',
    data: {
      sessionId: session._id,
      startedAt: session.startedAt,
      status: session.status,
    },
  });

  await notificationService.createNotification({
    userId: session.mentorUserId,
    type: 'mentor_session_started',
    title: 'Session started',
    message: 'Your mentor session has started.',
    data: {
      sessionId: session._id,
      startedAt: session.startedAt,
      status: session.status,
    },
  });
  return {
    id: session._id,
    status: session.status,
    startedAt: session.startedAt,
  };
};

const expirePendingSessions = async () => {
  const now = new Date();

  const sessions = await MentorSession.find({
    status: 'pending',
    expiresAt: { $lte: now },
  });

  let expiredCount = 0;

  for (const session of sessions) {
    session.status = 'expired';

    if (session.paymentStatus === 'held') {
      await paymentService.releaseHeldFunds({
        userId: session.userId,
        sessionId: session._id,
        amount: session.totalAmount,
        currency: session.currency,
      });

      session.paymentStatus = 'released';
    }

    await session.save();
    expiredCount++;
  }

      await notificationService.createNotification({
      userId: session.userId,
      type: 'mentor_session_expired',
      title: 'Session request expired',
      message: 'Your session request expired because it was not accepted in time.',
      data: {
        sessionId: session._id,
        status: session.status,
      },
    });

    if (session.paymentStatus === 'released') {
      await notificationService.createNotification({
        userId: session.userId,
        type: 'payment_released',
        title: 'Held payment released',
        message: `Your held payment of ${session.totalAmount} ${session.currency} was released after session expiration.`,
        data: {
          sessionId: session._id,
          amount: session.totalAmount,
          currency: session.currency,
          paymentStatus: session.paymentStatus,
        },
      });
    }

  return {
    expiredCount,
  };
};
const createSessionFawryCheckout = async (userId, payload) => {
  const mentorProfileId = payload.mentorProfileId;
  const method = validateMethod(payload.method);
  const durationMinutes = validateDuration(payload.durationMinutes);
  const userNotes = payload.userNotes || '';

  if (!mentorProfileId) {
    throw new Error('mentorProfileId is required');
  }

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

  const pricing = calculatePricing(mentorProfile, method, durationMinutes);
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

  const session = await MentorSession.create({
    userId,
    mentorProfileId: mentorProfile._id,
    mentorUserId: mentorProfile.userId._id,
    method,
    durationMinutes,

    baseRate: pricing.baseRate,
    multiplier: pricing.multiplier,
    subtotal: pricing.subtotal,
    platformFee: pricing.platformFee,
    totalAmount: pricing.totalAmount,
    mentorNetAmount: pricing.mentorNetAmount,
    currency: pricing.currency,

    status: 'pending',
    paymentStatus: 'hold_pending',

    requestedAt: new Date(),
    expiresAt,

    userNotes,
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
    amount: pricing.totalAmount,
    purpose: 'hold',
    entityType: 'mentor_session',
    entityId: session._id,
    description: `Mentor session payment - ${method} - ${durationMinutes} minutes`,
    paymentMethod: payload.paymentMethod || '',
  });

  await notificationService.createNotification({
    userId: mentorProfile.userId._id,
    type: 'mentor_session_requested',
    title: 'New session request',
    message: `You received a new ${method} session request for ${durationMinutes} minutes.`,
    data: {
      sessionId: session._id,
      mentorProfileId: mentorProfile._id,
      method,
      durationMinutes,
      totalAmount: pricing.totalAmount,
      currency: pricing.currency,
    },
  });

  return {
    sessionId: session._id,
    mentor: {
      id: mentorProfile._id,
      userId: mentorProfile.userId._id,
      fullName: mentorProfile.userId.fullName,
      email: mentorProfile.userId.email,
    },
    method: session.method,
    durationMinutes: session.durationMinutes,
    pricing,
    status: session.status,
    paymentStatus: session.paymentStatus,
    expiresAt: session.expiresAt,
    checkout,
  };
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