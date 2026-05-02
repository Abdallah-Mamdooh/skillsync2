
require('dotenv').config();
const mongoose = require('mongoose');

const Roadmap = require('../src/modules/roadmap/roadmap.model');

const badUxTitles = new Set([
  'Buzzwords to lookout for',
  'Things to lookout for',
  'Cheating',
  'with many chances to influence user',
  'In general, keep it short and simple',
  'Tell User what the Action is and ask for it',
  'Get a favorable Conscious Evaluation',
  'Prime User-Relevant Associations',
  'Deploy Strong Authority on Subject',
  'Business Model Inspirator',
  'How-to-Tips',
  'Tutorials',
  'Planners',
  'Status Reports',
]);

const uxPriority = [
  'Understanding the Product',
  'Define Target Users',
  'Create User Personas',
  'User Stories',
  'Simple Flowchart',
  'Competitor Analysis',
  'SWOT Analysis',
  'Business Model',
  'Business Model Canvas',
  'Lean Canvas',
  'Conceptual Design',
  'Wireframing',
  'Good Layout Rules',
  'UX Patterns',
  'Prototyping',
  'Figma',
  'Adobe XD',
  'Sketch',
  'Balsamiq',
  'Customer Experience Map by Mel Edwards',
  'Decision-Making Support',
  'Behavioral Science',
  'Behavioral Economics',
  'Nudge Theory',
  'Behavior Design',
  "BJ Fogg's Behavior Model",
  "BJ Fogg's Behavior Grid",
  "Nir Eyal's Hook Model",
  'Call to Action',
  'Clear the Page of Distractions',
  'Make it Clear, Where to Act',
  'Make it easy to understand and complete',
  'Make UI Professional and Beautiful',
  'Make progress visible to user',
  'Make progress meaningful to reward user',
  'Make successful completion clearly visible',
  'Gamification',
  'Goal Trackers',
  'Reminders',
  'Social Sharing',
  'UX Best Practices',
  'Measuring the Impact',
  'Deliverables',
];

function cleanText(value = '') {
  return String(value).replace(/\s+/g, ' ').trim();
}

function toSkillTag(title = '') {
  return cleanText(title)
    .toLowerCase()
    .replace(/[^a-z0-9+#.]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function priority(title = '') {
  const exactIndex = uxPriority.indexOf(cleanText(title));
  if (exactIndex !== -1) return exactIndex + 1;

  const lower = cleanText(title).toLowerCase();

  if (lower.includes('product') || lower.includes('target user') || lower.includes('persona')) return 20;
  if (lower.includes('flow') || lower.includes('wireframe') || lower.includes('prototype')) return 40;
  if (lower.includes('figma') || lower.includes('adobe') || lower.includes('sketch') || lower.includes('balsamiq')) return 60;
  if (lower.includes('behavior') || lower.includes('decision') || lower.includes('nudge')) return 80;
  if (lower.includes('best practice') || lower.includes('impact') || lower.includes('deliverable')) return 100;

  return 999;
}

function improveTitle(title = '') {
  const fixes = {
    'Ux Design': 'UX Design',
    'Help user Avoiding the Cue': 'Help Users Avoid the Cue',
    'Help User think about their Action': 'Help Users Think About Their Actions',
    'Educate & Encourage User': 'Educate and Encourage Users',
    'Getting Users Attention': 'Getting Users Attention',
    'Getting Positive Intuitive Reaction': 'Getting a Positive Intuitive Reaction',
  };

  return fixes[title] || title;
}

async function main() {
  await mongoose.connect(process.env.MONGO_URI);

  const allRoadmaps = await Roadmap.find();

  const roadmap = allRoadmaps.find((rm) => {
    return (rm.phases || []).some((phase) => {
      const title = cleanText(phase.title).toLowerCase();
      return title === 'ux design' || title === 'ux';
    });
  });

  if (!roadmap) {
    console.log('UX roadmap not found by phase title.');
    console.log('Available phase titles:');
    allRoadmaps.forEach((rm) => {
      const titles = (rm.phases || []).map((p) => p.title).join(', ');
      console.log('-', titles);
    });
    await mongoose.disconnect();
    return;
  }

  let removed = 0;
  let updated = 0;

  for (const phase of roadmap.phases || []) {
    phase.title = 'UX Design';

    const seen = new Set();

    phase.steps = (phase.steps || [])
      .map((step) => {
        step.title = improveTitle(cleanText(step.title));
        return step;
      })
      .filter((step) => {
        const title = cleanText(step.title);

        if (!title || badUxTitles.has(title)) {
          removed += 1;
          return false;
        }

        const key = title.toLowerCase();
        if (seen.has(key)) {
          removed += 1;
          return false;
        }

        seen.add(key);
        return true;
      })
      .sort((a, b) => {
        const pa = priority(a.title);
        const pb = priority(b.title);

        if (pa !== pb) return pa - pb;

        return Number(a.order || 0) - Number(b.order || 0);
      })
      .map((step, index) => {
        step.order = index + 1;
        step.skillTag = toSkillTag(step.title);
        step.description = `Learn ${step.title} as part of the UX Design roadmap.`;
        updated += 1;
        return step;
      });
  }

  await roadmap.save();

  console.log('UX roadmap sequence fixed successfully.');
  console.log(`Removed weak/noisy UX steps: ${removed}`);
  console.log(`Remaining ordered UX steps: ${updated}`);

  await mongoose.disconnect();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
