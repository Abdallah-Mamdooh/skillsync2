const mongoose = require('mongoose');

const mentorSessionSchema = new mongoose.Schema(
  {
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

    method: {
      type: String,
      enum: ['chat', 'call'],
      required: true,
    },

    durationMinutes: {
      type: Number,
      required: true,
      min: 15,
      max: 60,
    },

    scheduledDate: {
      type: String,
      required: true, // YYYY-MM-DD
      index: true,
    },

    scheduledStartTime: {
      type: String,
      required: true, // HH:mm
    },

    scheduledEndTime: {
      type: String,
      required: true, // HH:mm
    },

    timezone: {
      type: String,
      default: 'Africa/Cairo',
      trim: true,
    },

    startAt: {
      type: Date,
      default: null,
      index: true,
    },

    endAt: {
      type: Date,
      default: null,
      index: true,
    },

    noShowDeadline: {
      type: Date,
      default: null,
    },

    baseRate: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },

    multiplier: {
      type: Number,
      required: true,
      min: 0,
      default: 1,
    },

    subtotal: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },

    platformFee: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },

    totalAmount: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },

    mentorNetAmount: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },

    currency: {
      type: String,
      default: 'EGP',
      trim: true,
    },

    status: {
      type: String,
      enum: [
        'scheduled',
        'started',
        'active',
        'completed',
        'cancelled',
        'expired',
        'user_no_show',
      ],
      default: 'scheduled',
      index: true,
    },

    paymentStatus: {
      type: String,
      enum: [
        'unpaid',
        'hold_pending',
        'held',
        'captured',
        'released',
        'refunded',
        'failed',
      ],
      default: 'unpaid',
      index: true,
    },

    meetingProvider: {
      type: String,
      enum: ['google_meet', 'zoom', 'other', 'none'],
      default: 'none',
    },

    meetingLink: {
      type: String,
      trim: true,
      default: '',
    },

    chatRoomId: {
      type: String,
      trim: true,
      default: '',
    },

    requestedAt: {
      type: Date,
      default: Date.now,
    },

    acceptedAt: {
      type: Date,
      default: null,
    },

    startedAt: {
      type: Date,
      default: null,
    },

    endedAt: {
      type: Date,
      default: null,
    },

    expiresAt: {
      type: Date,
      default: null,
    },

    actualDurationMinutes: {
      type: Number,
      default: 0,
      min: 0,
    },

    userNotes: {
      type: String,
      trim: true,
      default: '',
    },
  },
  { timestamps: true }
);

mentorSessionSchema.index({
  mentorProfileId: 1,
  scheduledDate: 1,
  scheduledStartTime: 1,
});

module.exports = mongoose.model('MentorSession', mentorSessionSchema);