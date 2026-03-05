require('dotenv').config();
const mongoose = require('mongoose');

const AssessmentSection = require('../src/modules/assessment/assessmentSection.model');
const User = require('../src/modules/auth/user.model');
const assessmentService = require('../src/modules/assessment/assessment.service');

async function connectDB() {
  const uri = process.env.MONGO_URI || process.env.MONGODB_URI;
  if (!uri) throw new Error('Missing MONGO_URI');

  await mongoose.connect(uri);
  console.log('MongoDB connected');
}

async function run() {

  await connectDB();

  // find any user
  const user = await User.findOne();

  if (!user) {
    throw new Error('No user found in database');
  }

  console.log('Testing user:', user.email);

  // set interests manually for test
  user.selectedInterests = ['web', 'data_ai', 'devops'];
  await user.save();

  console.log('Saved interests:', user.selectedInterests);

  // get technical section
  const techSection = await AssessmentSection.findOne({ title: 'Technical' });

  if (!techSection) {
    throw new Error('Technical section not found');
  }

  // fetch questions using service
  const questions = await assessmentService.getQuestionsBySection(
    techSection._id,
    user._id
  );

  console.log('\nTotal questions returned:', questions.length);

  const specialty = questions.filter(
    q => q?.meta?.technical?.isSpecialty === true
  );

  const core = questions.filter(
    q => q?.meta?.technical?.isSpecialty !== true
  );

  console.log('Core questions:', core.length);
  console.log('Specialty questions:', specialty.length);

  console.log('\nSample questions:');

  questions.slice(0, 5).forEach(q => {
    console.log('-', q.questionCode, '| specialty:', q?.meta?.technical?.isSpecialty);
  });

  await mongoose.disconnect();
  console.log('\nMongoDB disconnected');
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});