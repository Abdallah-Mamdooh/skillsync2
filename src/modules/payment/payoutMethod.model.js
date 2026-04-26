const mongoose = require('mongoose');

const payoutMethodSchema = new mongoose.Schema(
  {
    mentorUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    methodType: {
      type: String,
      enum: ['bank_transfer', 'mobile_wallet'],
      required: true,
      index: true,
    },

    accountHolderName: {
      type: String,
      trim: true,
      default: '',
    },

    bankName: {
      type: String,
      trim: true,
      default: '',
    },

    bankAccountNumber: {
      type: String,
      trim: true,
      default: '',
    },

    iban: {
      type: String,
      trim: true,
      default: '',
    },

    walletProvider: {
      type: String,
      trim: true,
      default: '',
    },

    walletNumber: {
      type: String,
      trim: true,
      default: '',
    },

    isDefault: {
      type: Boolean,
      default: false,
      index: true,
    },

    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('PayoutMethod', payoutMethodSchema);