const mongoose = require('mongoose');

const userRoadmapProgressSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },

    // what career/roadmap this progress belongs to
    careerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Career', required: true, index: true },
    roadmapId: { type: mongoose.Schema.Types.ObjectId, ref: 'Roadmap', required: true },

    completedSteps: [{ type: mongoose.Schema.Types.ObjectId }],

    completionPercent: { type: Number, default: 0 },
  },
  { timestamps: true }
);

userRoadmapProgressSchema.index({ userId: 1, careerId: 1 }, { unique: true });

module.exports = mongoose.model('UserRoadmapProgress', userRoadmapProgressSchema);