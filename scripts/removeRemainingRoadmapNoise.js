require('dotenv').config();
const mongoose = require('mongoose');

const Roadmap = require('../src/modules/roadmap/roadmap.model');
require('../src/modules/career/career.model');

function cleanText(value = '') {
  return String(value).replace(/\s+/g, ' ').trim();
}

function isBadStep(title = '') {
  const t = cleanText(title).toLowerCase();

  return (
    t.includes('continue learning with following roadmap') ||
    t.includes('continue learning with following relevant tracks') ||
    t.includes('continue learning with these following relevant tracks') ||
    t.includes('if you are already a full-stack developer you should visit the following tracks') ||
    t.includes('visit the following tracks') ||
    t.includes('visit the following relevant tracks') ||
    t.includes('following relevant tracks') ||
    t.includes('following roadmap')
  );
}

async function main() {
  await mongoose.connect(process.env.MONGO_URI);

  const roadmaps = await Roadmap.find().populate('careerId', 'name');

  let updatedRoadmaps = 0;
  let removedSteps = 0;

  for (const roadmap of roadmaps) {
    let changed = false;

    for (const phase of roadmap.phases || []) {
      const beforeCount = phase.steps.length;

      phase.steps = phase.steps
        .filter((step) => {
          if (isBadStep(step.title)) {
            removedSteps += 1;
            changed = true;
            return false;
          }

          return true;
        })
        .map((step, index) => {
          step.order = index + 1;
          return step;
        });

      if (phase.steps.length !== beforeCount) {
        changed = true;
      }
    }

    roadmap.phases = roadmap.phases.filter(
      (phase) => Array.isArray(phase.steps) && phase.steps.length > 0
    );

    if (changed) {
      await roadmap.save();
      updatedRoadmaps += 1;
    }
  }

  console.log('Remaining roadmap noise removed.');
  console.log(`Updated roadmaps: ${updatedRoadmaps}`);
  console.log(`Removed noisy steps: ${removedSteps}`);

  await mongoose.disconnect();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});