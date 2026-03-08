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
    },

    complaintText: {
      type: String,
      trim: true,
      default: '',
    },

    complaintStatus: {
      type: String,
      enum: ['none', 'open', 'reviewed', 'resolved'],
      default: 'none',
      index: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('SessionFeedback', sessionFeedbackSchema);