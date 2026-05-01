const asyncHandler = require('../../middlewares/async.middleware');
const adminService = require('../admin/admin.service');
const User = require('../auth/user.model');
const MentorProfile = require('../mentor/mentorProfile.model');
const SessionFeedback = require('../mentor/sessionFeedback.model');
const Transaction = require('../payment/transaction.model');
const settingsService = require('../settings/settings.service');
const auditService = require('../audit/audit.service');
const GroupEvent = require('../events/groupEvent.model');

function mapUserToDashboardShape(user) {
  return {
    _id: user._id,
    name: user.fullName || '',
    email: user.email || '',
    role: user.role || 'user',
    status: user.isActive === false ? 'Blocked' : 'Active',
    blockReason: user.blockReason || '',
    blockNote: user.blockNote || '',
    blockedAt: user.blockedAt || null,
    blockedBy: user.blockedBy || '',
  };
}

function mapMentorToDashboardShape(profile) {
  const user = profile?.userId || {};

  let status = 'Pending';

  if (user.isActive === false || profile.isAvailable === false) {
    status = 'Rejected';
  } else if (profile.isVerified === true) {
    status = 'Active';
  }

  return {
    _id: profile._id,
    name: user.fullName || '',
    email: user.email || '',
    field: profile.careerField || profile.headline || '',
    rating: Number(profile.ratingAverage || 0),
    sessions: Number(profile.totalSessions || 0),
    status,
  };
}

function mapCareerToDashboardShape(career) {
  const skillsArray = Array.isArray(career.skills)
    ? career.skills
    : Array.isArray(career.requiredSkills)
    ? career.requiredSkills
    : [];

  return {
    _id: career._id,
    path: career.name || '',
    skills: skillsArray.join(', '),
    resources: '',
  };
}

function mapFeedbackToDashboardShape(feedback) {
  const sessionId = feedback.sessionId?._id || feedback.sessionId || '';
  const mentorName = feedback.mentorUserId?.fullName || 'Mentor';
  const userName = feedback.userId?.fullName || 'User';

  let status = 'Open';
  const complaintStatus = String(feedback.complaintStatus || '').toLowerCase();

  if (complaintStatus === 'resolved' || complaintStatus === 'dismissed') {
    status = 'Resolved';
  } else if (complaintStatus === 'reviewed') {
    status = 'Under Review';
  }

  return {
    _id: feedback._id,
    session: sessionId
      ? `Session ${sessionId}`
      : `${userName} with ${mentorName}`,
    issue:
      String(feedback.complaintText || '').trim() ||
      String(feedback.sessionComment || '').trim() ||
      'No issue provided',
    rating: Number(feedback.sessionRating || feedback.mentorRating || feedback.appRating || 0),
    status,
  };
}

const getDashboardStatsCompat = asyncHandler(async (req, res) => {
  const summary = await adminService.getDashboardSummary();

  const topCareerPaths = Array.isArray(summary.popularCareerPaths)
    ? summary.popularCareerPaths
    : [];

  const topFields = topCareerPaths.slice(0, 3).map((item) => ({
    title: item.careerName || 'Unknown',
    count: Number(item.count || 0),
    subtitle: `${Number(item.count || 0)} mentor${Number(item.count || 0) !== 1 ? 's' : ''}`,
  }));

  const mentorResult = await adminService.getMentors({ page: 1, limit: 3 });
  const mentorItems = Array.isArray(mentorResult?.items) ? mentorResult.items : [];

  const recentMentors = mentorItems.slice(0, 3).map((profile) => {
    const mapped = mapMentorToDashboardShape(profile);
    return {
      name: mapped.name,
      area: mapped.field,
      status: mapped.status,
      sessions: mapped.sessions,
    };
  });

  res.status(200).json({
    totalUsers: Number(summary.totalUsers || 0),
    totalMentors: Number(summary.totalMentors || 0),
    totalCareerPaths: Number(topCareerPaths.length || 0),
    activeSessions: Number(summary.activeSessions || 0),
    averageMentorRating: 0,
    topFields,
    recentMentors,
  });
});

