const MentorProfile = require('./mentorProfile.model');
const User = require('../auth/user.model');
const {
  validateAvailabilityRanges,
} = require('./mentorAvailability.service');

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

module.exports = {
  createMentorProfile,
  updateMentorProfile,
  getMyMentorProfile,
  getPublicMentors,
  getMentorById,
};