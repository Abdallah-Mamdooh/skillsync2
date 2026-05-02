require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');

const Roadmap = require('../src/modules/roadmap/roadmap.model');
require('../src/modules/career/career.model');

function normalizeTitle(title = '') {
  return String(title)
    .replace(/<[^>]*>/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function toSkillTag(title = '') {
  return normalizeTitle(title)
    .toLowerCase()
    .replace(/[^a-z0-9+#.]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function isBadImportedStep(step) {
  const title = normalizeTitle(step.title).toLowerCase();
  const description = String(step.description || '').toLowerCase();

  if (!title) return true;

  const badTitles = [
    'vertical node',
    'horizontal node',
    'roadmap.sh',
    'related roadmaps',
    'have a look at the following related roadmaps',
    'you might be interested in following roadmaps as well',
  ];

  if (badTitles.includes(title)) return true;

  if (title.startsWith('find the interactive version')) return true;
  if (title.startsWith('find the detailed version')) return true;
  if (title.includes('similar roadmaps')) return true;

  const badDescriptionTypes = [
    'type=vertical',
    'type=horizontal',
    'type=button',
    'type=linksgroup',
    'type=title',
  ];

  return badDescriptionTypes.some((bad) => description.includes(bad));
}

function buildDescription(title, careerName) {
  return `Learn ${title} as part of the ${careerName} roadmap.`;
}

function buildResources(title) {
  const query = encodeURIComponent(title);

  return [
    {
      title: `${title} - YouTube Search`,
      type: 'video',
      provider: 'YouTube',
      url: `https://www.youtube.com/results?search_query=${query}`,
    },
    {
      title: `${title} - Coursera Search`,
      type: 'course',
      provider: 'Coursera',
      url: `https://www.coursera.org/search?query=${query}`,
    },
    {
      title: `${title} - Documentation Search`,
      type: 'documentation',
      provider: 'Google',
      url: `https://www.google.com/search?q=${query}+documentation`,
    },
  ];
}

async function main() {
  await mongoose.connect(process.env.MONGO_URI);

  const roadmaps = await Roadmap.find().populate('careerId', 'name').lean();

  const backupPath = path.join(
    process.cwd(),
    `roadmaps-backup-before-clean-${Date.now()}.json`
  );

  fs.writeFileSync(backupPath, JSON.stringify(roadmaps, null, 2));
  console.log(`Backup created: ${backupPath}`);

  let updatedRoadmaps = 0;
  let removedSteps = 0;
  let cleanedSteps = 0;

  for (const roadmap of roadmaps) {
    const careerName = roadmap.careerId?.name || 'Career';
    const newPhases = [];

    for (const phase of roadmap.phases || []) {
      const cleanSteps = [];
      const seenTitles = new Set();

      for (const step of phase.steps || []) {
        const title = normalizeTitle(step.title);

        if (isBadImportedStep(step)) {
          removedSteps += 1;
          continue;
        }

        const key = title.toLowerCase();

        if (seenTitles.has(key)) {
          removedSteps += 1;
          continue;
        }

        seenTitles.add(key);

        cleanSteps.push({
          ...step,
          title,
          description: buildDescription(title, careerName),
          skillTag: toSkillTag(title),
          resources:
            Array.isArray(step.resources) && step.resources.length > 0
              ? step.resources
              : buildResources(title),
          order: cleanSteps.length + 1,
        });

        cleanedSteps += 1;
      }

      if (cleanSteps.length > 0) {
        newPhases.push({
          ...phase,
          title: phase.title || careerName,
          steps: cleanSteps,
          order: newPhases.length + 1,
        });
      }
    }

    if (newPhases.length === 0) {
      console.log(`Skipped ${careerName}: no valid steps left`);
      continue;
    }

    await Roadmap.findByIdAndUpdate(roadmap._id, {
      $set: {
        phases: newPhases,
      },
    });

    updatedRoadmaps += 1;
  }

  console.log('Cleaning finished');
  console.log(`Updated roadmaps: ${updatedRoadmaps}`);
  console.log(`Removed noisy/duplicate steps: ${removedSteps}`);
  console.log(`Cleaned useful steps: ${cleanedSteps}`);

  await mongoose.disconnect();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});