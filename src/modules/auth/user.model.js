const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: true,
      trim: true
    },
    profileImageUrl: {
    type: String,
    trim: true,
    default: ''
},

    bio: {
    type: String,
    trim: true,
    default: ''
},

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true
    },

    phoneNumber: {
      type: String,
      required: true,
      unique: true,
      trim: true
    },

    password: {
      type: String,
      required: true,
      select: false
    },

    passwordResetToken: String,
    passwordResetExpires: Date,

    role: {
      type: String,
      enum: ['user', 'mentor', 'admin'],
      required: true
    },

    // ✅ NEW: interest pre-selection for technical questions
    // store up to 3 (web, data_ai, security, design, product, devops, qa, mobile_game)
    selectedInterests: [
      {
        type: String,
        trim: true
      }
    ],

    // Core Profile Data
    skills: [
      {
        type: String
      }
    ],

    cvUrl: {
      type: String
    },

    assessmentCompleted: {
      type: Boolean,
      default: false
    },

    mentorProfile: {
      linkedinUrl: String,
      additionalInfo: String,
      isVerified: {
        type: Boolean,
        default: false
      }
    },

    isActive: {
      type: Boolean,
      default: true
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);