const mongoose = require('mongoose');

const optionSchema = new mongoose.Schema(
  {
    // For MCQ/Behavior/SJT: A/B/C/D ... (optional but useful)
    key: { type: String, trim: true },

    // Text shown to the user
    text: { type: String, required: true },

    // For technical MCQ: which option is correct (optional for likert)
    isCorrect: { type: Boolean, default: false },

    /**
     * You already use this in your scoring today.
     * Keep it for compatibility + for career scoring later.
     */
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
    },

    // New: quick filtering (personality / technical / soft)
    category: {
      type: String,
      enum: ['personality', 'technical', 'soft'],
      required: true,
      index: true,
    },

    // New: stable code like P01, T33, S61 (helps scoring & debugging)
    questionCode: {
      type: String,
      required: true,
      unique: true,
      index: true,
      trim: true,
    },

    text: { type: String, required: true },

    /**
     * New: how the answer is interpreted
     * - likert: A-E (Strongly Agree -> Strongly Disagree)
     * - single: one correct answer (technical MCQ)
     */
    answerType: {
      type: String,
      enum: ['likert', 'single'],
      required: true,
      index: true,
    },

    /**
     * Options:
     * - For technical MCQ: 4 options, one isCorrect=true
     * - For behavior/SJT: 4 options (no isCorrect) OR you can score via careerWeights
     * - For likert: you can omit options (frontend can render fixed A-E),
     *   but keeping options is fine if you want full DB-driven rendering.
     */
    options: { type: [optionSchema], default: [] },

    /**
     * New: metadata used by scorers (personality / technical / soft).
     * Keep it flexible so you don’t keep changing schema.
     */
    meta: {
      // Personality scoring metadata
      personality: {
        dimension: { type: String, trim: true }, // "EI", "SN", "TF", "JP"
        targetPole: { type: String, trim: true }, // "E" or "I" ... etc
      },

      // Technical scoring metadata
      technical: {
        area: { type: String, trim: true }, // "core", "frontend", "backend", "data", ...
        interest: { type: String, trim: true }, // "web", "data_ai", "security", ...
        isSpecialty: { type: Boolean, default: false },
        multiplier: { type: Number, default: 1 }, // weight importance
      },

      // Soft skills scoring metadata
      soft: {
        softType: { type: String, trim: true }, // "likert" | "behavior" | "sjt"
        softCategory: { type: String, trim: true }, // communication, teamwork, etc
        isReverse: { type: Boolean, default: false },
      },
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Question', questionSchema);