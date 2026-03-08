const SessionFeedback = require('./sessionFeedback.model');
const MentorSession = require('./mentorSession.model');
const MentorProfile = require('./mentorProfile.model');
const notificationService = require('../notification/notification.service');
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

  const total = allFeedback.reduce((sum, item) => sum + Number(item.mentorRating || 0), 0);
  const avg = total / count;

  await MentorProfile.findByIdAndUpdate(mentorProfileId, {
    ratingAverage: Math.round(avg * 10) / 10,
    ratingCount: count,
  });

  return {
    ratingAverage: Math.round(avg * 10) / 10,
    ratingCount: count,
  };
}

const submitSessionFeedback = async (userId, payload) => {
  const {
    sessionId,
    mentorRating,
    appRating,
    sessionRating,
    comment = '',
    complaintText = '',
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

  const feedback = await SessionFeedback.create({
    sessionId: session._id,
    userId,
    mentorProfileId: session.mentorProfileId,
    mentorUserId: session.mentorUserId,
    mentorRating,
    appRating,
    sessionRating,
    comment,
    complaintText,
    complaintStatus: complaintText ? 'open' : 'none',
  });

  const mentorRatingSummary = await recalculateMentorRatings(session.mentorProfileId);
  await notificationService.createNotification({
    userId: session.mentorUserId,
    type: 'session_feedback_received',
    title: 'New feedback received',
    message: 'A user submitted feedback for one of your sessions.',
    data: {
      sessionId: session._id,
      feedbackId: feedback._id,
      mentorRating: feedback.mentorRating,
      complaintStatus: feedback.complaintStatus,
    },
  });
  return {
    feedback,
    mentorRatingSummary,
  };
};

const getMyFeedbackForSession = async (userId, sessionId) => {
  const feedback = await SessionFeedback.findOne({ sessionId, userId });

  if (!feedback) {
    return null;
  }

  return feedback;
};

const getMentorFeedbackSummary = async (mentorUserId) => {
  const mentorProfile = await MentorProfile.findOne({ userId: mentorUserId });

  if (!mentorProfile) {
    throw new Error('Mentor profile not found');
  }

  const feedbackList = await SessionFeedback.find({
    mentorProfileId: mentorProfile._id,
  }).sort({ createdAt: -1 });

  return {
    ratingAverage: mentorProfile.ratingAverage || 0,
    ratingCount: mentorProfile.ratingCount || 0,
    feedback: feedbackList,
  };
};

const getOpenComplaints = async (mentorUserId) => {
  const mentorProfile = await MentorProfile.findOne({ userId: mentorUserId });

  if (!mentorProfile) {
    throw new Error('Mentor profile not found');
  }

  return SessionFeedback.find({
    mentorProfileId: mentorProfile._id,
    complaintStatus: 'open',
  }).sort({ createdAt: -1 });
};

module.exports = {
  submitSessionFeedback,
  getMyFeedbackForSession,
  getMentorFeedbackSummary,
  getOpenComplaints,
};