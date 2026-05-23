const mongoose = require('mongoose');

const mentorAvailabilityExceptionSchema = new mongoose.Schema(
  {
    mentorUserId: {
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

    unavailableFrom: {
      type: Date,
      required: true,
      index: true,
    },

    unavailableTo: {
      type: Date,
      required: true,
      index: true,
    },

    reason: {
      type: String,
      trim: true,
      default: '',
    },

    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
  },
  { timestamps: true }
);

mentorAvailabilityExceptionSchema.index({
  mentorProfileId: 1,
  unavailableFrom: 1,
  unavailableTo: 1,
});

module.exports = mongoose.model(
  'MentorAvailabilityException',
  mentorAvailabilityExceptionSchema
);