const mongoose = require('mongoose');

const withdrawalRequestSchema = new mongoose.Schema(
  {
    mentorUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    payoutMethodId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'PayoutMethod',
      required: true,
    },

    amount: {
      type: Number,
      required: true,
      min: 0,
    },

    currency: {
      type: String,
      default: 'EGP',
      trim: true,
    },

    status: {
      type: String,
      enum: ['pending', 'approved', 'paid', 'rejected', 'cancelled'],
      default: 'pending',
      index: true,
    },

    adminNote: {
      type: String,
      trim: true,
      default: '',
    },

    payoutReference: {
      type: String,
      trim: true,
      default: '',
    },

    reviewedByUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },

    reviewedAt: {
      type: Date,
      default: null,
    },

    paidAt: {
      type: Date,
      default: null,
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('WithdrawalRequest', withdrawalRequestSchema);