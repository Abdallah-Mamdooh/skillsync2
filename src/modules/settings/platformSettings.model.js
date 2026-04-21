const mongoose = require('mongoose');

const platformSettingsSchema = new mongoose.Schema(
  {
    enableNotifications: {
      type: Boolean,
      default: true,
    },

    paymentGatewayConfigured: {
      type: Boolean,
      default: true,
    },

    mentorVerificationActive: {
      type: Boolean,
      default: true,
    },

    updatedBy: {
      type: String,
      trim: true,
      default: '',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('PlatformSettings', platformSettingsSchema);