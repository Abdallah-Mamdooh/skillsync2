require('dotenv').config();
const mongoose = require('mongoose');

const Career = require('../src/modules/career/career.model');
const Roadmap = require('../src/modules/roadmap/roadmap.model');
const AssessmentSection = require('../src/modules/assessment/assessmentSection.model');
const Question = require('../src/modules/assessment/question.model');

async function seed() {
  await mongoose.connect(process.env.MONGO_URI);

  console.log('Connected to DB');

  // Clear old data
  await Career.deleteMany();
  await Roadmap.deleteMany();
  await AssessmentSection.deleteMany();
  await Question.deleteMany();

  // Create careers
  const backend = await Career.create({
    name: 'Backend Developer',
    description: 'Build server-side applications'
  });

  const frontend = await Career.create({
    name: 'Frontend Developer',
    description: 'Build user interfaces'
  });

  // Create assessment section
  const personalitySection = await AssessmentSection.create({
    title: 'Personality Assessment',
    type: 'personality',
    order: 1
  });

  // Create question
  await Question.create({
    sectionId: personalitySection._id,
    text: 'Do you enjoy solving logical problems?',
    options: [
      {
        text: 'Strongly Agree',
        careerWeights: [
          { careerId: backend._id, weight: 5 },
          { careerId: frontend._id, weight: 2 }
        ]
      },
      {
        text: 'Disagree',
        careerWeights: [
          { careerId: backend._id, weight: 1 },
          { careerId: frontend._id, weight: 4 }
        ]
      }
    ]
  });

  // Create roadmap
  await Roadmap.create({
    careerId: backend._id,
    phases: [
      {
        title: 'Foundation',
        order: 1,
        steps: [
          {
            title: 'Learn HTTP Basics',
            description: 'Understand web protocols',
            skillTag: 'HTTP',
            resources: [
              {
                title: 'MDN HTTP Guide',
                type: 'documentation',
                url: 'https://developer.mozilla.org/en-US/docs/Web/HTTP'
              }
            ]
          }
        ]
      }
    ]
  });

  console.log('Seed completed');
  process.exit();
}

seed();
