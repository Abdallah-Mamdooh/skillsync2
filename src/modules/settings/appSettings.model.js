const mongoose = require('mongoose');

const appSettingsSchema = new mongoose.Schema(
  {
    support: {
      whatsappEnabled: {
        type: Boolean,
        default: true,
      },
      supportEmail: {
        type: String,
        trim: true,
        default: '',
      },
    },

    payments: {
      walletEnabled: {
        type: Boolean,
        default: true,
      },
      fawryEnabled: {
        type: Boolean,
        default: true,
      },
      platformFeePercent: {
        type: Number,
        default: 20,
        min: 0,
      },
    },

    mentorSessions: {
      enabled: {
        type: Boolean,
        default: true,
      },
      minDurationMinutes: {
        type: Number,
        default: 15,
        min: 1,
      },
      maxDurationMinutes: {
        type: Number,
        default: 60,
        min: 1,
      },
      userJoinGraceMinutes: {
        type: Number,
        default: 5,
        min: 1,
      },
    },

    events: {
      enabled: {
        type: Boolean,
        default: true,
      },
    },

    complaints: {
      enabled: {
        type: Boolean,
        default: true,
      },
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('AppSettings', appSettingsSchema);