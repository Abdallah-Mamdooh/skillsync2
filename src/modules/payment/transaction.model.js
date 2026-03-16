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

    eventRegistrationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'EventRegistration',
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
      default: 'pending',
      index: true,
    },

    paymentMethodId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'PaymentMethod',
      default: null,
    },

    provider: {
      type: String,
      enum: ['internal', 'fawry'],
      default: 'internal',
      index: true,
    },

    providerReference: {
      type: String,
      trim: true,
      default: '',
      index: true,
    },

    providerStatus: {
      type: String,
      trim: true,
      default: '',
    },

    // what this payment is for
    entityType: {
      type: String,
      enum: ['wallet_topup', 'mentor_session', 'group_event', 'other'],
      default: 'other',
      index: true,
    },

    entityId: {
      type: mongoose.Schema.Types.ObjectId,
      default: null,
      index: true,
    },

    checkoutUrl: {
      type: String,
      trim: true,
      default: '',
    },

    paymentChannel: {
      type: String,
      trim: true,
      default: '',
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

    rawProviderResponse: {
      type: Object,
      default: null,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Transaction', transactionSchema);