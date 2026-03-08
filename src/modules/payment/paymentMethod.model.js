const mongoose = require('mongoose');

const paymentMethodSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    provider: {
      type: String,
      enum: ['mock_card', 'visa', 'mastercard', 'paypal', 'wallet'],
      default: 'mock_card',
    },

    brand: {
      type: String,
      trim: true,
      default: '',
    },

    last4: {
      type: String,
      trim: true,
      default: '',
    },

    tokenOrReference: {
      type: String,
      trim: true,
      default: '',
    },

    holderName: {
      type: String,
      trim: true,
      default: '',
    },

    expiryMonth: {
      type: Number,
      min: 1,
      max: 12,
      default: null,
    },

    expiryYear: {
      type: Number,
      default: null,
    },

    isDefault: {
      type: Boolean,
      default: false,
    },

    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('PaymentMethod', paymentMethodSchema);