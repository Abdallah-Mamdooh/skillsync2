require('dotenv').config();
const fs = require('fs');
const mongoose = require('mongoose');

const Roadmap = require('../src/modules/roadmap/roadmap.model');
require('../src/modules/career/career.model');

const suspiciousPatterns = [
  /roadmap\.sh/i,
  /vertical node/i,
  /horizontal node/i,
  /related roadmaps/i,
  /find the detailed version/i,
  /find the interactive version/i,
  /special thanks/i,
  /visit the following/i,
  /continue learning with/i,
  /you might be interested/i,
  /things to lookout/i,
  /buzzwords/i,
];

async function main() {
  await mongoose.connect(process.env.MONGO_URI);

  const roadmaps = await Roadmap.find().populate('careerId', 'name description').lean();

  const report = [];

  for (const roadmap of roadmaps) {
    const careerName = roadmap.careerId?.name || 'Unknown Career';
    let totalSteps = 0;
    const suspiciousSteps = [];

    for (const phase of roadmap.phases || []) {
      for (const step of phase.steps || []) {
        totalSteps += 1;

        const combined = `${step.title || ''} ${step.description || ''}`;

        if (suspiciousPatterns.some((pattern) => pattern.test(combined))) {
          suspiciousSteps.push({
            phase: phase.title,
            order: step.order,
            title: step.title,
            description: step.description,
          });
        }
      }
    }

    report.push({
      careerName,
      totalSteps,
      suspiciousCount: suspiciousSteps.length,
      suspiciousSteps,
      status:
        totalSteps === 0
          ? 'EMPTY'
          : suspiciousSteps.length > 0
            ? 'NEEDS_REVIEW'
            : 'CLEAN_BY_RULES',
    });
  }

  fs.writeFileSync(
    'roadmap-quality-report.json',
    JSON.stringify(report, null, 2)
  );

  console.log('Audit finished.');
  console.log('Report created: roadmap-quality-report.json');

  const needsReview = report.filter((item) => item.status !== 'CLEAN_BY_RULES');

  console.log(`Total roadmaps: ${report.length}`);
  console.log(`Need review: ${needsReview.length}`);

  needsReview.forEach((item) => {
    console.log(`${item.status}: ${item.careerName} | suspicious=${item.suspiciousCount} | steps=${item.totalSteps}`);
  });

  await mongoose.disconnect();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});