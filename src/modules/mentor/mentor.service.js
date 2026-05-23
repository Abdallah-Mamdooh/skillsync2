const MentorProfile = require('./mentorProfile.model');
const User = require('../auth/user.model');
const {
  validateAvailabilityRanges,
} = require('./mentorAvailability.service');
const MentorActivityLog = require('./mentorActivityLog.model');
const MentorScheduleChangeRequest = require('./mentorScheduleChangeRequest.model');
const MentorAvailabilityException = require('./mentorAvailabilityException.model');

function normalizeProfilePayload(payload = {}) {
  return {
    headline: payload.headline || '',
    bio: payload.bio || '',
    specialization: Array.isArray(payload.specialization)
      ? payload.specialization
      : [],
    careerField: payload.careerField || '',
    yearsOfExperience: payload.yearsOfExperience || 0,
    linkedinUrl: payload.linkedinUrl || '',
    portfolioUrl: payload.portfolioUrl || '',
    mentorCvUrl: payload.mentorCvUrl || '',
    certifications: Array.isArray(payload.certifications)
      ? payload.certifications
      : [],
    identityDocs: Array.isArray(payload.identityDocs)
      ? payload.identityDocs
      : [],
    availability: payload.availability !== undefined
      ? validateAvailabilityRanges(payload.availability)
      : [],
    timezone: payload.timezone || 'Africa/Cairo',
    isAvailable:
      typeof payload.isAvailable === 'boolean' ? payload.isAvailable : true,
    supportsChat:
      typeof payload.supportsChat === 'boolean' ? payload.supportsChat : true,
    supportsCall:
      typeof payload.supportsCall === 'boolean' ? payload.supportsCall : false,
    baseRate: payload.baseRate || 0,
    chatMultiplier: payload.chatMultiplier || 1,
    callMultiplier: payload.callMultiplier || 1.5,
    currency: payload.currency || 'EGP',
    quotaLabel: payload.quotaLabel || '',
  };
}

const createMentorProfile = async (userId, payload) => {
  const existing = await MentorProfile.findOne({ userId });
  if (existing) {
    throw new Error('Mentor profile already exists for this user');
  }

  const user = await User.findById(userId);
  if (!user) {
    throw new Error('User not found');
  }

  const normalized = normalizeProfilePayload(payload);

  const profile = await MentorProfile.create({
    userId,
    ...normalized,
  });

  return profile;
};

const updateMentorProfile = async (userId, payload) => {
  const profile = await MentorProfile.findOne({ userId });
  if (!profile) {
    throw new Error('Mentor profile not found');
  }

  const updatableFields = [
    'headline',
    'bio',
    'specialization',
    'careerField',
    'yearsOfExperience',
    'linkedinUrl',
    'portfolioUrl',
    'mentorCvUrl',
    'certifications',
    'identityDocs',
    'isAvailable',
    'supportsChat',
    'supportsCall',
    'baseRate',
    'chatMultiplier',
    'callMultiplier',
    'currency',
    'quotaLabel',
    'timezone',
  ];

  for (const field of updatableFields) {
    if (payload[field] !== undefined) {
      profile[field] = payload[field];
    }
  }

  if (payload.availability !== undefined) {
    profile.availability = validateAvailabilityRanges(payload.availability);
  }

  await profile.save();
  return profile;
};

const getMyMentorProfile = async (userId) => {
  const profile = await MentorProfile.findOne({ userId }).populate(
    'userId',
    'fullName email phoneNumber role cvUrl isActive'
  );

  if (!profile) {
    throw new Error('Mentor profile not found');
  }

  return profile;
};

const getPublicMentors = async () => {
  const profiles = await MentorProfile.find({
    isVerified: true,
    isAvailable: true,
  })
    .populate('userId', 'fullName email')
    .sort({ ratingAverage: -1, totalSessions: -1, createdAt: -1 });

  return profiles.map((profile) => ({
    id: profile._id,
    userId: profile.userId?._id || null,
    fullName: profile.userId?.fullName || '',
    email: profile.userId?.email || '',
    headline: profile.headline,
    bio: profile.bio,
    specialization: profile.specialization,
    careerField: profile.careerField,
    yearsOfExperience: profile.yearsOfExperience,
    isAvailable: profile.isAvailable,
    supportsChat: profile.supportsChat,
    supportsCall: profile.supportsCall,
    baseRate: profile.baseRate,
    chatMultiplier: profile.chatMultiplier,
    callMultiplier: profile.callMultiplier,
    currency: profile.currency,
    quotaLabel: profile.quotaLabel,
    ratingAverage: profile.ratingAverage,
    ratingCount: profile.ratingCount,
    totalSessions: profile.totalSessions,
    timezone: profile.timezone,
    availability: profile.availability,
  }));
};

