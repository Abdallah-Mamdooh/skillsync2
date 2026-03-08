const mongoose = require('mongoose');

const eventRegistrationSchema = new mongoose.Schema(
  {
    eventId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'GroupEvent',
      required: true,
      index: true,
    },

    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    paymentStatus: {
      type: String,
      enum: ['unpaid', 'held', 'captured', 'released', 'refunded'],
      default: 'unpaid',
      index: true,
    },

    amountPaid: {
      type: Number,
      default: 0,
      min: 0,
    },

    currency: {
      type: String,
      default: 'EGP',
      trim: true,
    },

    attended: {
      type: Boolean,
      default: false,
    },

    checkedInAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

eventRegistrationSchema.index({ eventId: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model('EventRegistration', eventRegistrationSchema);