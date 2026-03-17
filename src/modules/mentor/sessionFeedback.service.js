const SessionFeedback = require('./sessionFeedback.model');
const MentorSession = require('./mentorSession.model');
const MentorProfile = require('./mentorProfile.model');
const notificationService = require('../notification/notification.service');

function normalizeText(value) {
  return String(value || '').trim();
}

function validateRating(name, value) {
  const num = Number(value);

  if (!Number.isFinite(num) || num < 1 || num > 5) {
    throw new Error(`${name} must be between 1 and 5`);
  }

  return num;
}

async function recalculateMentorRatings(mentorProfileId) {
  const allFeedback = await SessionFeedback.find({ mentorProfileId });

  const count = allFeedback.length;

  if (count === 0) {
    await MentorProfile.findByIdAndUpdate(mentorProfileId, {
      ratingAverage: 0,
      ratingCount: 0,
    });

    return { ratingAverage: 0, ratingCount: 0 };
  }

  const total = allFeedback.reduce(
    (sum, item) => sum + Number(item.mentorRating || 0),
    0
  );

  const avg = total / count;
  const rounded = Math.round(avg * 10) / 10;

  await MentorProfile.findByIdAndUpdate(mentorProfileId, {
    ratingAverage: rounded,
    ratingCount: count,
  });

  return {
    ratingAverage: rounded,
    ratingCount: count,
  };
}

async function submitSessionFeedback(userId, payload) {
  const {
    sessionId,
    mentorRating,
    appRating,
    sessionRating,
    comment = '',
    complaintText = '',
    complaintCategory = 'none',
  } = payload;

  if (!sessionId) {
    throw new Error('sessionId is required');
  }

  const session = await MentorSession.findById(sessionId);

  if (!session) {
    throw new Error('Session not found');
  }

  if (String(session.userId) !== String(userId)) {
    throw new Error('You are not allowed to submit feedback for this session');
  }

  if (session.status !== 'completed') {
    throw new Error('Feedback can only be submitted for completed sessions');
  }

  const existing = await SessionFeedback.findOne({ sessionId });
  if (existing) {
    throw new Error('Feedback already submitted for this session');
  }

  const cleanComment = normalizeText(comment);
  const cleanComplaintText = normalizeText(complaintText);
  const cleanComplaintCategory = normalizeText(complaintCategory) || 'none';

  const finalMentorRating = validateRating('mentorRating', mentorRating);
  const finalAppRating = validateRating('appRating', appRating);
  const finalSessionRating = validateRating('sessionRating', sessionRating);

  const hasComplaint = Boolean(cleanComplaintText);

  if (hasComplaint && cleanComplaintCategory === 'none') {
    throw new Error('complaintCategory is required when complaintText is provided');
  }

  if (!hasComplaint && cleanComplaintCategory !== 'none') {
    throw new Error('complaintCategory must be "none" when no complaintText is provided');
  }

  const feedback = await SessionFeedback.create({
    sessionId: session._id,
    userId,
    mentorProfileId: session.mentorProfileId,
    mentorUserId: session.mentorUserId,
    mentorRating: finalMentorRating,
    appRating: finalAppRating,
    sessionRating: finalSessionRating,
    comment: cleanComment,
    complaintText: cleanComplaintText,
    complaintCategory: hasComplaint ? cleanComplaintCategory : 'none',
    complaintStatus: hasComplaint ? 'open' : 'none',
    complaintReviewedAt: null,
    complaintResolvedAt: null,
  });

  const mentorRatingSummary = await recalculateMentorRatings(session.mentorProfileId);

  await notificationService.createNotification({
    userId: session.mentorUserId,
    type: 'session_feedback_received',
    title: 'New feedback received',
    message: hasComplaint
      ? 'A user submitted feedback and a complaint for one of your sessions.'
      : 'A user submitted feedback for one of your sessions.',
    data: {
      sessionId: session._id,
      feedbackId: feedback._id,
      mentorRating: feedback.mentorRating,
      complaintStatus: feedback.complaintStatus,
      complaintCategory: feedback.complaintCategory,
    },
  });

  if (hasComplaint) {
    await notificationService.createNotification({
      userId,
      type: 'complaint_submitted',
      title: 'Complaint submitted',
      message: 'Your complaint was submitted successfully and is now under review.',
      data: {
        sessionId: session._id,
        feedbackId: feedback._id,
        complaintStatus: feedback.complaintStatus,
        complaintCategory: feedback.complaintCategory,
      },
    });
  }

  return {
    feedback,
    mentorRatingSummary,
  };
}

async function getMyFeedbackForSession(userId, sessionId) {
  const feedback = await SessionFeedback.findOne({ sessionId, userId });

  if (!feedback) {
    return null;
  }

  return feedback;
}

async function getMentorFeedbackSummary(mentorUserId) {
  const mentorProfile = await MentorProfile.findOne({ userId: mentorUserId });

  if (!mentorProfile) {
    throw new Error('Mentor profile not found');
  }

  const feedbackList = await SessionFeedback.find({
    mentorProfileId: mentorProfile._id,
  })
    .populate('sessionId')
    .populate('userId', 'fullName email')
    .sort({ createdAt: -1 });

  const totalFeedback = feedbackList.length;
  const complaintsCount = feedbackList.filter((f) => f.complaintStatus !== 'none').length;
  const openComplaintsCount = feedbackList.filter((f) => f.complaintStatus === 'open').length;

  return {
    ratingAverage: mentorProfile.ratingAverage || 0,
    ratingCount: mentorProfile.ratingCount || 0,
    totalFeedback,
    complaintsCount,
    openComplaintsCount,
    feedback: feedbackList,
  };
}

async function getOpenComplaints(mentorUserId) {
  const mentorProfile = await MentorProfile.findOne({ userId: mentorUserId });

  if (!mentorProfile) {
    throw new Error('Mentor profile not found');
  }

  return SessionFeedback.find({
    mentorProfileId: mentorProfile._id,
    complaintStatus: 'open',
  })
    .populate('sessionId')
    .populate('userId', 'fullName email')
    .sort({ createdAt: -1 });
}

module.exports = {
  submitSessionFeedback,
  getMyFeedbackForSession,
  getMentorFeedbackSummary,
  getOpenComplaints,
  recalculateMentorRatings,
};