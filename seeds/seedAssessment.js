require('dotenv').config();
const mongoose = require('mongoose');

const AssessmentSection = require('../src/modules/assessment/assessmentSection.model');
const Question = require('../src/modules/assessment/question.model');
const Career = require('../src/modules/career/career.model');

const {
  personalityQuestions,
  technicalQuestions,
  softSkillQuestions,
} = require('./assessmentQuestions');

function normalizeName(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, ' ');
}

function toTitleCase(slug) {
  return String(slug || '')
    .replace(/[-_]+/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

async function upsertSections() {
  const sections = [
    { title: 'Personality Assessment', type: 'personality', order: 1 },
    { title: 'Technical Assessment', type: 'technical', order: 2 },
    { title: 'Soft Skills Assessment', type: 'soft', order: 3 },
  ];

  const created = {};

  for (const section of sections) {
    const doc = await AssessmentSection.findOneAndUpdate(
      { type: section.type },
      { $set: section },
      { upsert: true, new: true }
    );
    created[section.type] = doc;
  }

  return created;
}

function buildCareerMap(careers) {
  const map = new Map();

  for (const career of careers) {
    map.set(normalizeName(career.name), career);
  }

  return map;
}

function findCareer(careerMap, names) {
  for (const name of names) {
    const found = careerMap.get(normalizeName(name));
    if (found) return found;
  }
  return null;
}

function buildTechnicalCareerWeightMap(careerMap) {
  return {
    web: [
      { names: ['Frontend', 'Frontend Developer'], weight: 5 },
      { names: ['Full Stack'], weight: 4 },
      { names: ['Javascript'], weight: 3 },
      { names: ['Typescript'], weight: 3 },
      { names: ['React'], weight: 3 },
      { names: ['Angular'], weight: 3 },
      { names: ['Vue'], weight: 3 },
    ],
    data_ai: [
      { names: ['Data Analyst'], weight: 5 },
      { names: ['Data Engineer'], weight: 4 },
      { names: ['Machine Learning'], weight: 5 },
      { names: ['Ai Engineer'], weight: 5 },
      { names: ['Ai Data Scientist'], weight: 5 },
      { names: ['Mlops'], weight: 4 },
      { names: ['Python'], weight: 3 },
    ],
    security: [
      { names: ['Cyber Security'], weight: 5 },
      { names: ['Ai Red Teaming'], weight: 3 },
      { names: ['Devops'], weight: 2 },
      { names: ['Backend', 'Backend Developer'], weight: 2 },
    ],
    design: [
      { names: ['Ux Design'], weight: 5 },
      { names: ['Design System'], weight: 4 },
      { names: ['Frontend', 'Frontend Developer'], weight: 2 },
    ],
    product: [
      { names: ['Product Manager'], weight: 5 },
      { names: ['Ux Design'], weight: 2 },
      { names: ['Software Architect'], weight: 2 },
    ],
    devops: [
      { names: ['Devops', 'Devops Beginner'], weight: 5 },
      { names: ['Cloudflare'], weight: 3 },
      { names: ['Kubernetes'], weight: 4 },
      { names: ['Terraform'], weight: 4 },
      { names: ['Docker'], weight: 4 },
      { names: ['Backend', 'Backend Developer'], weight: 2 },
    ],
    qa: [
      { names: ['Qa'], weight: 5 },
      { names: ['Frontend', 'Frontend Developer'], weight: 2 },
      { names: ['Backend', 'Backend Developer'], weight: 2 },
    ],
    mobile_game: [
      { names: ['Flutter'], weight: 5 },
      { names: ['Android'], weight: 4 },
      { names: ['Ios'], weight: 4 },
      { names: ['Game Developer'], weight: 5 },
      { names: ['Server Side Game Developer'], weight: 3 },
      { names: ['React Native'], weight: 4 },
    ],
    core: [
      { names: ['Backend', 'Backend Developer'], weight: 3 },
      { names: ['Frontend', 'Frontend Developer'], weight: 3 },
      { names: ['Full Stack'], weight: 3 },
      { names: ['Software Architect'], weight: 3 },
      { names: ['Computer Science'], weight: 3 },
      { names: ['Data Analyst'], weight: 2 },
      { names: ['Devops'], weight: 2 },
      { names: ['Qa'], weight: 2 },
    ],
  };
}

function attachCareerWeightsToTechnicalQuestions(questions, careers) {
  const careerMap = buildCareerMap(careers);
  const weightMap = buildTechnicalCareerWeightMap(careerMap);

  return questions.map((question) => {
    const interest = question.meta?.technical?.interest || 'core';
    const area = question.meta?.technical?.area || 'core';

    const targets = weightMap[interest] || weightMap.core || [];
    const weights = [];

    for (const target of targets) {
      const career = findCareer(careerMap, target.names);
      if (!career) continue;

      let weight = target.weight;

      if (area === 'applied') weight += 1;
      if (area === 'tool') weight += 0.5;

      weights.push({
        careerId: career._id,
        weight,
      });
    }

    return {
      ...question,
      options: (question.options || []).map((option, index) => {
        const isCorrect =
          question.correctOptionIndex === index || option.isCorrect === true;

        return {
          ...option,
          isCorrect,
          careerWeights: isCorrect ? weights : [],
        };
      }),
    };
  });
}

async function upsertQuestions(sectionMap, careers) {
  const technicalWithWeights = attachCareerWeightsToTechnicalQuestions(
    technicalQuestions,
    careers
  );

  const allQuestions = [
    ...personalityQuestions,
    ...technicalWithWeights,
    ...softSkillQuestions,
  ];

  for (const question of allQuestions) {
    const sectionType = question.section;
    const section = sectionMap[sectionType];

    if (!section) {
      throw new Error(`Missing section for question ${question.questionCode}`);
    }

    const payload = {
      sectionId: section._id,
      category: question.category,
      questionCode: question.questionCode,
      text: question.text,
      answerType: question.answerType,
      options: question.options || [],
      correctOptionIndex:
        typeof question.correctOptionIndex === 'number'
          ? question.correctOptionIndex
          : null,
      meta: question.meta || {},
    };

    await Question.findOneAndUpdate(
      { questionCode: question.questionCode },
      { $set: payload },
      { upsert: true, new: true }
    );
  }

  return allQuestions.length;
}

async function seedAssessment() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to DB');

  const careers = await Career.find();
  if (!careers.length) {
    throw new Error('No careers found. Import/seed careers before assessment questions.');
  }

  const sectionMap = await upsertSections();
  const count = await upsertQuestions(sectionMap, careers);

  console.log(`Seeded assessment sections and ${count} questions successfully.`);
  await mongoose.disconnect();
  console.log('Disconnected from DB');
}

seedAssessment().catch(async (err) => {
  console.error('Seed failed:', err);
  try {
    await mongoose.disconnect();
  } catch (_) {}
  process.exit(1);
});