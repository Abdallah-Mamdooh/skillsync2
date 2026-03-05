require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('../src/config/db');

const AssessmentSection = require('../src/modules/assessment/assessmentSection.model');

async function upsertSection(title, order, description) {
  return AssessmentSection.findOneAndUpdate(
    { title },
    { $set: { title, order, description } },
    { upsert: true, new: true }
  );
}

async function main() {
  await connectDB();

  const personality = await upsertSection(
    'Personality',
    1,
    'MBTI-style personality assessment (Likert scale)'
  );

  const technical = await upsertSection(
    'Technical',
    2,
    'Technical fundamentals + interest-based specialty questions'
  );

  const soft = await upsertSection(
    'Soft Skills',
    3,
    'Soft skills assessment (Likert + behavior + situational judgment)'
  );

  console.log('✅ Sections upserted:');
  console.log({
    personality: personality._id.toString(),
    technical: technical._id.toString(),
    soft: soft._id.toString(),
  });

  await mongoose.disconnect();
  process.exit(0);
}

main().catch(async (err) => {
  console.error(err);
  await mongoose.disconnect();
  process.exit(1);
});