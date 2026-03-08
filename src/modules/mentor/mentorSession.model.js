const mongoose = require('mongoose');

const mentorSessionSchema = new mongoose.Schema(
  {
    // student / user requesting help
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    // mentor profile selected
    mentorProfileId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MentorProfile',
      required: true,
      index: true,
    },

    // mentor base user id (useful for populate/filtering)
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

    // pricing snapshot at booking time
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
        'pending',
        'accepted',
        'rejected',
        'active',
        'completed',
        'cancelled',
        'expired',
      ],
      default: 'pending',
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

    // for call sessions using external provider
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

    // for chat sessions later
    chatRoomId: {
      type: String,
      trim: true,
      default: '',
    },

    // booking lifecycle
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

module.exports = mongoose.model('MentorSession', mentorSessionSchema);