const getUsersCompat = asyncHandler(async (req, res) => {
  const result = await adminService.getUsers(req.query);
  const users = Array.isArray(result?.items) ? result.items : [];
  res.status(200).json(users.map(mapUserToDashboardShape));
});

const updateUserCompat = asyncHandler(async (req, res) => {
  const body = req.body || {};

  const updated = await adminService.updateUserStatus(req.params.userId, {
    isActive: body.status !== 'Blocked',
    blockReason: body.blockReason || '',
    blockNote: body.blockNote || '',
    blockedAt: body.blockedAt || null,
    blockedBy: body.blockedBy || '',
  });

  res.status(200).json(mapUserToDashboardShape(updated));
});

const deleteUserCompat = asyncHandler(async (req, res) => {
  const deleted = await adminService.deleteUser(req.params.userId);

  res.status(200).json({
    message: deleted?.message || 'User deleted successfully',
  });
});

const getMentorsCompat = asyncHandler(async (req, res) => {
  const result = await adminService.getMentors(req.query);
  const mentors = Array.isArray(result?.items) ? result.items : [];
  res.status(200).json(mentors.map(mapMentorToDashboardShape));
});

const updateMentorCompat = asyncHandler(async (req, res) => {
  const { mentorId } = req.params;
  const body = req.body || {};

  const profile = await MentorProfile.findById(mentorId).populate(
    'userId',
    'fullName email role isActive'
  );

  if (!profile) {
    throw new Error('Mentor profile not found');
  }

  const user = profile.userId;
  if (!user) {
    throw new Error('Mentor user not found');
  }

  if (body.name !== undefined) {
    user.fullName = String(body.name || '').trim();
  }

  if (body.email !== undefined) {
    user.email = String(body.email || '').trim().toLowerCase();
  }

  if (body.field !== undefined) {
    profile.careerField = String(body.field || '').trim();
  }

  if (body.rating !== undefined) {
    profile.ratingAverage = Number(body.rating || 0);
  }

  if (body.sessions !== undefined) {
    profile.totalSessions = Number(body.sessions || 0);
  }

  const normalizedStatus = String(body.status || '').trim().toLowerCase();

  if (normalizedStatus === 'active') {
    profile.isVerified = true;
    profile.isAvailable = true;
    user.isActive = true;
  } else if (normalizedStatus === 'pending') {
    profile.isVerified = false;
    profile.isAvailable = true;
    user.isActive = true;
  } else if (normalizedStatus === 'rejected') {
    profile.isVerified = false;
    profile.isAvailable = false;
    user.isActive = false;
  }

  await user.save();
  await profile.save();

  const refreshed = await MentorProfile.findById(profile._id).populate(
    'userId',
    'fullName email role isActive'
  );

  res.status(200).json(mapMentorToDashboardShape(refreshed));
});

const deleteMentorCompat = asyncHandler(async (req, res) => {
  const { mentorId } = req.params;

  const profile = await MentorProfile.findById(mentorId).populate(
    'userId',
    'fullName email role isActive'
  );

  if (!profile) {
    throw new Error('Mentor profile not found');
  }

  if (profile.userId) {
    profile.userId.role = 'user';
    await profile.userId.save();
  }

  await profile.deleteOne();

  res.status(200).json({
    message: 'Mentor deleted successfully',
  });
});

const getCareerPathsCompat = asyncHandler(async (req, res) => {
  const result = await adminService.getCareers(req.query);
  const careers = Array.isArray(result?.items) ? result.items : [];
  res.status(200).json(careers.map(mapCareerToDashboardShape));
});

