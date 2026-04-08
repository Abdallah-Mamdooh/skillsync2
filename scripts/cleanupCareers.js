require('dotenv').config();
const mongoose = require('mongoose');

const Career = require('../src/modules/career/career.model');
const Roadmap = require('../src/modules/roadmap/roadmap.model');
const UserAssessmentResult = require('../src/modules/assessment/userAssessmentResult.model');
const UserRoadmapProgress = require('../src/modules/roadmap/userRoadmapProgress.model');
const User = require('../src/modules/auth/user.model');

async function cleanupCareers() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to DB');

  const careers = await Career.find().sort({ name: 1 });
  const roadmaps = await Roadmap.find({}, { careerId: 1 });

  const roadmapCareerIds = new Set(roadmaps.map((r) => String(r.careerId)));

  const careersWithRoadmaps = careers.filter((c) =>
    roadmapCareerIds.has(String(c._id))
  );

  const careersWithoutRoadmaps = careers.filter(
    (c) => !roadmapCareerIds.has(String(c._id))
  );

  console.log('\n=== Careers WITH roadmap ===');
  careersWithRoadmaps.forEach((c) => {
    console.log(`KEEP   | ${c.name} | ${c._id}`);
  });

  console.log('\n=== Careers WITHOUT roadmap ===');
  careersWithoutRoadmaps.forEach((c) => {
    console.log(`REMOVE? | ${c.name} | ${c._id}`);
  });

  console.log('\nNo deletions were made in this step.');
  console.log('This script is currently only for inspection.');

  await mongoose.disconnect();
  console.log('\nDisconnected from DB');
}

cleanupCareers().catch(async (err) => {
  console.error('Cleanup inspection failed:', err);
  try {
    await mongoose.disconnect();
  } catch (_) {}
  process.exit(1);
});