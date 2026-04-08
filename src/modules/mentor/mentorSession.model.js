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
      required: true,
      index: true,
    },

    scheduledStartTime: {
      type: String,
      required: true,
    },

    scheduledEndTime: {
      type: String,
      required: true,
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
      index: true,
    },

    userJoinedAt: {
      type: Date,
      default: null,
    },

    payoutTransferred: {
      type: Boolean,
      default: false,
    },

    platformFeeLogged: {
      type: Boolean,
      default: false,
    },

    finalizationReason: {
      type: String,
      enum: [
        'normal_end',
        'manual_complete',
        'user_no_show',
        'cancelled',
        'expired',
        '',
      ],
      default: '',
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

    // actual session start time (set on first chat message or call join)
    startedAt: {
      type: Date,
      default: null,
      index: true,
    },

    endedAt: {
      type: Date,
      default: null,
      index: true,
    },

    expiresAt: {
      type: Date,
      default: null,
      index: true,
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

mentorSessionSchema.index({
  status: 1,
  noShowDeadline: 1,
});

mentorSessionSchema.index({
  status: 1,
  endAt: 1,
});

module.exports = mongoose.model('MentorSession', mentorSessionSchema);