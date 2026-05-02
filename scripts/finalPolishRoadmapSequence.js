require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');

const Roadmap = require('../src/modules/roadmap/roadmap.model');
require('../src/modules/career/career.model');

function cleanText(value = '') {
  return String(value).replace(/\s+/g, ' ').trim();
}

function toSkillTag(title = '') {
  return cleanText(title)
    .toLowerCase()
    .replace(/[^a-z0-9+#.]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function isRemainingBadStep(title = '') {
  const t = cleanText(title).toLowerCase();

  if (!t) return true;

  const badExact = [
    'vertical node',
    'horizontal node',
    'roadmap.sh',
    'related roadmaps',
    'useful links',
  ];

  if (badExact.includes(t)) return true;

  const badStarts = [
    'find the interactive version',
    'find the detailed version',
    'find the complete version',
    'have a look at',
    'you might be interested',
    'visit the following',
    'also visit',
    'make sure to visit',
    'special thanks',
  ];

  return badStarts.some((bad) => t.startsWith(bad));
}

function getPriority(title = '') {
  const t = cleanText(title).toLowerCase();

  // Foundation / prerequisites
  if (
    t.includes('introduction') ||
    t.includes('fundamental') ||
    t.includes('basics') ||
    t.includes('what is') ||
    t.includes('overview') ||
    t.includes('prerequisite')
  ) {
    return 10;
  }

  // Setup / environment
  if (
    t.includes('install') ||
    t.includes('setup') ||
    t.includes('configuration') ||
    t.includes('getting started') ||
    t.includes('bootstrapping') ||
    t.includes('environment') ||
    t.includes('cli') ||
    t.includes('create-')
  ) {
    return 20;
  }

  // Core concepts
  if (
    t.includes('syntax') ||
    t.includes('component') ||
    t.includes('template') ||
    t.includes('type') ||
    t.includes('class') ||
    t.includes('function') ||
    t.includes('module') ||
    t.includes('props') ||
    t.includes('state') ||
    t.includes('lifecycle') ||
    t.includes('routing')
  ) {
    return 30;
  }

  // Data / APIs / backend interaction
  if (
    t.includes('api') ||
    t.includes('http') ||
    t.includes('database') ||
    t.includes('query') ||
    t.includes('fetch') ||
    t.includes('axios') ||
    t.includes('graphql') ||
    t.includes('authentication') ||
    t.includes('authorization')
  ) {
    return 40;
  }

  // Tools / ecosystem / libraries
  if (
    t.includes('tool') ||
    t.includes('framework') ||
    t.includes('library') ||
    t.includes('package') ||
    t.includes('plugin') ||
    t.includes('ecosystem') ||
    t.includes('vite') ||
    t.includes('webpack') ||
    t.includes('tailwind') ||
    t.includes('figma') ||
    t.includes('sketch')
  ) {
    return 50;
  }

  // Testing / debugging / quality
  if (
    t.includes('test') ||
    t.includes('debug') ||
    t.includes('lint') ||
    t.includes('format') ||
    t.includes('quality') ||
    t.includes('validation')
  ) {
    return 60;
  }

  // Performance / security / advanced
  if (
    t.includes('performance') ||
    t.includes('security') ||
    t.includes('optimization') ||
    t.includes('advanced') ||
    t.includes('scaling') ||
    t.includes('architecture')
  ) {
    return 70;
  }

  // Deployment / production
  if (
    t.includes('deploy') ||
    t.includes('cloud') ||
    t.includes('ci/cd') ||
    t.includes('docker') ||
    t.includes('kubernetes') ||
    t.includes('monitoring') ||
    t.includes('logging') ||
    t.includes('production')
  ) {
    return 80;
  }

  // Career / interview / job preparation
  if (
    t.includes('interview') ||
    t.includes('job') ||
    t.includes('resume') ||
    t.includes('portfolio') ||
    t.includes('salary')
  ) {
    return 90;
  }

  return 55;
}

function improveTitle(title = '') {
  const fixes = {
    'Boostrapping a Project': 'Bootstrapping a Project',
    'Usecases and Benefits': 'Use Cases and Benefits',
    'Hashicorp Config. Language (HCL)': 'HashiCorp Configuration Language (HCL)',
    'Typescript': 'TypeScript',
    'Ux Design': 'UX Design',
    'Postgresql Dba': 'PostgreSQL DBA',
    'Ai Agents': 'AI Agents',
    'Ai Red Teaming': 'AI Red Teaming',
    'Datastructures And Algorithms': 'Data Structures and Algorithms',
  };

  return fixes[title] || title;
}

function buildDescription(title, careerName) {
  return `Learn ${title} as part of the ${careerName} roadmap.`;
}

async function main() {
  await mongoose.connect(process.env.MONGO_URI);

  const roadmaps = await Roadmap.find().populate('careerId', 'name').lean();

  const backupPath = path.join(
    process.cwd(),
    `roadmaps-backup-before-final-sequence-${Date.now()}.json`
  );

  fs.writeFileSync(backupPath, JSON.stringify(roadmaps, null, 2));
  console.log(`Backup created: ${backupPath}`);

  let updatedRoadmaps = 0;
  let removedSteps = 0;
  let reorderedSteps = 0;

  for (const roadmap of roadmaps) {
    const careerName = improveTitle(roadmap.careerId?.name || 'Career');
    const newPhases = [];

    for (const phase of roadmap.phases || []) {
      const seen = new Set();

      const cleanSteps = (phase.steps || [])
        .map((step) => ({
          ...step,
          title: improveTitle(cleanText(step.title)),
        }))
        .filter((step) => {
          if (isRemainingBadStep(step.title)) {
            removedSteps += 1;
            return false;
          }

          const key = step.title.toLowerCase();

          if (seen.has(key)) {
            removedSteps += 1;
            return false;
          }

          seen.add(key);
          return true;
        })
        .sort((a, b) => {
          const priorityA = getPriority(a.title);
          const priorityB = getPriority(b.title);

          if (priorityA !== priorityB) return priorityA - priorityB;

          return Number(a.order || 0) - Number(b.order || 0);
        })
        .map((step, index) => {
          reorderedSteps += 1;

          return {
            ...step,
            order: index + 1,
            skillTag: toSkillTag(step.title),
            description: buildDescription(step.title, careerName),
          };
        });

      if (cleanSteps.length > 0) {
        newPhases.push({
          ...phase,
          title: improveTitle(cleanText(phase.title || careerName)),
          order: newPhases.length + 1,
          steps: cleanSteps,
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

  console.log('Final sequence polish finished');
  console.log(`Updated roadmaps: ${updatedRoadmaps}`);
  console.log(`Removed remaining bad steps: ${removedSteps}`);
  console.log(`Reordered steps: ${reorderedSteps}`);

  await mongoose.disconnect();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});