const mongoose = require('mongoose');

const resourceSchema = new mongoose.Schema(
  {
    title: { type: String, required: true },

    type: {
      type: String,
      enum: ['video', 'article', 'course', 'documentation'],
      required: true
    },

    url: { type: String, required: true }
  },
  { _id: false }
);

const stepSchema = new mongoose.Schema(
  {
    title: { type: String, required: true },

    description: { type: String, required: true },

    skillTag: { type: String, required: true },

    order: { type: Number, required: true },

    resources: [resourceSchema]
  },
  { timestamps: true }
);

const phaseSchema = new mongoose.Schema(
  {
    title: { type: String, required: true },

    order: { type: Number, required: true },

    steps: [stepSchema]
  },
  { timestamps: true }
);

const roadmapSchema = new mongoose.Schema(
  {
    careerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Career',
      required: true
    },

    phases: [phaseSchema]
  },
  { timestamps: true }
);

module.exports = mongoose.model('Roadmap', roadmapSchema);