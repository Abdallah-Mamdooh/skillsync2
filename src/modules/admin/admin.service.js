const User = require('../auth/user.model');
const MentorProfile = require('../mentor/mentorProfile.model');
const MentorSession = require('../mentor/mentorSession.model');
const SessionFeedback = require('../mentor/sessionFeedback.model');
const Transaction = require('../payment/transaction.model');
const UserAssessmentResult = require('../assessment/userAssessmentResult.model');
const Career = require('../career/career.model');
const notificationService = require('../notification/notification.service');
const Roadmap = require('../roadmap/roadmap.model');
const auditService = require('../audit/audit.service');
const MentorActivityLog = require('../mentor/mentorActivityLog.model');
const MentorScheduleChangeRequest = require('../mentor/mentorScheduleChangeRequest.model');
const MentorAvailabilityException = require('../mentor/mentorAvailabilityException.model');


function getDateNDaysAgo(days) {
  const date = new Date();
  date.setDate(date.getDate() - days);
  date.setHours(0, 0, 0, 0);
  return date;
}

function formatDateKey(date) {
  const d = new Date(date);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function buildContinuousDateSeries(days) {
  const result = [];
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  for (let i = days - 1; i >= 0; i -= 1) {
    const d = new Date(today);
    d.setDate(today.getDate() - i);
    result.push(formatDateKey(d));
  }

  return result;
}
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
function normalizeStringArray(value) {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => String(item || '').trim())
    .filter(Boolean);
}

function normalizeResources(value) {
  if (!Array.isArray(value)) {
    throw new Error('resources must be an array');
  }

  return value.map((item) => {
    const title = String(item.title || '').trim();
    const type = String(item.type || '').trim();
    const url = String(item.url || '').trim();

    if (!title || !type || !url) {
      throw new Error('Each resource must include title, type, and url');
    }

    return { title, type, url };
  });
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

async function updateUserStatus(userId, payload = {}, adminUser = null) {
  const {
    isActive,
    blockReason = '',
    blockNote = '',
    blockedAt = null,
    blockedBy = '',
  } = payload;

  const user = await User.findById(userId);
  if (!user) {
    throw new Error('User not found');
  }

  const previousIsActive = user.isActive;

  user.isActive = normalizeBoolean(isActive, 'isActive');
  user.blockReason = String(blockReason || '').trim();
  user.blockNote = String(blockNote || '').trim();
  user.blockedAt = blockedAt ? new Date(blockedAt) : null;
  user.blockedBy = String(blockedBy || '').trim();

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
      blockReason: user.blockReason,
      blockNote: user.blockNote,
      blockedAt: user.blockedAt,
      blockedBy: user.blockedBy,
    },
  });

  if (previousIsActive !== user.isActive) {
    await auditService.createAuditLog({
      action: user.isActive ? 'user_unblocked' : 'user_blocked',
      entityType: 'user',
      entityId: user._id,
      message: user.isActive
        ? `User account unblocked: ${user.fullName || user.email}`
        : `User account blocked: ${user.fullName || user.email}`,
      performedByUserId: adminUser?._id || null,
      performedByEmail:
        adminUser?.email || String(blockedBy || '').trim() || 'admin',
      metadata: {
        isActive: user.isActive,
        blockReason: user.blockReason,
        blockNote: user.blockNote,
      },
    });
  }

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

async function verifyMentorProfile(mentorProfileId, adminUser = null) {
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

  await auditService.createAuditLog({
    action: 'mentor_verified',
    entityType: 'mentor_profile',
    entityId: profile._id,
    message: `Mentor account approved: ${
      profile.userId?.fullName || profile.userId?.email || 'Mentor'
    }`,
    performedByUserId: adminUser?._id || null,
    performedByEmail: adminUser?.email || 'admin',
    metadata: {
      mentorUserId: profile.userId?._id || null,
    },
  });

  return profile;
}

