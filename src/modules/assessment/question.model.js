const mongoose = require('mongoose');

const questionSchema = new mongoose.Schema(
  {
    sectionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'AssessmentSection',
      required: true
    },

    text: {
      type: String,
      required: true
    },

    options: [
      {
        text: String,

        careerWeights: [
          {
            careerId: {
              type: mongoose.Schema.Types.ObjectId,
              ref: 'Career'
            },
            weight: Number
          }
        ]
      }
    ]
  },
  { timestamps: true }
);

module.exports = mongoose.model('Question', questionSchema);
