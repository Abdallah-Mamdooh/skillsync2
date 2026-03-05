// src/modules/assessment/userAssessmentResult.model.js
const mongoose = require('mongoose');

const userAssessmentResultSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },

    // old style scores (compat)
    scores: { type: Array, default: [] },

    // new detailed ranking
    rankedCareers: { type: Array, default: [] },

    chosenCareer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Career',
      default: null,
    },

    // store breakdown results (for UI/debug)
    personalityResult: { type: Object, default: null },
    technicalResult: { type: Object, default: null },
    softSkillsResult: { type: Object, default: null },

    weights: { type: Object, default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model('UserAssessmentResult', userAssessmentResultSchema);