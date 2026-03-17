const User = require('../auth/user.model');
const MentorProfile = require('../mentor/mentorProfile.model');
const MentorSession = require('../mentor/mentorSession.model');
const SessionFeedback = require('../mentor/sessionFeedback.model');
const Transaction = require('../payment/transaction.model');
const UserAssessmentResult = require('../assessment/userAssessmentResult.model');
const Career = require('../career/career.model');
const notificationService = require('../notification/notification.service');

function normalizeBoolean(value, fieldName) {
  if (typeof value !== 'boolean') {
    throw new Error(`${fieldName} must be a boolean`);
  }
  return value;
}

function todayDateString() {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

async function getDashboardSummary() {
  const totalUsers = await User.countDocuments({ role: 'user' });
  const totalMentors = await User.countDocuments({ role: 'mentor' });

  const pendingMentors = await MentorProfile.countDocuments({
    isVerified: false,
  });

  const activeSessions = await MentorSession.countDocuments({
    $or: [
      { status: { $in: ['started', 'active'] } },
      { status: 'scheduled', scheduledDate: todayDateString() },
    ],
  });

  const completedPaidSessions = await MentorSession.aggregate([
    {
      $match: {
        status: { $in: ['completed', 'user_no_show'] },
        paymentStatus: { $in: ['captured', 'refunded'] },
      },
    },
    {
      $group: {
        _id: null,
        totalRevenue: { $sum: '$platformFee' },
      },
    },
  ]);

  const totalRevenue = completedPaidSessions[0]?.totalRevenue || 0;

  const topCareerAgg = await UserAssessmentResult.aggregate([
    { $match: { chosenCareer: { $ne: null } } },
    {
      $group: {
        _id: '$chosenCareer',
        count: { $sum: 1 },
      },
    },
    { $sort: { count: -1 } },
    { $limit: 5 },
  ]);

  const careerIds = topCareerAgg.map((item) => item._id);
  const careers = await Career.find({ _id: { $in: careerIds } }).select('name');

  const careerMap = new Map(careers.map((c) => [String(c._id), c.name]));

  const popularCareerPaths = topCareerAgg.map((item) => ({
    careerId: item._id,
    careerName: careerMap.get(String(item._id)) || 'Unknown Career',
    count: item.count,
  }));

  const topSkillsAgg = await User.aggregate([
    { $unwind: '$skills' },
    {
      $group: {
        _id: '$skills',
        count: { $sum: 1 },
      },
    },
    { $sort: { count: -1 } },
    { $limit: 5 },
  ]);

  const topSkills = topSkillsAgg.map((item) => ({
    skill: item._id,
    count: item.count,
  }));

  return {
    totalUsers,
    totalMentors,
    pendingMentors,
    activeSessions,
    totalRevenue,
    popularCareerPaths,
    topSkills,
  };
}

async function getUsers(query = {}) {
  const {
    search = '',
    role = '',
    isActive,
    page = 1,
    limit = 20,
  } = query;

  const filters = {};

  if (role) {
    filters.role = role;
  }

  if (isActive !== undefined && isActive !== '') {
    filters.isActive = String(isActive) === 'true';
  }

  if (search) {
    filters.$or = [
      { fullName: { $regex: search, $options: 'i' } },
      { email: { $regex: search, $options: 'i' } },
      { phoneNumber: { $regex: search, $options: 'i' } },
    ];
  }

  const skip = (Number(page) - 1) * Number(limit);

  const [items, total] = await Promise.all([
    User.find(filters)
      .select('-password -passwordResetToken -passwordResetExpires')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(Number(limit)),
    User.countDocuments(filters),
  ]);

  return {
    items,
    pagination: {
      page: Number(page),
      limit: Number(limit),
      total,
      pages: Math.ceil(total / Number(limit)),
    },
  };
}

async function getUserDetails(userId) {
  const user = await User.findById(userId).select(
    '-password -passwordResetToken -passwordResetExpires'
  );

  if (!user) {
    throw new Error('User not found');
  }

  const assessment = await UserAssessmentResult.findOne({ userId }).populate(
    'chosenCareer'
  );

  const sessionsCount = await MentorSession.countDocuments({ userId });
  const completedSessionsCount = await MentorSession.countDocuments({
    userId,
    status: { $in: ['completed', 'user_no_show'] },
  });

  return {
    user,
    assessment: assessment
      ? {
          id: assessment._id,
          chosenCareer: assessment.chosenCareer || null,
          createdAt: assessment.createdAt,
          updatedAt: assessment.updatedAt,
        }
      : null,
    sessionsCount,
    completedSessionsCount,
    skillsCount: Array.isArray(user.skills) ? user.skills.length : 0,
  };
}

async function updateUserStatus(userId, payload = {}) {
  const { isActive } = payload;

  const user = await User.findById(userId);
  if (!user) {
    throw new Error('User not found');
  }

  user.isActive = normalizeBoolean(isActive, 'isActive');
  await user.save();

  await notificationService.createNotification({
    userId: user._id,
    type: 'account_status_updated',
    title: 'Account status updated',
    message: user.isActive
      ? 'Your account has been activated.'
      : 'Your account has been deactivated by admin.',
    data: {
      isActive: user.isActive,
    },
  });

  return user;
}

async function getAllMentorProfiles() {
  return MentorProfile.find()
    .populate('userId', 'fullName email phoneNumber role cvUrl isActive')
    .sort({ createdAt: -1 });
}

async function getPendingMentorProfiles() {
  return MentorProfile.find({ isVerified: false })
    .populate('userId', 'fullName email phoneNumber role cvUrl isActive')
    .sort({ createdAt: -1 });
}

async function getMentors(query = {}) {
  const {
    search = '',
    isVerified,
    isAvailable,
    page = 1,
    limit = 20,
  } = query;

  const filters = {};

  if (isVerified !== undefined && isVerified !== '') {
    filters.isVerified = String(isVerified) === 'true';
  }

  if (isAvailable !== undefined && isAvailable !== '') {
    filters.isAvailable = String(isAvailable) === 'true';
  }

  let mentorProfiles = await MentorProfile.find(filters)
    .populate('userId', 'fullName email phoneNumber role cvUrl isActive')
    .sort({ createdAt: -1 });

  if (search) {
    const s = String(search).toLowerCase();
    mentorProfiles = mentorProfiles.filter((m) => {
      const fullName = String(m.userId?.fullName || '').toLowerCase();
      const email = String(m.userId?.email || '').toLowerCase();
      const headline = String(m.headline || '').toLowerCase();
      const careerField = String(m.careerField || '').toLowerCase();

      return (
        fullName.includes(s) ||
        email.includes(s) ||
        headline.includes(s) ||
        careerField.includes(s)
      );
    });
  }

  const total = mentorProfiles.length;
  const start = (Number(page) - 1) * Number(limit);
  const end = start + Number(limit);

  return {
    items: mentorProfiles.slice(start, end),
    pagination: {
      page: Number(page),
      limit: Number(limit),
      total,
      pages: Math.ceil(total / Number(limit)),
    },
  };
}

async function getMentorDetails(mentorProfileId) {
  const profile = await MentorProfile.findById(mentorProfileId).populate(
    'userId',
    'fullName email phoneNumber role cvUrl isActive'
  );

  if (!profile) {
    throw new Error('Mentor profile not found');
  }

  const sessionsCount = await MentorSession.countDocuments({
    mentorProfileId,
  });

  const openComplaintsCount = await SessionFeedback.countDocuments({
    mentorProfileId,
    complaintStatus: 'open',
  });

  return {
    profile,
    sessionsCount,
    openComplaintsCount,
  };
}

async function updateMentorStatus(mentorProfileId, payload = {}) {
  const { isVerified, isAvailable } = payload;

  const profile = await MentorProfile.findById(mentorProfileId).populate(
    'userId',
    'fullName email'
  );

  if (!profile) {
    throw new Error('Mentor profile not found');
  }

  if (isVerified !== undefined) {
    profile.isVerified = normalizeBoolean(isVerified, 'isVerified');
  }

  if (isAvailable !== undefined) {
    profile.isAvailable = normalizeBoolean(isAvailable, 'isAvailable');
  }

  await profile.save();

  if (profile.userId?._id) {
    await notificationService.createNotification({
      userId: profile.userId._id,
      type: 'mentor_status_updated',
      title: 'Mentor profile status updated',
      message: 'Your mentor profile status has been updated by admin.',
      data: {
        mentorProfileId: profile._id,
        isVerified: profile.isVerified,
        isAvailable: profile.isAvailable,
      },
    });
  }

  return profile;
}

async function verifyMentorProfile(mentorProfileId) {
  const profile = await MentorProfile.findById(mentorProfileId).populate(
    'userId',
    'fullName email'
  );

  if (!profile) {
    throw new Error('Mentor profile not found');
  }

  profile.isVerified = true;
  await profile.save();

  if (profile.userId?._id) {
    await notificationService.createNotification({
      userId: profile.userId._id,
      type: 'mentor_verified',
      title: 'Mentor profile verified',
      message: 'Your mentor profile has been verified successfully.',
      data: {
        mentorProfileId: profile._id,
      },
    });
  }

  return profile;
}

async function unverifyMentorProfile(mentorProfileId) {
  const profile = await MentorProfile.findById(mentorProfileId).populate(
    'userId',
    'fullName email'
  );

  if (!profile) {
    throw new Error('Mentor profile not found');
  }

  profile.isVerified = false;
  await profile.save();

  if (profile.userId?._id) {
    await notificationService.createNotification({
      userId: profile.userId._id,
      type: 'mentor_unverified',
      title: 'Mentor profile verification removed',
      message: 'Your mentor profile verification status has been removed.',
      data: {
        mentorProfileId: profile._id,
      },
    });
  }

  return profile;
}

async function getOpenComplaints() {
  return SessionFeedback.find({
    complaintStatus: 'open',
  })
    .populate('userId', 'fullName email')
    .populate('mentorUserId', 'fullName email')
    .populate('mentorProfileId')
    .populate('sessionId')
    .sort({ createdAt: -1 });
}

async function updateComplaintStatus(feedbackId, payload) {
  const { complaintStatus, complaintAdminNote = '' } = payload || {};

  const allowed = ['open', 'reviewed', 'resolved', 'dismissed'];

  if (!allowed.includes(complaintStatus)) {
    throw new Error('Invalid complaint status');
  }

  const feedback = await SessionFeedback.findById(feedbackId);

  if (!feedback) {
    throw new Error('Feedback not found');
  }

  if (!feedback.complaintText) {
    throw new Error('This feedback does not contain a complaint');
  }

  feedback.complaintStatus = complaintStatus;
  feedback.complaintAdminNote = String(complaintAdminNote || '').trim();

  if (complaintStatus === 'reviewed' && !feedback.complaintReviewedAt) {
    feedback.complaintReviewedAt = new Date();
  }

  if (['resolved', 'dismissed'].includes(complaintStatus)) {
    feedback.complaintResolvedAt = new Date();
    if (!feedback.complaintReviewedAt) {
      feedback.complaintReviewedAt = new Date();
    }
  }

  await feedback.save();

  await notificationService.createNotification({
    userId: feedback.userId,
    type: 'complaint_status_updated',
    title: 'Complaint status updated',
    message: `Your complaint status is now: ${complaintStatus}.`,
    data: {
      feedbackId: feedback._id,
      complaintStatus,
      complaintAdminNote: feedback.complaintAdminNote,
      sessionId: feedback.sessionId,
    },
  });

  return feedback;
}

async function getTransactions(query = {}) {
  const {
    search = '',
    entityType = '',
    status = '',
    provider = '',
    page = 1,
    limit = 20,
  } = query;

  const filters = {};

  if (entityType) {
    filters.entityType = entityType;
  }

  if (status) {
    filters.status = status;
  }

  if (provider) {
    filters.provider = provider;
  }

  let transactions = await Transaction.find(filters)
    .populate('userId', 'fullName email')
    .populate('sessionId')
    .sort({ createdAt: -1 });

  if (search) {
    const s = String(search).toLowerCase();
    transactions = transactions.filter((tx) => {
      const fullName = String(tx.userId?.fullName || '').toLowerCase();
      const email = String(tx.userId?.email || '').toLowerCase();
      const merchantRef = String(tx.merchantRefNum || '').toLowerCase();
      const providerRef = String(tx.providerRefNum || '').toLowerCase();

      return (
        fullName.includes(s) ||
        email.includes(s) ||
        merchantRef.includes(s) ||
        providerRef.includes(s)
      );
    });
  }

  const total = transactions.length;
  const start = (Number(page) - 1) * Number(limit);
  const end = start + Number(limit);

  return {
    items: transactions.slice(start, end),
    pagination: {
      page: Number(page),
      limit: Number(limit),
      total,
      pages: Math.ceil(total / Number(limit)),
    },
  };
}

module.exports = {
  getDashboardSummary,
  getUsers,
  getUserDetails,
  updateUserStatus,
  getAllMentorProfiles,
  getPendingMentorProfiles,
  getMentors,
  getMentorDetails,
  updateMentorStatus,
  verifyMentorProfile,
  unverifyMentorProfile,
  getOpenComplaints,
  updateComplaintStatus,
  getTransactions,
};