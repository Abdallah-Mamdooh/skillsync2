const mongoose = require('mongoose');

const roadmapSchema = new mongoose.Schema(
  {
    careerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Career',
      required: true
    },

    phases: [
      {
        title: String,
        order: Number,

        steps: [
          {
            title: String,
            description: String,
            skillTag: String,

            resources: [
              {
                title: String,
                type: {
                  type: String,
                  enum: ['video', 'article', 'course', 'documentation']
                },
                url: String
              }
            ]
          }
        ]
      }
    ]
  },
  { timestamps: true }
);

module.exports = mongoose.model('Roadmap', roadmapSchema);
