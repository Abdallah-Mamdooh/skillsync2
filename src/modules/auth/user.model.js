const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: true,
      trim: true,
    },

    profileImageUrl: {
      type: String,
      trim: true,
      default: '',
    },

    bio: {
      type: String,
      trim: true,
      default: '',
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },

    phoneNumber: {
      type: String,
      unique: true,
      sparse: true,
      trim: true,
      default: undefined,
    },

    password: {
      type: String,
      select: false,
      default: undefined,
    },

    authProvider: {
      type: String,
      enum: ['local', 'google'],
      default: 'local',
    },

    googleId: {
      type: String,
      unique: true,
      sparse: true,
      default: undefined,
    },

    passwordResetToken: String,
    passwordResetExpires: Date,

    role: {
      type: String,
      enum: ['user', 'mentor', 'admin'],
      required: true,
    },

    selectedInterests: [
      {
        type: String,
        trim: true,
      },
    ],

    skills: [
      {
        type: String,
        trim: true,
      },
    ],

    chosenCareer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Career',
      default: null,
      index: true,
    },

    cvUrl: {
      type: String,
      default: '',
    },

    assessmentCompleted: {
      type: Boolean,
      default: false,
    },

    mentorProfile: {
  linkedinUrl: {
    type: String,
    trim: true,
  },

  additionalInfo: {
    type: String,
    trim: true,
    default: '',
  },

  proposedHourlyRate: {
    type: Number,
    min: 0,
    default: 0,
  },

  payoutAccountInfo: {
  iv: String,
  content: String,
  authTag: String,
},

  isVerified: {
    type: Boolean,
    default: false,
  },
},

    isActive: {
      type: Boolean,
      default: true,
    },


        blockReason: {
      type: String,
      trim: true,
      default: '',
    },

    blockNote: {
      type: String,
      trim: true,
      default: '',
    },

    blockedAt: {
      type: Date,
      default: null,
    },

    blockedBy: {
      type: String,
      trim: true,
      default: '',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);