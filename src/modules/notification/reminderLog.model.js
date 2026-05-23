const mongoose = require('mongoose');

const reminderLogSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    entityType: {
      type: String,
      enum: ['mentor_session', 'group_event'],
      required: true,
      index: true,
    },

    entityId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
      index: true,
    },

    reminderType: {
  type: String,
  enum: [
    'session_expiring_soon',
    'session_starting_soon',
    'event_starting_soon',
    'speaker_event_starting_soon',

    'session_24h_before',
    'session_1h_before',
    'session_15m_before',
  ],
  required: true,
  index: true,
},

    sentAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

// Prevent duplicate reminder for same user + entity + type
reminderLogSchema.index(
  { userId: 1, entityType: 1, entityId: 1, reminderType: 1 },
  { unique: true }
);

module.exports = mongoose.model('ReminderLog', reminderLogSchema);