const mongoose = require('mongoose');

const optionSchema = new mongoose.Schema(
  {
    key: { type: String, trim: true }, // A, B, C, D, E
    text: { type: String, required: true },
    isCorrect: { type: Boolean, default: false },

    careerWeights: [
      {
        careerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Career' },
        weight: { type: Number, default: 0 },
      },
    ],
  },
  { _id: false }
);

const questionSchema = new mongoose.Schema(
  {
    sectionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'AssessmentSection',
      required: true,
      index: true,
    },

    category: {
      type: String,
      enum: ['personality', 'technical', 'soft'],
      required: true,
      index: true,
    },

    questionCode: {
      type: String,
      required: true,
      unique: true,
      index: true,
      trim: true,
    },

    text: {
      type: String,
      required: true,
      trim: true,
    },

    answerType: {
      type: String,
      enum: ['likert', 'single'],
      required: true,
      index: true,
    },

    options: {
      type: [optionSchema],
      default: [],
    },

    // NEW: cleaner technical scoring support
    correctOptionIndex: {
      type: Number,
      default: null,
    },

    meta: {
      personality: {
        dimension: { type: String, trim: true }, // EI, SN, TF, JP
        targetPole: { type: String, trim: true }, // E / I / S / N / T / F / J / P
      },

      technical: {
        area: { type: String, trim: true }, // core / concept / tool / applied
        interest: { type: String, trim: true }, // web / data_ai / security / ...
        isSpecialty: { type: Boolean, default: false },
        multiplier: { type: Number, default: 1 },
      },

      soft: {
        softType: { type: String, trim: true }, // likert / behavior / sjt
        softCategory: { type: String, trim: true }, // communication / teamwork / ...
        isReverse: { type: Boolean, default: false },
      },
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Question', questionSchema);