const mongoose = require('mongoose');

const cvAnalysisResultSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },

    cvUrl: {
      type: String,
      trim: true,
      default: '',
    },

    originalFileName: {
      type: String,
      trim: true,
      default: '',
    },

    detectedField: {
      type: String,
      trim: true,
      default: '',
      index: true,
    },

    score: {
      type: Number,
      default: 0,
      min: 0,
      max: 100,
    },

    grade: {
      type: String,
      trim: true,
      default: '',
    },

    wordCount: {
      type: Number,
      default: 0,
      min: 0,
    },

    summary: {
      type: String,
      trim: true,
      default: '',
    },

    strongPoints: {
      type: [String],
      default: [],
    },

    quickWins: {
      type: [String],
      default: [],
    },

    missingSections: {
      type: [String],
      default: [],
    },

    atsIssues: {
      type: [String],
      default: [],
    },

    writingIssues: {
      type: [String],
      default: [],
    },

    improvements: {
      type: [String],
      default: [],
    },

    jdMatchScore: {
      type: Number,
      default: null,
      min: 0,
      max: 100,
    },

    missingKeywords: {
      type: [String],
      default: [],
    },

    analysisProvider: {
      type: String,
      default: 'python_resume_analyzer',
      trim: true,
    },

    rawResponse: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
  },
  { timestamps: true }
);

cvAnalysisResultSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('CvAnalysisResult', cvAnalysisResultSchema);