const getMentorById = async (mentorProfileId) => {
  const profile = await MentorProfile.findById(mentorProfileId).populate(
    'userId',
    'fullName email phoneNumber cvUrl'
  );

  if (!profile) {
    throw new Error('Mentor profile not found');
  }

  return {
    id: profile._id,
    user: {
      id: profile.userId?._id || null,
      fullName: profile.userId?.fullName || '',
      email: profile.userId?.email || '',
      phoneNumber: profile.userId?.phoneNumber || '',
      cvUrl: profile.userId?.cvUrl || '',
    },
    headline: profile.headline,
    bio: profile.bio,
    specialization: profile.specialization,
    careerField: profile.careerField,
    yearsOfExperience: profile.yearsOfExperience,
    linkedinUrl: profile.linkedinUrl,
    portfolioUrl: profile.portfolioUrl,
    mentorCvUrl: profile.mentorCvUrl,
    certifications: profile.certifications,
    availability: profile.availability,
    timezone: profile.timezone,
    isVerified: profile.isVerified,
    isAvailable: profile.isAvailable,
    supportsChat: profile.supportsChat,
    supportsCall: profile.supportsCall,
    baseRate: profile.baseRate,
    chatMultiplier: profile.chatMultiplier,
    callMultiplier: profile.callMultiplier,
    currency: profile.currency,
    quotaLabel: profile.quotaLabel,
    ratingAverage: profile.ratingAverage,
    ratingCount: profile.ratingCount,
    totalSessions: profile.totalSessions,
  };
};

const updateMentorAvailabilityStatus = async (userId, payload = {}) => {
  const { availabilityStatus, breakDurationMinutes } = payload;

  const allowedStatuses = ['online', 'offline', 'on_break'];

  if (!allowedStatuses.includes(availabilityStatus)) {
    throw new Error('availabilityStatus must be online, offline, or on_break');
  }

  const profile = await MentorProfile.findOne({ userId });

  if (!profile) {
    throw new Error('Mentor profile not found');
  }

  const previousStatus = profile.availabilityStatus || 'offline';

  profile.availabilityStatus = availabilityStatus;

  if (availabilityStatus === 'online') {
    profile.isAvailable = true;
    profile.breakStartedAt = null;
    profile.breakEndsAt = null;
    profile.breakDurationMinutes = null;
  }

  if (availabilityStatus === 'offline') {
    profile.isAvailable = false;
    profile.breakStartedAt = null;
    profile.breakEndsAt = null;
    profile.breakDurationMinutes = null;
  }

  if (availabilityStatus === 'on_break') {
    const duration = Number(breakDurationMinutes);

    if (![5, 10].includes(duration)) {
      throw new Error('Break duration must be either 5 or 10 minutes');
    }

    const now = new Date();

    profile.isAvailable = false;
    profile.breakStartedAt = now;
    profile.breakEndsAt = new Date(now.getTime() + duration * 60 * 1000);
    profile.breakDurationMinutes = duration;
  }

  await profile.save();

  await MentorActivityLog.create({
    mentorUserId: userId,
    mentorProfileId: profile._id,
    action:
      availabilityStatus === 'on_break'
        ? 'break_started'
        : 'status_changed',
    message: `Mentor status changed from ${previousStatus} to ${availabilityStatus}`,
    metadata: {
      previousStatus,
      availabilityStatus,
      breakDurationMinutes: profile.breakDurationMinutes,
      breakStartedAt: profile.breakStartedAt,
      breakEndsAt: profile.breakEndsAt,
    },
    performedByUserId: userId,
    performedByRole: 'mentor',
  });

  return profile;
};

const submitScheduleChangeRequest = async (userId, payload = {}) => {
  const {
    requestedAvailability = [],
    reason = '',
    effectiveFrom,
  } = payload;

  const profile = await MentorProfile.findOne({ userId });

  if (!profile) {
    throw new Error('Mentor profile not found');
  }

  const existingPending = await MentorScheduleChangeRequest.findOne({
    mentorProfileId: profile._id,
    status: 'pending',
  });

  if (existingPending) {
    throw new Error('You already have a pending schedule change request');
  }

  if (
    !Array.isArray(requestedAvailability) ||
    requestedAvailability.length === 0
  ) {
    throw new Error('requestedAvailability is required');
  }

  const request = await MentorScheduleChangeRequest.create({
    mentorUserId: userId,
    mentorProfileId: profile._id,
    currentAvailability: profile.availability || [],
    requestedAvailability,
    reason,
    effectiveFrom,
    status: 'pending',
  });

  await MentorActivityLog.create({
    mentorUserId: userId,
    mentorProfileId: profile._id,
    action: 'schedule_change_requested',
    message: 'Mentor submitted schedule change request',
    metadata: {
      requestedAvailability,
      effectiveFrom,
      reason,
    },
    performedByUserId: userId,
    performedByRole: 'mentor',
  });

  return request;
};