const createCareerPathCompat = asyncHandler(async (req, res) => {
  const body = req.body || {};

  const skills = String(body.skills || '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);

  const created = await adminService.createCareer({
    name: body.path,
    skills,
    requiredSkills: skills,
    description: '',
  });

  res.status(201).json(mapCareerToDashboardShape(created));
});

const updateCareerPathCompat = asyncHandler(async (req, res) => {
  const body = req.body || {};

  const skills = String(body.skills || '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);

  const updated = await adminService.updateCareer(req.params.careerPathId, {
    name: body.path,
    skills,
    requiredSkills: skills,
  });

  res.status(200).json(mapCareerToDashboardShape(updated));
});

const deleteCareerPathCompat = asyncHandler(async (req, res) => {
  const deleted = await adminService.deleteCareer(req.params.careerPathId);

  res.status(200).json({
    message: deleted?.deleted
      ? 'Career path deleted successfully'
      : 'Career path deleted successfully',
  });
});

const getFeedbackCompat = asyncHandler(async (req, res) => {
  const items = await SessionFeedback.find()
    .populate('userId', 'fullName email')
    .populate('mentorUserId', 'fullName email')
    .populate('sessionId')
    .sort({ createdAt: -1 });

  res.status(200).json(items.map(mapFeedbackToDashboardShape));
});

const updateFeedbackCompat = asyncHandler(async (req, res) => {
  const { feedbackId } = req.params;
  const body = req.body || {};

  let complaintStatus = 'open';
  const normalizedStatus = String(body.status || '').trim().toLowerCase();

  if (normalizedStatus === 'resolved') {
    complaintStatus = 'resolved';
  } else if (normalizedStatus === 'under review') {
    complaintStatus = 'reviewed';
  }

  const updated = await adminService.updateComplaintStatus(feedbackId, {
    complaintStatus,
    complaintAdminNote: '',
  });

  const populated = await SessionFeedback.findById(updated._id)
    .populate('userId', 'fullName email')
    .populate('mentorUserId', 'fullName email')
    .populate('sessionId');

  res.status(200).json(mapFeedbackToDashboardShape(populated));
});

const deleteFeedbackCompat = asyncHandler(async (req, res) => {
  const feedback = await SessionFeedback.findById(req.params.feedbackId);

  if (!feedback) {
    throw new Error('Feedback not found');
  }

  await feedback.deleteOne();

  res.status(200).json({
    message: 'Feedback deleted successfully',
  });
});

const getAnalyticsCompat = asyncHandler(async (req, res) => {
  const overview = await adminService.getAnalyticsOverview();

  const growthBars = [
    { label: 'Users', value: Number(overview.totalUsers || 0) },
    { label: 'Mentors', value: Number(overview.totalMentors || 0) },
    { label: 'Paths', value: Number((overview.popularCareerPaths || []).length || 0) },
    { label: 'Feedback', value: Number(overview.openComplaints || 0) },
    { label: 'Sessions', value: Number(overview.activeSessions || 0) },
    { label: 'Ratings', value: 0 },
  ];

  res.status(200).json({
    totalUsers: Number(overview.totalUsers || 0),
    totalMentors: Number(overview.totalMentors || 0),
    totalCareerPaths: Number((overview.popularCareerPaths || []).length || 0),
    totalFeedback: Number(overview.openComplaints || 0),
    totalSessions: Number(overview.activeSessions || 0),
    averageMentorRating: 0,
    growthBars,
  });
});

const getPaymentsCompat = asyncHandler(async (req, res) => {
  const result = await adminService.getTransactions(req.query);
  const transactions = Array.isArray(result?.items) ? result.items : [];

  const mapped = transactions.map((tx) => ({
    id: String(tx._id || ''),
    user: tx.userId?.fullName || tx.userId?.email || 'Unknown User',
    amount: Number(tx.amount || 0),
    currency: tx.currency || 'EGP',
    type: tx.type || '',
    provider: tx.provider || 'internal',
    status: tx.status || 'pending',
    entityType: tx.entityType || 'other',
    providerStatus: tx.providerStatus || '',
    reference: tx.reference || tx.providerReference || '',
    date: tx.createdAt
      ? new Date(tx.createdAt).toISOString().slice(0, 10)
      : '',
  }));

  res.status(200).json(mapped);
});

const getPaymentsSummaryCompat = asyncHandler(async (req, res) => {
  const transactions = await Transaction.find()
    .populate('userId', 'fullName email')
    .sort({ createdAt: -1 });

  const totalTransactionVolume = transactions.reduce(
    (sum, tx) => sum + Number(tx.amount || 0),
    0
  );

  const walletTopups = transactions
    .filter((tx) => tx.entityType === 'wallet_topup')
    .reduce((sum, tx) => sum + Number(tx.amount || 0), 0);

  const pendingTransactions = transactions
    .filter((tx) => tx.status === 'pending')
    .reduce((sum, tx) => sum + Number(tx.amount || 0), 0);

  res.status(200).json({
    totalTransactionVolume,
    walletTopups,
    pendingTransactions,
  });
});
const getSettingsCompat = asyncHandler(async (req, res) => {
  const settings = await settingsService.getAppSettings();

  res.status(200).json({
    whatsappEnabled: Boolean(settings.support?.whatsappEnabled),
    supportEmail: String(settings.support?.supportEmail || ''),
    walletEnabled: Boolean(settings.payments?.walletEnabled),
    fawryEnabled: Boolean(settings.payments?.fawryEnabled),
    platformFeePercent: Number(settings.payments?.platformFeePercent || 0),
    mentorSessionsEnabled: Boolean(settings.mentorSessions?.enabled),
    minDurationMinutes: Number(settings.mentorSessions?.minDurationMinutes || 15),
    maxDurationMinutes: Number(settings.mentorSessions?.maxDurationMinutes || 60),
    userJoinGraceMinutes: Number(
      settings.mentorSessions?.userJoinGraceMinutes || 5
    ),
    eventsEnabled: Boolean(settings.events?.enabled),
    complaintsEnabled: Boolean(settings.complaints?.enabled),
  });
});

const updateSettingsCompat = asyncHandler(async (req, res) => {
  const body = req.body || {};

  const updated = await settingsService.updateAppSettings({
    support: {
      whatsappEnabled: Boolean(body.whatsappEnabled),
      supportEmail: String(body.supportEmail || '').trim(),
    },
    payments: {
      walletEnabled: Boolean(body.walletEnabled),
      fawryEnabled: Boolean(body.fawryEnabled),
      platformFeePercent: Number(body.platformFeePercent || 0),
    },
    mentorSessions: {
      enabled: Boolean(body.mentorSessionsEnabled),
      minDurationMinutes: Number(body.minDurationMinutes || 15),
      maxDurationMinutes: Number(body.maxDurationMinutes || 60),
      userJoinGraceMinutes: Number(body.userJoinGraceMinutes || 5),
    },
    events: {
      enabled: Boolean(body.eventsEnabled),
    },
    complaints: {
      enabled: Boolean(body.complaintsEnabled),
    },
  });
    await auditService.createAuditLog({
    action: 'settings_updated',
    entityType: 'app_settings',
    entityId: null,
    message: `Platform settings updated by ${req.user?.email || 'admin'}`,
    performedByUserId: req.user?._id || null,
    performedByEmail: req.user?.email || 'admin',
    metadata: {
      supportEmail: updated.support?.supportEmail || '',
      walletEnabled: Boolean(updated.payments?.walletEnabled),
      fawryEnabled: Boolean(updated.payments?.fawryEnabled),
      platformFeePercent: Number(updated.payments?.platformFeePercent || 0),
      mentorSessionsEnabled: Boolean(updated.mentorSessions?.enabled),
      eventsEnabled: Boolean(updated.events?.enabled),
      complaintsEnabled: Boolean(updated.complaints?.enabled),
    },
  });

  res.status(200).json({
    whatsappEnabled: Boolean(updated.support?.whatsappEnabled),
    supportEmail: String(updated.support?.supportEmail || ''),
    walletEnabled: Boolean(updated.payments?.walletEnabled),
    fawryEnabled: Boolean(updated.payments?.fawryEnabled),
    platformFeePercent: Number(updated.payments?.platformFeePercent || 0),
    mentorSessionsEnabled: Boolean(updated.mentorSessions?.enabled),
    minDurationMinutes: Number(updated.mentorSessions?.minDurationMinutes || 15),
    maxDurationMinutes: Number(updated.mentorSessions?.maxDurationMinutes || 60),
    userJoinGraceMinutes: Number(
      updated.mentorSessions?.userJoinGraceMinutes || 5
    ),
    eventsEnabled: Boolean(updated.events?.enabled),
    complaintsEnabled: Boolean(updated.complaints?.enabled),
  });
});

const getSettingsSecurityLogsCompat = asyncHandler(async (req, res) => {
  const logs = await auditService.getRecentAuditLogs(20);

  res.status(200).json(
    logs.map((log) => ({
      message: log.message,
      createdAt: log.createdAt,
      action: log.action,
      entityType: log.entityType,
      performedByEmail:
        log.performedByEmail ||
        log.performedByUserId?.email ||
        '',
    }))
  );
});

function buildEventAvailability(event) {
  const capacity = Number(event.capacity || 0);
  const registeredCount = Number(event.registeredCount || 0);
  const availableSeats = Math.max(capacity - registeredCount, 0);

  let registrationState = 'closed';

  if (event.status === 'published' && event.scheduledAt && new Date(event.scheduledAt) > new Date()) {
    registrationState = availableSeats <= 0 ? 'full' : 'open';
  }

  return {
    capacity,
    registeredCount,
    availableSeats,
    isFull: availableSeats <= 0,
    registrationState,
  };
}

function mapEventToDashboardShape(event) {
  const obj = event.toObject ? event.toObject() : event;
  const organizer = obj.organizerUserId || {};

  return {
    ...obj,
    organizerName: organizer.fullName || organizer.name || organizer.email || 'Unknown',
    organizerEmail: organizer.email || '',
    availability: buildEventAvailability(obj),
  };
}

function ensureFutureDate(dateValue) {
  const date = new Date(dateValue);

  if (Number.isNaN(date.getTime())) {
    throw new Error('Invalid event date');
  }

  if (date <= new Date()) {
    throw new Error('Event must be scheduled in the future');
  }

  return date;
}
const getPendingEventRequestsCompat = asyncHandler(async (req, res) => {
  const events = await GroupEvent.find({ status: 'pending_review' })
    .sort({ submittedAt: 1, createdAt: 1 })
    .populate('organizerUserId', 'fullName email phoneNumber role')
    .populate('speakers.mentorUserId', 'fullName email')
    .populate('speakers.mentorProfileId');

  res.status(200).json(events.map(mapEventToDashboardShape));
});

const getEventsCompat = asyncHandler(async (req, res) => {
  const query = {};

  if (req.query.status) {
    query.status = req.query.status;
  }

  const events = await GroupEvent.find(query)
    .sort({ createdAt: -1 })
    .populate('organizerUserId', 'fullName email phoneNumber role')
    .populate('speakers.mentorUserId', 'fullName email')
    .populate('speakers.mentorProfileId');

  res.status(200).json(events.map(mapEventToDashboardShape));
});

const approveEventRequestCompat = asyncHandler(async (req, res) => {
  const { eventId } = req.params;
  const body = req.body || {};

  const event = await GroupEvent.findById(eventId);

  if (!event) {
    throw new Error('Event not found');
  }

  if (event.status !== 'pending_review') {
    throw new Error('Only pending event requests can be approved');
  }

  const finalScheduledAt = body.scheduledAt || event.requestedScheduledAt;

  if (!finalScheduledAt) {
    throw new Error('scheduledAt is required before approval');
  }

  event.scheduledAt = ensureFutureDate(finalScheduledAt);
  event.durationMinutes = Number(
    body.durationMinutes || event.requestedDurationMinutes || event.durationMinutes || 60
  );
  event.capacity = Number(body.capacity || event.requestedCapacity || event.capacity || 100);

  event.fee =
    body.fee !== undefined
      ? Number(body.fee)
      : event.requestedFee !== null && event.requestedFee !== undefined
      ? Number(event.requestedFee)
      : Number(event.fee || 0);

  event.currency = body.currency || event.currency || 'EGP';

  if (body.meetingProvider !== undefined) {
    event.meetingProvider = body.meetingProvider;
  }

  if (body.meetingLink !== undefined) {
    event.meetingLink = body.meetingLink;
  }

  event.adminNotes = body.adminNotes || '';
  event.status = 'approved';
  event.adminReviewedBy = req.user?._id || null;
  event.adminReviewedAt = new Date();
  event.approvedAt = new Date();
  event.rejectionReason = '';

  await event.save();

  const populated = await GroupEvent.findById(event._id)
    .populate('organizerUserId', 'fullName email phoneNumber role')
    .populate('speakers.mentorUserId', 'fullName email')
    .populate('speakers.mentorProfileId');

  res.status(200).json(mapEventToDashboardShape(populated));
});

const rejectEventRequestCompat = asyncHandler(async (req, res) => {
  const { eventId } = req.params;
  const body = req.body || {};

  const event = await GroupEvent.findById(eventId);

  if (!event) {
    throw new Error('Event not found');
  }

  if (!['pending_review', 'approved'].includes(event.status)) {
    throw new Error('Only pending or approved event requests can be rejected');
  }

  event.status = 'rejected';
  event.adminReviewedBy = req.user?._id || null;
  event.adminReviewedAt = new Date();
  event.adminNotes = body.adminNotes || '';
  event.rejectionReason =
    body.rejectionReason || 'Event request was rejected by admin';
  event.approvedAt = null;

  await event.save();

  const populated = await GroupEvent.findById(event._id)
    .populate('organizerUserId', 'fullName email phoneNumber role')
    .populate('speakers.mentorUserId', 'fullName email')
    .populate('speakers.mentorProfileId');

  res.status(200).json(mapEventToDashboardShape(populated));
});

const publishEventCompat = asyncHandler(async (req, res) => {
  const { eventId } = req.params;

  const event = await GroupEvent.findById(eventId);

  if (!event) {
    throw new Error('Event not found');
  }

  if (event.status !== 'approved') {
    throw new Error('Only approved events can be published');
  }

  if (!event.scheduledAt) {
    throw new Error('Event scheduledAt is required before publishing');
  }

  ensureFutureDate(event.scheduledAt);

  if (Number(event.capacity || 0) <= 0) {
    throw new Error('Event capacity must be greater than 0');
  }

  if (Number(event.registeredCount || 0) >= Number(event.capacity || 0)) {
    throw new Error('Cannot publish a full event');
  }

  event.status = 'published';
  event.publishedAt = new Date();

  await event.save();

  const populated = await GroupEvent.findById(event._id)
    .populate('organizerUserId', 'fullName email phoneNumber role')
    .populate('speakers.mentorUserId', 'fullName email')
    .populate('speakers.mentorProfileId');

  res.status(200).json(mapEventToDashboardShape(populated));
});


module.exports = {
  getDashboardStatsCompat,
  getUsersCompat,
  updateUserCompat,
  deleteUserCompat,
  getMentorsCompat,
  updateMentorCompat,
  deleteMentorCompat,
  getCareerPathsCompat,
  createCareerPathCompat,
  updateCareerPathCompat,
  deleteCareerPathCompat,
  getFeedbackCompat,
  updateFeedbackCompat,
  deleteFeedbackCompat,
  getAnalyticsCompat,
  getPaymentsCompat,
  getPaymentsSummaryCompat,
  getSettingsCompat,
  updateSettingsCompat,
  getSettingsSecurityLogsCompat,

  getPendingEventRequestsCompat,
  getEventsCompat,
  approveEventRequestCompat,
  rejectEventRequestCompat,
  publishEventCompat,
};