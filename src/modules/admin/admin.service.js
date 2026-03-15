const MentorProfile = require('../mentor/mentorProfile.model');
const SessionFeedback = require('../mentor/sessionFeedback.model');
const notificationService = require('../notification/notification.service');

const getAllMentorProfiles = async () => {
  return MentorProfile.find()
    .populate('userId', 'fullName email phoneNumber role cvUrl isActive')
    .sort({ createdAt: -1 });
};

const getPendingMentorProfiles = async () => {
  return MentorProfile.find({ isVerified: false })
    .populate('userId', 'fullName email phoneNumber role cvUrl isActive')
    .sort({ createdAt: -1 });
};

const verifyMentorProfile = async (mentorProfileId) => {
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
};

const unverifyMentorProfile = async (mentorProfileId) => {
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
};

const getOpenComplaints = async () => {
  return SessionFeedback.find({
    complaintStatus: 'open',
  })
    .populate('userId', 'fullName email')
    .populate('mentorUserId', 'fullName email')
    .populate('mentorProfileId')
    .populate('sessionId')
    .sort({ createdAt: -1 });
};

const updateComplaintStatus = async (feedbackId, complaintStatus) => {
  const allowed = ['open', 'reviewed', 'resolved'];
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
  await feedback.save();

  await notificationService.createNotification({
    userId: feedback.userId,
    type: 'complaint_status_updated',
    title: 'Complaint status updated',
    message: `Your complaint status is now: ${complaintStatus}.`,
    data: {
      feedbackId: feedback._id,
      complaintStatus,
      sessionId: feedback.sessionId,
    },
  });

  return feedback;
};

module.exports = {
  getAllMentorProfiles,
  getPendingMentorProfiles,
  verifyMentorProfile,
  unverifyMentorProfile,
  getOpenComplaints,
  updateComplaintStatus,
};