async function unverifyMentorProfile(mentorProfileId, adminUser = null) {
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

  await auditService.createAuditLog({
    action: 'mentor_unverified',
    entityType: 'mentor_profile',
    entityId: profile._id,
    message: `Mentor account unverified: ${
      profile.userId?.fullName || profile.userId?.email || 'Mentor'
    }`,
    performedByUserId: adminUser?._id || null,
    performedByEmail: adminUser?.email || 'admin',
    metadata: {
      mentorUserId: profile.userId?._id || null,
    },
  });

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

async function getAnalyticsOverview() {
  const summary = await getDashboardSummary();

  const completedSessions = await MentorSession.countDocuments({
    status: 'completed',
  });

  const noShowSessions = await MentorSession.countDocuments({
    status: 'user_no_show',
  });

  const openComplaints = await SessionFeedback.countDocuments({
    complaintStatus: 'open',
  });

  const totalTransactions = await Transaction.countDocuments();

  return {
    ...summary,
    completedSessions,
    noShowSessions,
    openComplaints,
    totalTransactions,
  };
}

async function getUserGrowthAnalytics(days = 30) {
  const safeDays = Math.max(1, Math.min(Number(days) || 30, 365));
  const startDate = getDateNDaysAgo(safeDays - 1);

  const rows = await User.aggregate([
    {
      $match: {
        role: 'user',
        createdAt: { $gte: startDate },
      },
    },
    {
      $group: {
        _id: {
          $dateToString: { format: '%Y-%m-%d', date: '$createdAt' },
        },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  const countMap = new Map(rows.map((r) => [r._id, r.count]));
  const labels = buildContinuousDateSeries(safeDays);

  return labels.map((date) => ({
    date,
    count: countMap.get(date) || 0,
  }));
}

async function getMentorGrowthAnalytics(days = 30) {
  const safeDays = Math.max(1, Math.min(Number(days) || 30, 365));
  const startDate = getDateNDaysAgo(safeDays - 1);

  const rows = await User.aggregate([
    {
      $match: {
        role: 'mentor',
        createdAt: { $gte: startDate },
      },
    },
    {
      $group: {
        _id: {
          $dateToString: { format: '%Y-%m-%d', date: '$createdAt' },
        },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);

  const countMap = new Map(rows.map((r) => [r._id, r.count]));
  const labels = buildContinuousDateSeries(safeDays);

  return labels.map((date) => ({
    date,
    count: countMap.get(date) || 0,
  }));
}

async function getSessionTrendAnalytics(days = 30) {
  const safeDays = Math.max(1, Math.min(Number(days) || 30, 365));
  const startDate = getDateNDaysAgo(safeDays - 1);

  const rows = await MentorSession.aggregate([
    {
      $match: {
        createdAt: { $gte: startDate },
      },
    },
    {
      $group: {
        _id: {
          date: {
            $dateToString: { format: '%Y-%m-%d', date: '$createdAt' },
          },
          status: '$status',
        },
        count: { $sum: 1 },
      },
    },
    { $sort: { '_id.date': 1 } },
  ]);

  const labels = buildContinuousDateSeries(safeDays);

  const grouped = new Map();
  for (const date of labels) {
    grouped.set(date, {
      date,
      scheduled: 0,
      started: 0,
      active: 0,
      completed: 0,
      cancelled: 0,
      expired: 0,
      user_no_show: 0,
    });
  }

  for (const row of rows) {
    const date = row._id.date;
    const status = row._id.status;

    if (grouped.has(date) && grouped.get(date)[status] !== undefined) {
      grouped.get(date)[status] = row.count;
    }
  }

  return labels.map((date) => grouped.get(date));
}

async function getTopCareersAnalytics(limit = 10) {
  const safeLimit = Math.max(1, Math.min(Number(limit) || 10, 50));

  const topCareerAgg = await UserAssessmentResult.aggregate([
    { $match: { chosenCareer: { $ne: null } } },
    {
      $group: {
        _id: '$chosenCareer',
        count: { $sum: 1 },
      },
    },
    { $sort: { count: -1 } },
    { $limit: safeLimit },
  ]);

  const careerIds = topCareerAgg.map((item) => item._id);
  const careers = await Career.find({ _id: { $in: careerIds } }).select('name');
  const careerMap = new Map(careers.map((c) => [String(c._id), c.name]));

  return topCareerAgg.map((item) => ({
    careerId: item._id,
    careerName: careerMap.get(String(item._id)) || 'Unknown Career',
    count: item.count,
  }));
}

async function getTopSkillsAnalytics(limit = 10) {
  const safeLimit = Math.max(1, Math.min(Number(limit) || 10, 50));

  const topSkillsAgg = await User.aggregate([
    { $unwind: '$skills' },
    {
      $group: {
        _id: '$skills',
        count: { $sum: 1 },
      },
    },
    { $sort: { count: -1 } },
    { $limit: safeLimit },
  ]);

  return topSkillsAgg.map((item) => ({
    skill: item._id,
    count: item.count,
  }));
}
async function getCareers(query = {}) {
  const {
    search = '',
    page = 1,
    limit = 20,
  } = query;

  const filters = {};

  if (search) {
    filters.$or = [
      { name: { $regex: search, $options: 'i' } },
      { description: { $regex: search, $options: 'i' } },
      { requiredSkills: { $regex: search, $options: 'i' } },
    ];
  }

  const skip = (Number(page) - 1) * Number(limit);

  const [items, total] = await Promise.all([
    Career.find(filters)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(Number(limit)),
    Career.countDocuments(filters),
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

async function getCareerDetails(careerId) {
  const career = await Career.findById(careerId);

  if (!career) {
    throw new Error('Career not found');
  }

  const roadmap = await Roadmap.findOne({ careerId: career._id });

  let roadmapStats = null;

  if (roadmap) {
    let totalPhases = roadmap.phases?.length || 0;
    let totalSteps = 0;

    for (const phase of roadmap.phases || []) {
      totalSteps += (phase.steps || []).length;
    }

    roadmapStats = {
      roadmapId: roadmap._id,
      totalPhases,
      totalSteps,
    };
  }

  return {
    career,
    roadmapStats,
  };
}

async function createCareer(payload = {}) {
  const name = String(payload.name || '').trim();
  const description = String(payload.description || '').trim();
  const requiredSkills = normalizeStringArray(payload.requiredSkills);
  const skills = normalizeStringArray(payload.skills);

  if (!name) {
    throw new Error('name is required');
  }

  const existing = await Career.findOne({ name });
  if (existing) {
    throw new Error('Career with this name already exists');
  }

  const career = await Career.create({
    name,
    description,
    requiredSkills,
    skills,
  });

  return career;
}

async function updateCareer(careerId, payload = {}) {
  const career = await Career.findById(careerId);

  if (!career) {
    throw new Error('Career not found');
  }

  if (payload.name !== undefined) {
    const name = String(payload.name || '').trim();

    if (!name) {
      throw new Error('name cannot be empty');
    }

    const existing = await Career.findOne({
      name,
      _id: { $ne: careerId },
    });

    if (existing) {
      throw new Error('Another career with this name already exists');
    }

    career.name = name;
  }

  if (payload.description !== undefined) {
    career.description = String(payload.description || '').trim();
  }

  if (payload.requiredSkills !== undefined) {
    career.requiredSkills = normalizeStringArray(payload.requiredSkills);
  }

  if (payload.skills !== undefined) {
    career.skills = normalizeStringArray(payload.skills);
  }

  await career.save();
  return career;
}

async function deleteCareer(careerId) {
  const career = await Career.findById(careerId);

  if (!career) {
    throw new Error('Career not found');
  }

  const linkedRoadmap = await Roadmap.findOne({ careerId });

  if (linkedRoadmap) {
    throw new Error(
      'Cannot delete career while a roadmap is linked to it. Delete or reassign the roadmap first.'
    );
  }

  await career.deleteOne();

  return {
    deleted: true,
    careerId,
  };
}

async function getCareerRoadmap(careerId) {
  const career = await Career.findById(careerId);

  if (!career) {
    throw new Error('Career not found');
  }

  const roadmap = await Roadmap.findOne({ careerId });

  if (!roadmap) {
    throw new Error('Roadmap not found for this career');
  }

  return {
    career,
    roadmap,
  };
}

async function updateRoadmapStepResources(careerId, stepId, payload = {}) {
  const career = await Career.findById(careerId);

  if (!career) {
    throw new Error('Career not found');
  }

  const roadmap = await Roadmap.findOne({ careerId });

  if (!roadmap) {
    throw new Error('Roadmap not found for this career');
  }

  const resources = normalizeResources(payload.resources);

  let foundStep = null;

  for (const phase of roadmap.phases || []) {
    for (const step of phase.steps || []) {
      if (String(step._id) === String(stepId)) {
        step.resources = resources;
        foundStep = step;
        break;
      }
    }

    if (foundStep) break;
  }

  if (!foundStep) {
    throw new Error('Step not found in roadmap');
  }

  await roadmap.save();

  return {
    careerId: career._id,
    roadmapId: roadmap._id,
    stepId: foundStep._id,
    resources: foundStep.resources,
  };
}

async function deleteUser(userId) {
  const user = await User.findById(userId);

  if (!user) {
    throw new Error('User not found');
  }

  await user.deleteOne();

  return {
    deleted: true,
    message: 'User deleted successfully',
    userId,
  };
}

async function getPendingMentorCancellations() {
  return MentorSession.find({
    'mentorCancellation.isCancelledByMentor': true,
    'mentorCancellation.adminReviewStatus': 'pending',
  })
    .populate('userId', 'fullName email phoneNumber')
    .populate('mentorUserId', 'fullName email phoneNumber isActive')
    .populate('mentorProfileId')
    .sort({ 'mentorCancellation.cancelledAt': -1 });
}

async function reviewMentorCancellation(sessionId, payload = {}, adminUser = null) {
  const { reviewStatus, adminNote = '' } = payload;

  if (!['valid', 'rejected'].includes(reviewStatus)) {
    throw new Error('reviewStatus must be either valid or rejected');
  }

  const session = await MentorSession.findById(sessionId)
    .populate('mentorUserId', 'fullName email isActive');

  if (!session) {
    throw new Error('Session not found');
  }

  if (!session.mentorCancellation?.isCancelledByMentor) {
    throw new Error('This session was not cancelled by mentor');
  }

  if (session.mentorCancellation.adminReviewStatus !== 'pending') {
    throw new Error('This cancellation has already been reviewed');
  }

  const mentorProfile = await MentorProfile.findById(session.mentorProfileId);

  if (!mentorProfile) {
    throw new Error('Mentor profile not found');
  }

  session.mentorCancellation.adminReviewStatus = reviewStatus;
  session.mentorCancellation.adminReviewedBy = adminUser?._id || null;
  session.mentorCancellation.adminReviewedAt = new Date();
  session.mentorCancellation.adminNote = String(adminNote || '').trim();

  let penaltyApplied = false;
  let mentorBlocked = false;

  if (reviewStatus === 'valid') {
    mentorProfile.consecutiveValidCancellations =
      Number(mentorProfile.consecutiveValidCancellations || 0) + 1;

    mentorProfile.lastCancellationReviewedAt = new Date();

    if (mentorProfile.consecutiveValidCancellations >= 3) {
      mentorProfile.cancellationPenaltyCount =
        Number(mentorProfile.cancellationPenaltyCount || 0) + 1;

      mentorProfile.consecutiveValidCancellations = 0;
      penaltyApplied = true;

      await MentorActivityLog.create({
        mentorUserId: session.mentorUserId._id || session.mentorUserId,
        mentorProfileId: mentorProfile._id,
        sessionId: session._id,
        action: 'penalty_applied',
        message: 'Penalty applied after 3 consecutive valid mentor cancellations',
        metadata: {
          cancellationPenaltyCount: mentorProfile.cancellationPenaltyCount,
        },
        performedByUserId: adminUser?._id || null,
        performedByRole: 'admin',
      });
    }

    if (mentorProfile.cancellationPenaltyCount >= 2) {
      const mentorUser = await User.findById(session.mentorUserId._id || session.mentorUserId);

      if (mentorUser) {
        mentorUser.isActive = false;
        mentorUser.blockReason = 'Repeated valid mentor session cancellations';
        mentorUser.blockNote =
          'Blocked automatically after two cancellation penalty cycles.';
        mentorUser.blockedAt = new Date();
        mentorUser.blockedBy = adminUser?.email || 'admin';

        await mentorUser.save();
        mentorBlocked = true;

        await MentorActivityLog.create({
          mentorUserId: mentorUser._id,
          mentorProfileId: mentorProfile._id,
          sessionId: session._id,
          action: 'mentor_blocked',
          message: 'Mentor blocked after repeated cancellation penalties',
          metadata: {
            cancellationPenaltyCount: mentorProfile.cancellationPenaltyCount,
          },
          performedByUserId: adminUser?._id || null,
          performedByRole: 'admin',
        });

        await notificationService.createNotification({
          userId: mentorUser._id,
          type: 'account_status_updated',
          title: 'Account deactivated',
          message:
            'Your mentor account has been deactivated due to repeated valid session cancellations.',
          data: {
            reason: mentorUser.blockReason,
          },
        });
      }
    }
  }

  if (reviewStatus === 'rejected') {
    mentorProfile.consecutiveValidCancellations = 0;
    mentorProfile.lastCancellationReviewedAt = new Date();
  }

  await session.save();
  await mentorProfile.save();

  await MentorActivityLog.create({
    mentorUserId: session.mentorUserId._id || session.mentorUserId,
    mentorProfileId: mentorProfile._id,
    sessionId: session._id,
    action:
      reviewStatus === 'valid'
        ? 'cancellation_reviewed_valid'
        : 'cancellation_reviewed_rejected',
    message: `Admin reviewed mentor cancellation as ${reviewStatus}`,
    metadata: {
      reviewStatus,
      adminNote,
      consecutiveValidCancellations: mentorProfile.consecutiveValidCancellations,
      cancellationPenaltyCount: mentorProfile.cancellationPenaltyCount,
      penaltyApplied,
      mentorBlocked,
    },
    performedByUserId: adminUser?._id || null,
    performedByRole: 'admin',
  });

  return {
    session,
    mentorProfile,
    reviewStatus,
    penaltyApplied,
    mentorBlocked,
  };
}

async function getMentorActivityLogs(query = {}) {
  const {
    mentorUserId = '',
    mentorProfileId = '',
    action = '',
    page = 1,
    limit = 20,
  } = query;

  const filters = {};

  if (mentorUserId) {
    filters.mentorUserId = mentorUserId;
  }

  if (mentorProfileId) {
    filters.mentorProfileId = mentorProfileId;
  }

  if (action) {
    filters.action = action;
  }

  const skip = (Number(page) - 1) * Number(limit);

  const [items, total] = await Promise.all([
    MentorActivityLog.find(filters)
      .populate('mentorUserId', 'fullName email phoneNumber isActive')
      .populate('mentorProfileId')
      .populate('sessionId')
      .populate('performedByUserId', 'fullName email role')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(Number(limit)),
    MentorActivityLog.countDocuments(filters),
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

async function getPendingScheduleChangeRequests() {
  return MentorScheduleChangeRequest.find({ status: 'pending' })
    .populate('mentorUserId', 'fullName email phoneNumber isActive')
    .populate('mentorProfileId')
    .sort({ createdAt: -1 });
}

async function approveScheduleChangeRequest(requestId, adminUser = null, payload = {}) {
  const request = await MentorScheduleChangeRequest.findById(requestId);

  if (!request) {
    throw new Error('Schedule change request not found');
  }

  if (request.status !== 'pending') {
    throw new Error('This request has already been reviewed');
  }

  request.status = 'approved';
  request.reviewedBy = adminUser?._id || null;
  request.reviewedAt = new Date();
  request.adminNote = String(payload.adminNote || '').trim();

  await request.save();

  await MentorActivityLog.create({
    mentorUserId: request.mentorUserId,
    mentorProfileId: request.mentorProfileId,
    action: 'schedule_change_approved',
    message: 'Admin approved mentor schedule change request',
    metadata: {
      requestId: request._id,
      effectiveFrom: request.effectiveFrom,
      adminNote: request.adminNote,
    },
    performedByUserId: adminUser?._id || null,
    performedByRole: 'admin',
  });

  await notificationService.createNotification({
    userId: request.mentorUserId,
    type: 'schedule_change_approved',
    title: 'Schedule change approved',
    message: 'Your schedule change request has been approved.',
    data: {
      requestId: request._id,
      effectiveFrom: request.effectiveFrom,
    },
  });

  return request;
}

async function rejectScheduleChangeRequest(requestId, adminUser = null, payload = {}) {
  const request = await MentorScheduleChangeRequest.findById(requestId);

  if (!request) {
    throw new Error('Schedule change request not found');
  }

  if (request.status !== 'pending') {
    throw new Error('This request has already been reviewed');
  }

  request.status = 'rejected';
  request.reviewedBy = adminUser?._id || null;
  request.reviewedAt = new Date();
  request.adminNote = String(payload.adminNote || '').trim();

  await request.save();

  await MentorActivityLog.create({
    mentorUserId: request.mentorUserId,
    mentorProfileId: request.mentorProfileId,
    action: 'schedule_change_rejected',
    message: 'Admin rejected mentor schedule change request',
    metadata: {
      requestId: request._id,
      adminNote: request.adminNote,
    },
    performedByUserId: adminUser?._id || null,
    performedByRole: 'admin',
  });

  await notificationService.createNotification({
    userId: request.mentorUserId,
    type: 'schedule_change_rejected',
    title: 'Schedule change rejected',
    message: 'Your schedule change request was rejected by admin.',
    data: {
      requestId: request._id,
      adminNote: request.adminNote,
    },
  });

  return request;
}

async function getMentorAvailabilityExceptions(query = {}) {
  const {
    mentorUserId = '',
    mentorProfileId = '',
    isActive = '',
    page = 1,
    limit = 20,
  } = query;

  const filters = {};

  if (mentorUserId) filters.mentorUserId = mentorUserId;
  if (mentorProfileId) filters.mentorProfileId = mentorProfileId;

  if (isActive !== '') {
    filters.isActive = String(isActive) === 'true';
  }

  const skip = (Number(page) - 1) * Number(limit);

  const [items, total] = await Promise.all([
    MentorAvailabilityException.find(filters)
      .populate('mentorUserId', 'fullName email phoneNumber isActive')
      .populate('mentorProfileId')
      .sort({ unavailableFrom: -1 })
      .skip(skip)
      .limit(Number(limit)),
    MentorAvailabilityException.countDocuments(filters),
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

async function getScheduleChangeRequests(query = {}) {
  const {
    mentorUserId = '',
    mentorProfileId = '',
    status = '',
    page = 1,
    limit = 20,
  } = query;

  const filters = {};

  if (mentorUserId) filters.mentorUserId = mentorUserId;
  if (mentorProfileId) filters.mentorProfileId = mentorProfileId;
  if (status) filters.status = status;

  const skip = (Number(page) - 1) * Number(limit);

  const [items, total] = await Promise.all([
    MentorScheduleChangeRequest.find(filters)
      .populate('mentorUserId', 'fullName email phoneNumber isActive')
      .populate('mentorProfileId')
      .populate('reviewedBy', 'fullName email role')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(Number(limit)),
    MentorScheduleChangeRequest.countDocuments(filters),
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
  getAnalyticsOverview,
  getUserGrowthAnalytics,
  getMentorGrowthAnalytics,
  getSessionTrendAnalytics,
  getTopCareersAnalytics,
  getTopSkillsAnalytics,
  getCareers,
  getCareerDetails,
  createCareer,
  updateCareer,
  deleteCareer,
  getCareerRoadmap,
  updateRoadmapStepResources,
  deleteUser,
  getPendingMentorCancellations,
  reviewMentorCancellation,
  getMentorActivityLogs,
  getPendingScheduleChangeRequests,
  approveScheduleChangeRequest,
  rejectScheduleChangeRequest,
  getMentorAvailabilityExceptions,
  getScheduleChangeRequests,
};