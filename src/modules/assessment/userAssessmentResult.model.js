const mongoose = require('mongoose');

const userAssessmentResultSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true // 🔥 Only ONE assessment per user
    },

    scores: [
      {
        careerId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'Career',
          required: true
        },
        totalScore: {
          type: Number,
          required: true
        },
        percentage: {
          type: Number,
          required: true
        }
      }
    ],

    chosenCareer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Career',
      default: null
    },

    isCompleted: {
      type: Boolean,
      default: false
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model(
  'UserAssessmentResult',
  userAssessmentResultSchema
);