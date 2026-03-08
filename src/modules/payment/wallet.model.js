const mongoose = require('mongoose');

const walletSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
      index: true,
    },

    availableBalance: {
      type: Number,
      default: 0,
      min: 0,
    },

    heldBalance: {
      type: Number,
      default: 0,
      min: 0,
    },

    currency: {
      type: String,
      default: 'EGP',
      trim: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Wallet', walletSchema);