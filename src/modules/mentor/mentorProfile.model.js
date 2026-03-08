const mongoose = require('mongoose');

const certificationSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    issuer: { type: String, trim: true },
    issueDate: { type: Date },
    certificateUrl: { type: String, trim: true },
  },
  { _id: false }
);

const identityDocSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['national_id', 'passport', 'license', 'other'],
      required: true,
    },
    documentUrl: { type: String, required: true, trim: true },
  },
  { _id: false }
);

const mentorProfileSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
      index: true,
    },

    headline: {
      type: String,
      trim: true,
      default: '',
    },

    bio: {
      type: String,
      trim: true,
      default: '',
    },

    specialization: [
      {
        type: String,
        trim: true,
      },
    ],

    careerField: {
      type: String,
      trim: true,
      default: '',
    },

    yearsOfExperience: {
      type: Number,
      default: 0,
      min: 0,
    },

    linkedinUrl: {
      type: String,
      trim: true,
      default: '',
    },

    portfolioUrl: {
      type: String,
      trim: true,
      default: '',
    },

    mentorCvUrl: {
      type: String,
      trim: true,
      default: '',
    },

    certifications: {
      type: [certificationSchema],
      default: [],
    },

    identityDocs: {
      type: [identityDocSchema],
      default: [],
    },

    isVerified: {
      type: Boolean,
      default: false,
    },

    isAvailable: {
      type: Boolean,
      default: true,
    },

    supportsChat: {
      type: Boolean,
      default: true,
    },

    supportsCall: {
      type: Boolean,
      default: false,
    },

    baseRate: {
      type: Number,
      required: true,
      default: 0,
      min: 0,
    },

    chatMultiplier: {
      type: Number,
      default: 1,
      min: 0,
    },

    callMultiplier: {
      type: Number,
      default: 1.5,
      min: 0,
    },

    currency: {
      type: String,
      default: 'EGP',
      trim: true,
    },

    quotaLabel: {
      type: String,
      trim: true,
      default: '',
    },

    ratingAverage: {
      type: Number,
      default: 0,
      min: 0,
      max: 5,
    },

    ratingCount: {
      type: Number,
      default: 0,
      min: 0,
    },

    totalSessions: {
      type: Number,
      default: 0,
      min: 0,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('MentorProfile', mentorProfileSchema);