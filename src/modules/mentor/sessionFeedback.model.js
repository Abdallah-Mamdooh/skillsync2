const mongoose = require('mongoose');

const sessionFeedbackSchema = new mongoose.Schema(
  {
    sessionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MentorSession',
      required: true,
      unique: true,
      index: true,
    },

    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    mentorProfileId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MentorProfile',
      required: true,
      index: true,
    },

    mentorUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    mentorRating: {
      type: Number,
      required: true,
      min: 1,
      max: 5,
    },

    appRating: {
      type: Number,
      required: true,
      min: 1,
      max: 5,
    },

    sessionRating: {
      type: Number,
      required: true,
      min: 1,
      max: 5,
    },

    comment: {
      type: String,
      trim: true,
      default: '',
      maxlength: 1000,
    },

    complaintText: {
      type: String,
      trim: true,
      default: '',
      maxlength: 2000,
    },

    complaintCategory: {
      type: String,
      enum: [
        'none',
        'mentor_behavior',
        'late_start',
        'poor_guidance',
        'technical_issue',
        'payment_issue',
        'other',
      ],
      default: 'none',
      index: true,
    },

    complaintStatus: {
      type: String,
      enum: ['none', 'open', 'reviewed', 'resolved', 'dismissed'],
      default: 'none',
      index: true,
    },

    complaintAdminNote: {
      type: String,
      trim: true,
      default: '',
      maxlength: 2000,
    },

    complaintReviewedAt: {
      type: Date,
      default: null,
    },

    complaintResolvedAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('SessionFeedback', sessionFeedbackSchema);