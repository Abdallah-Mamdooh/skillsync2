const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    relatedUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },

    sessionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MentorSession',
      default: null,
      index: true,
    },

    type: {
      type: String,
      enum: [
        'deposit',
        'withdraw',
        'hold',
        'release',
        'capture',
        'refund',
        'mentor_credit',
        'platform_fee',
      ],
      required: true,
      index: true,
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
      enum: ['pending', 'completed', 'failed'],
      default: 'completed',
      index: true,
    },

    paymentMethodId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'PaymentMethod',
      default: null,
    },

    reference: {
      type: String,
      trim: true,
      default: '',
    },

    notes: {
      type: String,
      trim: true,
      default: '',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Transaction', transactionSchema);