require('dotenv').config();
const mongoose = require('mongoose');

const Career = require('../src/modules/career/career.model');
const Roadmap = require('../src/modules/roadmap/roadmap.model');

async function syncCareerRoadmapIds() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to DB');

  const careers = await Career.find();
  const roadmaps = await Roadmap.find({}, { _id: 1, careerId: 1 });

  const roadmapByCareerId = new Map(
    roadmaps.map((r) => [String(r.careerId), r._id])
  );

  let updated = 0;
  let skipped = 0;

  for (const career of careers) {
    const roadmapId = roadmapByCareerId.get(String(career._id));

    if (!roadmapId) {
      skipped += 1;
      console.log(`SKIP   | ${career.name} | no roadmap found`);
      continue;
    }

    if (String(career.roadmapId) === String(roadmapId)) {
      skipped += 1;
      console.log(`OK     | ${career.name} | already linked`);
      continue;
    }

    career.roadmapId = roadmapId;
    await career.save();

    updated += 1;
    console.log(`UPDATE | ${career.name} | roadmapId set`);
  }

  console.log('\nDone.');
  console.log(`Updated: ${updated}`);
  console.log(`Skipped: ${skipped}`);

  await mongoose.disconnect();
  console.log('Disconnected from DB');
}

syncCareerRoadmapIds().catch(async (err) => {
  console.error('syncCareerRoadmapIds failed:', err);
  try {
    await mongoose.disconnect();
  } catch (_) {}
  process.exit(1);
});