const applyApprovedScheduleChanges = async () => {
  const now = new Date();

  const requests = await MentorScheduleChangeRequest.find({
    status: 'approved',
    effectiveFrom: { $lte: now },
  });

  let appliedCount = 0;

  for (const request of requests) {
    const profile = await MentorProfile.findById(request.mentorProfileId);

    if (!profile) continue;

    profile.availability = request.requestedAvailability;
    await profile.save();

    request.status = 'applied';
    request.appliedAt = now;
    await request.save();

    await MentorActivityLog.create({
      mentorUserId: request.mentorUserId,
      mentorProfileId: request.mentorProfileId,
      action: 'schedule_change_applied',
      message: 'Approved mentor schedule change was applied automatically',
      metadata: {
        requestId: request._id,
        effectiveFrom: request.effectiveFrom,
        appliedAt: now,
      },
      performedByUserId: null,
      performedByRole: 'system',
    });

    appliedCount += 1;
  }

  return {
    appliedCount,
    checkedAt: now,
  };
};

const createAvailabilityException = async (userId, payload = {}) => {
  const { unavailableFrom, unavailableTo, reason = '' } = payload;

  if (!unavailableFrom || !unavailableTo) {
    throw new Error('unavailableFrom and unavailableTo are required');
  }

  const from = new Date(unavailableFrom);
  const to = new Date(unavailableTo);

  if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) {
    throw new Error('Invalid unavailable date range');
  }

  if (to <= from) {
    throw new Error('unavailableTo must be after unavailableFrom');
  }

  const profile = await MentorProfile.findOne({ userId });

  if (!profile) {
    throw new Error('Mentor profile not found');
  }

  const exception = await MentorAvailabilityException.create({
    mentorUserId: userId,
    mentorProfileId: profile._id,
    unavailableFrom: from,
    unavailableTo: to,
    reason,
    isActive: true,
  });

  await MentorActivityLog.create({
    mentorUserId: userId,
    mentorProfileId: profile._id,
    action: 'availability_exception_created',
    message: 'Mentor created availability exception',
    metadata: {
      exceptionId: exception._id,
      unavailableFrom: from,
      unavailableTo: to,
      reason,
    },
    performedByUserId: userId,
    performedByRole: 'mentor',
  });

  return exception;
};

const removeAvailabilityException = async (userId, exceptionId) => {
  const exception = await MentorAvailabilityException.findById(exceptionId);

  if (!exception) {
    throw new Error('Availability exception not found');
  }

  if (String(exception.mentorUserId) !== String(userId)) {
    throw new Error('You are not allowed to remove this exception');
  }

  exception.isActive = false;
  await exception.save();

  await MentorActivityLog.create({
    mentorUserId: userId,
    mentorProfileId: exception.mentorProfileId,
    action: 'availability_exception_removed',
    message: 'Mentor removed availability exception',
    metadata: {
      exceptionId: exception._id,
      unavailableFrom: exception.unavailableFrom,
      unavailableTo: exception.unavailableTo,
      reason: exception.reason,
    },
    performedByUserId: userId,
    performedByRole: 'mentor',
  });

  return exception;
};

const getMyAvailabilityExceptions = async (userId) => {
  const profile = await MentorProfile.findOne({ userId });

  if (!profile) {
    throw new Error('Mentor profile not found');
  }

  return MentorAvailabilityException.find({
    mentorProfileId: profile._id,
    isActive: true,
    unavailableTo: { $gte: new Date() },
  }).sort({ unavailableFrom: 1 });
};



const expireFinishedBreaks = async () => {
  const now = new Date();

  const mentors = await MentorProfile.find({
    availabilityStatus: 'on_break',
    breakEndsAt: { $lte: now },
  });

  for (const mentor of mentors) {
    mentor.availabilityStatus = 'online';
    mentor.isAvailable = true;
    mentor.breakEndsAt = null;

    await mentor.save();

    await MentorActivityLog.create({
      mentorUserId: mentor.userId,
      mentorProfileId: mentor._id,

      action: 'break_ended',

      message:
        'Mentor break expired automatically',

      metadata: {},

      performedByUserId: null,
      performedByRole: 'system',
    });
  }

  return {
    updated: mentors.length,
  };
};

const getMyScheduleChangeRequests = async (userId) => {
  const profile = await MentorProfile.findOne({ userId });

  if (!profile) {
    throw new Error('Mentor profile not found');
  }

  return MentorScheduleChangeRequest.find({
    mentorProfileId: profile._id,
  }).sort({ createdAt: -1 });
};
module.exports = {
  createMentorProfile,
  updateMentorProfile,
  getMyMentorProfile,
  getPublicMentors,
  getMentorById,
  updateMentorAvailabilityStatus,
  expireFinishedBreaks,
  submitScheduleChangeRequest,
  applyApprovedScheduleChanges,
  createAvailabilityException,
  removeAvailabilityException,
  getMyAvailabilityExceptions,
  getMyScheduleChangeRequests, 
};