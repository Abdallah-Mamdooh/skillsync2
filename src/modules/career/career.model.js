const mongoose = require('mongoose');

const careerSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      unique: true
    },
    description: {
      type: String
    },
    icon: {
      type: String
    },
    roadmapId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Roadmap'
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Career', careerSchema);
