const mongoose = require('mongoose');

const speakerSchema = new mongoose.Schema(
  {
    mentorProfileId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MentorProfile',
      required: true,
    },
    mentorUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    roleLabel: {
      type: String,
      trim: true,
      default: 'Speaker',
    },
  },
  { _id: false }
);

const groupEventSchema = new mongoose.Schema(
  {
    organizerUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    title: {
      type: String,
      required: true,
      trim: true,
    },

    description: {
      type: String,
      trim: true,
      default: '',
    },

    topic: {
      type: String,
      trim: true,
      default: '',
    },

    speakers: {
      type: [speakerSchema],
      default: [],
    },

    fee: {
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

    capacity: {
      type: Number,
      required: true,
      min: 1,
      default: 100,
    },

    registeredCount: {
      type: Number,
      default: 0,
      min: 0,
    },

    meetingProvider: {
      type: String,
      enum: ['google_meet', 'zoom', 'other'],
      required: true,
      default: 'google_meet',
    },

    meetingLink: {
      type: String,
      required: true,
      trim: true,
    },

    scheduledAt: {
      type: Date,
      required: true,
      index: true,
    },

    durationMinutes: {
      type: Number,
      required: true,
      min: 15,
      default: 60,
    },

    status: {
      type: String,
      enum: ['draft', 'published', 'cancelled', 'completed'],
      default: 'draft',
      index: true,
    },

    coverImageUrl: {
      type: String,
      trim: true,
      default: '',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('GroupEvent', groupEventSchema);