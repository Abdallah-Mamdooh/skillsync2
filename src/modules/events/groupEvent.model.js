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

    eventType: {
      type: String,
      enum: ['workshop', 'webinar', 'qa_session', 'career_talk', 'other'],
      default: 'webinar',
      index: true,
    },

    targetAudience: {
      type: String,
      trim: true,
      default: '',
    },

    agenda: {
      type: String,
      trim: true,
      default: '',
    },

    learningOutcomes: {
      type: [String],
      default: [],
    },

    requirements: {
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
      default: 'google_meet',
    },

    // Important:
    // This is now optional because admins/owners will manage meeting links externally by email.
    meetingLink: {
      type: String,
      trim: true,
      default: '',
    },

    scheduledAt: {
      type: Date,
      default: null,
      index: true,
    },

    durationMinutes: {
      type: Number,
      min: 15,
      default: 60,
    },

    status: {
      type: String,
      enum: [
        'draft',
        'pending_review',
        'approved',
        'published',
        'rejected',
        'cancelled',
        'completed',
      ],
      default: 'draft',
      index: true,
    },

    coverImageUrl: {
      type: String,
      trim: true,
      default: '',
    },

    // Mentor request preferences
    requestedScheduledAt: {
      type: Date,
      default: null,
    },

    requestedDurationMinutes: {
      type: Number,
      min: 15,
      default: null,
    },

    requestedCapacity: {
      type: Number,
      min: 1,
      default: null,
    },

    requestedFee: {
      type: Number,
      min: 0,
      default: null,
    },

    mentorNotes: {
      type: String,
      trim: true,
      default: '',
    },

    submittedAt: {
      type: Date,
      default: null,
    },

    // Admin review data
    adminReviewedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    adminReviewedAt: {
      type: Date,
      default: null,
    },

    adminNotes: {
      type: String,
      trim: true,
      default: '',
    },

    rejectionReason: {
      type: String,
      trim: true,
      default: '',
    },

    approvedAt: {
      type: Date,
      default: null,
    },

    publishedAt: {
      type: Date,
      default: null,
    },

    closedAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

groupEventSchema.virtual('availableSeats').get(function () {
  return Math.max(Number(this.capacity || 0) - Number(this.registeredCount || 0), 0);
});

groupEventSchema.virtual('isFull').get(function () {
  return Number(this.registeredCount || 0) >= Number(this.capacity || 0);
});

groupEventSchema.set('toJSON', { virtuals: true });
groupEventSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('GroupEvent', groupEventSchema);