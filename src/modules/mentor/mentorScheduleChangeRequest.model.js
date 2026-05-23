const mongoose = require('mongoose');

const availabilityRangeSchema = new mongoose.Schema(
  {
    dayOfWeek: {
      type: Number,
      required: true,
      min: 0,
      max: 6,
    },
    startTime: {
      type: String,
      required: true,
      trim: true,
    },
    endTime: {
      type: String,
      required: true,
      trim: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { _id: false }
);

const mentorScheduleChangeRequestSchema = new mongoose.Schema(
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

    currentAvailability: {
      type: [availabilityRangeSchema],
      default: [],
    },

    requestedAvailability: {
      type: [availabilityRangeSchema],
      required: true,
      default: [],
    },

    reason: {
      type: String,
      trim: true,
      default: '',
    },

    effectiveFrom: {
      type: Date,
      required: true,
      index: true,
    },

    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected', 'applied'],
      default: 'pending',
      index: true,
    },

    reviewedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    reviewedAt: {
      type: Date,
      default: null,
    },

    adminNote: {
      type: String,
      trim: true,
      default: '',
    },

    appliedAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

mentorScheduleChangeRequestSchema.index({
  mentorProfileId: 1,
  status: 1,
});

module.exports = mongoose.model(
  'MentorScheduleChangeRequest',
  mentorScheduleChangeRequestSchema
);