const User = require('../auth/user.model');
const UserAssessmentResult = require('../assessment/userAssessmentResult.model');
const UserRoadmapProgress = require('../roadmap/userRoadmapProgress.model');
const MentorProfile = require('../mentor/mentorProfile.model');
const MentorSession = require('../mentor/mentorSession.model');
const EventRegistration = require('../events/eventRegistration.model');
const GroupEvent = require('../events/groupEvent.model');
const Notification = require('../notification/notification.model');
const SessionFeedback = require('../mentor/sessionFeedback.model');
const Wallet = require('../payment/wallet.model');

const getUserDashboardSummary = async (userId) => {
  const user = await User.findById(userId).select(
    'fullName email phoneNumber role skills cvUrl assessmentCompleted'
  );

  if (!user) {
    throw new Error('User not found');
  }

  const unreadNotifications = await Notification.countDocuments({
    userId,
    isRead: false,
  });

  const assessment = await UserAssessmentResult.findOne({ userId }).populate('chosenCareer');

  const roadmapProgress = await UserRoadmapProgress.findOne({ userId })
    .populate('careerId', 'name')
    .populate('roadmapId');

  const mySessions = await MentorSession.find({
    userId,
    status: { $in: ['pending', 'accepted', 'active'] },
  })
    .populate('mentorUserId', 'fullName email')
    .sort({ createdAt: -1 })
    .limit(5);

  const myEventRegistrations = await EventRegistration.find({ userId })
    .populate('eventId')
    .sort({ createdAt: -1 })
    .limit(5);

  return {
    profile: user,
    unreadNotifications,
    chosenCareer: assessment?.chosenCareer
      ? {
          id: assessment.chosenCareer._id,
          name: assessment.chosenCareer.name,
        }
      : null,
    roadmap: roadmapProgress
      ? {
          careerId: roadmapProgress.careerId?._id || null,
          careerName: roadmapProgress.careerId?.name || '',
          completionPercent: roadmapProgress.completionPercent || 0,
          completedStepsCount: Array.isArray(roadmapProgress.completedSteps)
            ? roadmapProgress.completedSteps.length
            : 0,
        }
      : null,
    skillsCount: Array.isArray(user.skills) ? user.skills.length : 0,
    upcomingSessions: mySessions.map((s) => ({
      id: s._id,
      mentorName: s.mentorUserId?.fullName || '',
      method: s.method,
      durationMinutes: s.durationMinutes,
      status: s.status,
      totalAmount: s.totalAmount,
      currency: s.currency,
      acceptedAt: s.acceptedAt,
      startedAt: s.startedAt,
      expiresAt: s.expiresAt,
    })),
    upcomingEvents: myEventRegistrations
      .filter((r) => r.eventId)
      .map((r) => ({
        registrationId: r._id,
        eventId: r.eventId?._id || null,
        title: r.eventId?.title || '',
        scheduledAt: r.eventId?.scheduledAt || null,
        paymentStatus: r.paymentStatus,
        attended: r.attended,
      })),
  };
};

const getMentorDashboardSummary = async (userId) => {
  const user = await User.findById(userId).select(
    'fullName email phoneNumber role skills cvUrl assessmentCompleted'
  );

  if (!user) {
    throw new Error('User not found');
  }

  const mentorProfile = await MentorProfile.findOne({ userId });

  if (!mentorProfile) {
    throw new Error('Mentor profile not found');
  }

  const unreadNotifications = await Notification.countDocuments({
    userId,
    isRead: false,
  });

  const pendingSessionsCount = await MentorSession.countDocuments({
    mentorUserId: userId,
    status: 'pending',
  });

  const liveSessions = await MentorSession.find({
    mentorUserId: userId,
    status: { $in: ['accepted', 'active'] },
  })
    .populate('userId', 'fullName email')
    .sort({ createdAt: -1 })
    .limit(5);

  const wallet = await Wallet.findOne({ userId });

  const feedbackCount = await SessionFeedback.countDocuments({
    mentorUserId: userId,
  });

  const upcomingSpeakerEvents = await GroupEvent.find({
    'speakers.mentorUserId': userId,
    status: 'published',
  })
    .sort({ scheduledAt: 1 })
    .limit(5);

  const organizedEvents = await GroupEvent.find({
    organizerUserId: userId,
  })
    .sort({ createdAt: -1 })
    .limit(5);

  return {
    profile: user,
    mentorProfile: {
      id: mentorProfile._id,
      headline: mentorProfile.headline,
      specialization: mentorProfile.specialization,
      careerField: mentorProfile.careerField,
      yearsOfExperience: mentorProfile.yearsOfExperience,
      isVerified: mentorProfile.isVerified,
      isAvailable: mentorProfile.isAvailable,
      supportsChat: mentorProfile.supportsChat,
      supportsCall: mentorProfile.supportsCall,
      baseRate: mentorProfile.baseRate,
      currency: mentorProfile.currency,
      quotaLabel: mentorProfile.quotaLabel,
      ratingAverage: mentorProfile.ratingAverage,
      ratingCount: mentorProfile.ratingCount,
      totalSessions: mentorProfile.totalSessions,
    },
    unreadNotifications,
    pendingSessionsCount,
    liveSessions: liveSessions.map((s) => ({
      id: s._id,
      requesterName: s.userId?.fullName || '',
      requesterEmail: s.userId?.email || '',
      method: s.method,
      durationMinutes: s.durationMinutes,
      status: s.status,
      totalAmount: s.totalAmount,
      currency: s.currency,
      acceptedAt: s.acceptedAt,
      startedAt: s.startedAt,
      expiresAt: s.expiresAt,
    })),
    wallet: wallet
      ? {
          availableBalance: wallet.availableBalance,
          heldBalance: wallet.heldBalance,
          currency: wallet.currency,
        }
      : {
          availableBalance: 0,
          heldBalance: 0,
          currency: mentorProfile.currency || 'EGP',
        },
    feedbackCount,
    upcomingSpeakerEvents: upcomingSpeakerEvents.map((e) => ({
      id: e._id,
      title: e.title,
      scheduledAt: e.scheduledAt,
      status: e.status,
      meetingProvider: e.meetingProvider,
    })),
    organizedEvents: organizedEvents.map((e) => ({
      id: e._id,
      title: e.title,
      scheduledAt: e.scheduledAt,
      status: e.status,
      registeredCount: e.registeredCount,
      capacity: e.capacity,
    })),
  };
};

module.exports = {
  getUserDashboardSummary,
  getMentorDashboardSummary,
};