const mongoose = require('mongoose');

const rankedCareerSchema = new mongoose.Schema(
  {
    careerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Career',
      required: true,
    },
    name: { type: String, trim: true },
    finalScore: { type: Number, default: 0 },
    technical: { type: Number, default: 0 },
    personality: { type: Number, default: 0 },
    soft: { type: Number, default: 0 },
  },
  { _id: false }
);

const compatScoreSchema = new mongoose.Schema(
  {
    careerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Career',
      required: true,
    },
    percentage: { type: Number, default: 0 },
    totalScore: { type: Number, default: 0 },
  },
  { _id: false }
);

const userAssessmentResultSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
      index: true,
    },

    // old-style compatibility output
    scores: {
      type: [compatScoreSchema],
      default: [],
    },

    // new detailed ranking
    rankedCareers: {
      type: [rankedCareerSchema],
      default: [],
    },

    chosenCareer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Career',
      default: null,
    },

    // full scoring breakdowns
    personalityResult: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
    technicalResult: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
    softSkillsResult: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },

    // final engine weights used during scoring
    weights: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('UserAssessmentResult', userAssessmentResultSchema);