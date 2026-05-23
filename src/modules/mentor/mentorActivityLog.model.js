const mongoose = require('mongoose');

const mentorActivityLogSchema = new mongoose.Schema(
  {
    mentorUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    mentorProfileId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MentorProfile',
      default: null,
      index: true,
    },

    sessionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MentorSession',
      default: null,
      index: true,
    },

    action: {
      type: String,
      enum: [
        'status_changed',
        'break_started',
        'break_ended',
        'session_cancelled_by_mentor',
        'cancellation_reviewed_valid',
        'cancellation_reviewed_rejected',
        'penalty_applied',
        'mentor_blocked',
        'schedule_change_requested',
        'schedule_change_approved',
        'schedule_change_rejected',
        'schedule_change_applied',

        'availability_exception_created',
        'availability_exception_removed',

        'mentor_online',
        'mentor_offline',

        
      ],
      required: true,
      index: true,
    },

    message: {
      type: String,
      trim: true,
      default: '',
    },

    metadata: {
      type: Object,
      default: {},
    },

    performedByUserId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },

    performedByRole: {
      type: String,
      enum: ['mentor', 'admin', 'system'],
      default: 'system',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('MentorActivityLog', mentorActivityLogSchema);