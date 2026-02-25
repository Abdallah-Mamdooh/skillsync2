const mongoose = require('mongoose');

const userRoadmapProgressSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },

    roadmapId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Roadmap',
      required: true
    },

    completedSteps: [
      {
        type: mongoose.Schema.Types.ObjectId
      }
    ]
  },
  { timestamps: true }
);

module.exports = mongoose.model(
  'UserRoadmapProgress',
  userRoadmapProgressSchema
);