require('dotenv').config();
const mongoose = require('mongoose');

const Roadmap = require('../src/modules/roadmap/roadmap.model');
require('../src/modules/career/career.model');

function cleanText(value = '') {
  return String(value).replace(/\s+/g, ' ').trim();
}

function isNonLearningStep(title = '', description = '') {
  const t = cleanText(title).toLowerCase();
  const d = cleanText(description).toLowerCase();

  if (!t) return true;

  const badExact = new Set([
    'vertical node',
    'horizontal node',
    'roadmap.sh',
    'related roadmaps',
    'useful links',
    'resources',
  ]);

  if (badExact.has(t)) return true;

  const badIncludes = [
    'find the detailed version',
    'find the interactive version',
    'find the complete version',
    'similar roadmaps',
    'visit the following relevant roadmaps',
    'continue learning with following roadmaps',
    'continue learning with the following roadmaps',
    'special thanks',
    'roadmap contribution',
    'have a look at the following',
    'you might be interested',
    'following relevant roadmaps',
  ];

  if (badIncludes.some((bad) => t.includes(bad))) return true;

  const badDescriptionTypes = [
    'type=vertical',
    'type=horizontal',
    'type=button',
    'type=linksgroup',
    'type=paragraph',
  ];

  if (badDescriptionTypes.some((bad) => d.includes(bad))) return true;

  return false;
}

function toSkillTag(title = '') {
  return cleanText(title)
    .toLowerCase()
    .replace(/[^a-z0-9+#.]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

async function main() {
  await mongoose.connect(process.env.MONGO_URI);

  const roadmaps = await Roadmap.find().populate('careerId', 'name');

  let updatedRoadmaps = 0;
  let removedSteps = 0;
  let fixedSteps = 0;

  for (const roadmap of roadmaps) {
    const careerName = roadmap.careerId?.name || 'Career';
    let changed = false;

    for (const phase of roadmap.phases || []) {
      const seen = new Set();

      const cleanedSteps = [];

      for (const step of phase.steps || []) {
        const title = cleanText(step.title);
        const description = cleanText(step.description);

        if (isNonLearningStep(title, description)) {
          removedSteps += 1;
          changed = true;
          continue;
        }

        const key = title.toLowerCase();

        if (seen.has(key)) {
          removedSteps += 1;
          changed = true;
          continue;
        }

        seen.add(key);

        step.title = title;
        step.skillTag = toSkillTag(title);
        step.description = `Learn ${title} as part of the ${careerName} roadmap.`;
        step.order = cleanedSteps.length + 1;

        cleanedSteps.push(step);
        fixedSteps += 1;
      }

      phase.steps = cleanedSteps;
    }

    roadmap.phases = roadmap.phases.filter(
      (phase) => Array.isArray(phase.steps) && phase.steps.length > 0
    );

    if (changed) {
      await roadmap.save();
      updatedRoadmaps += 1;
    }
  }

  console.log('Strict roadmap cleanup finished.');
  console.log(`Updated roadmaps: ${updatedRoadmaps}`);
  console.log(`Removed non-learning steps: ${removedSteps}`);
  console.log(`Fixed remaining steps: ${fixedSteps}`);

  await mongoose.disconnect();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});