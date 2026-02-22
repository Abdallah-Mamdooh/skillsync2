const mongoose = require('mongoose');

const assessmentSectionSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true
    },
    type: {
      type: String,
      enum: ['personality', 'technical', 'soft-skills'],
      required: true
    },
    order: Number
  },
  { timestamps: true }
);

module.exports = mongoose.model('AssessmentSection', assessmentSectionSchema);
