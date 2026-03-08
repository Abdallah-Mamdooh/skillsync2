const mongoose = require('mongoose');

const chatMessageSchema = new mongoose.Schema(
  {
    sessionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MentorSession',
      required: true,
      index: true,
    },

    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    senderRole: {
      type: String,
      enum: ['user', 'mentor'],
      required: true,
    },

    messageType: {
      type: String,
      enum: ['text'],
      default: 'text',
    },

    content: {
      type: String,
      required: true,
      trim: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('ChatMessage', chatMessageSchema);