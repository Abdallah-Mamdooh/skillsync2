require('dotenv').config();
const mongoose = require('mongoose');

const Roadmap = require('../src/modules/roadmap/roadmap.model');
require('../src/modules/career/career.model');

const titleFixes = {
  'Boostrapping a Project': 'Bootstrapping a Project',
  'Usecases and Benefits': 'Use Cases and Benefits',
  'Hashicorp Config. Language (HCL)': 'HashiCorp Configuration Language (HCL)',
  'Typescript': 'TypeScript',
  'Ux Design': 'UX Design',
  'Golang': 'Go',
};

function normalizeTitle(title) {
  return titleFixes[title] || title;
}

function toSkillTag(title = '') {
  return String(title)
    .toLowerCase()
    .replace(/[^a-z0-9+#.]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

async function main() {
  await mongoose.connect(process.env.MONGO_URI);

  const roadmaps = await Roadmap.find().populate('careerId', 'name');

  let changedSteps = 0;

  for (const roadmap of roadmaps) {
    const careerName = roadmap.careerId?.name || 'Career';
    let changed = false;

    for (const phase of roadmap.phases || []) {
      phase.title = normalizeTitle(phase.title);

      for (const step of phase.steps || []) {
        const newTitle = normalizeTitle(step.title);

        if (newTitle !== step.title) {
          step.title = newTitle;
          step.skillTag = toSkillTag(newTitle);
          step.description = `Learn ${newTitle} as part of the ${careerName} roadmap.`;

          if (Array.isArray(step.resources)) {
            step.resources = step.resources.map((resource) => {
              const encoded = encodeURIComponent(newTitle);

              if (resource.type === 'video') {
                return {
                  ...resource,
                  title: `${newTitle} - YouTube Search`,
                  url: `https://www.youtube.com/results?search_query=${encoded}`,
                };
              }

              if (resource.type === 'course') {
                return {
                  ...resource,
                  title: `${newTitle} - Coursera Search`,
                  url: `https://www.coursera.org/search?query=${encoded}`,
                };
              }

              if (resource.type === 'documentation') {
                return {
                  ...resource,
                  title: `${newTitle} - Documentation Search`,
                  url: `https://www.google.com/search?q=${encoded}+documentation`,
                };
              }

              return resource;
            });
          }

          changedSteps += 1;
          changed = true;
        }
      }
    }

    if (changed) {
      await roadmap.save();
    }
  }

  console.log(`Polished roadmap titles. Changed steps: ${changedSteps}`);

  await mongoose.disconnect();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});