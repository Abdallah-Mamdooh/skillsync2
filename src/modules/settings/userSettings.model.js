const mongoose = require('mongoose');

const userSettingsSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
      index: true,
    },

    language: {
      type: String,
      enum: ['en', 'ar'],
      default: 'en',
    },

    notifications: {
      pushEnabled: {
        type: Boolean,
        default: true,
      },
      emailEnabled: {
        type: Boolean,
        default: true,
      },
      inAppEnabled: {
        type: Boolean,
        default: true,
      },
    },

    privacy: {
      profileVisible: {
        type: Boolean,
        default: true,
      },
      showSkills: {
        type: Boolean,
        default: true,
      },
      showRoadmapProgress: {
        type: Boolean,
        default: true,
      },
    },

    appearance: {
      theme: {
        type: String,
        enum: ['light', 'dark', 'system'],
        default: 'system',
      },
    },

    support: {
      showWhatsappShortcut: {
        type: Boolean,
        default: true,
      },
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('UserSettings', userSettingsSchema);