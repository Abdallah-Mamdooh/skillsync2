require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('../src/config/db');

const AssessmentSection = require('../src/modules/assessment/assessmentSection.model');
const Question = require('../src/modules/assessment/question.model');

const LIKERT_OPTIONS = [
  { key: 'A', text: 'Strongly Agree' },
  { key: 'B', text: 'Agree' },
  { key: 'C', text: 'Neutral' },
  { key: 'D', text: 'Disagree' },
  { key: 'E', text: 'Strongly Disagree' },
];

// For each question we store: dimension + agreePole (what “Agree” indicates)
const personalityQuestions = [
  // EI (1–8)
  { code: 'P01', dim: 'EI', agreePole: 'E', text: 'I feel energized after interacting with groups of people.' },
  { code: 'P02', dim: 'EI', agreePole: 'I', text: 'I prefer working independently rather than in teams.' },
  { code: 'P03', dim: 'EI', agreePole: 'E', text: 'I speak up quickly during meetings.' },
  { code: 'P04', dim: 'EI', agreePole: 'I', text: 'I need quiet time alone to recharge.' },
  { code: 'P05', dim: 'EI', agreePole: 'E', text: 'I actively seek networking opportunities.' },
  { code: 'P06', dim: 'EI', agreePole: 'E', text: 'I initiate conversations easily.' },
  { code: 'P07', dim: 'EI', agreePole: 'I', text: 'I feel mentally drained after social events.' },
  { code: 'P08', dim: 'EI', agreePole: 'E', text: 'I gain motivation from teamwork.' },

  // SN (9–16)
  { code: 'P09', dim: 'SN', agreePole: 'S', text: 'I focus on concrete facts rather than abstract ideas.' },
  { code: 'P10', dim: 'SN', agreePole: 'N', text: 'I enjoy theoretical discussions.' },
  { code: 'P11', dim: 'SN', agreePole: 'N', text: 'I imagine future possibilities often.' },
  { code: 'P12', dim: 'SN', agreePole: 'N', text: 'I connect patterns between unrelated ideas.' },
  { code: 'P13', dim: 'SN', agreePole: 'S', text: 'I notice small factual details quickly.' },
  { code: 'P14', dim: 'SN', agreePole: 'S', text: 'I prefer step-by-step instructions.' },
  { code: 'P15', dim: 'SN', agreePole: 'N', text: 'I enjoy innovation and new methods.' },
  { code: 'P16', dim: 'SN', agreePole: 'N', text: 'I brainstorm alternative solutions frequently.' },

  // TF (17–24)
  { code: 'P17', dim: 'TF', agreePole: 'T', text: 'I prioritize logic over emotions in decisions.' },
  { code: 'P18', dim: 'TF', agreePole: 'F', text: 'I consider others’ feelings before finalizing decisions.' },
  { code: 'P19', dim: 'TF', agreePole: 'T', text: 'I value fairness more than harmony.' },
  { code: 'P20', dim: 'TF', agreePole: 'F', text: 'I avoid conflict to preserve relationships.' },
  { code: 'P21', dim: 'TF', agreePole: 'T', text: 'I prefer objective evaluation.' },
  { code: 'P22', dim: 'TF', agreePole: 'F', text: 'I empathize easily with people’s struggles.' },
  { code: 'P23', dim: 'TF', agreePole: 'T', text: 'I openly challenge weak reasoning.' },
  { code: 'P24', dim: 'TF', agreePole: 'F', text: 'I aim for consensus in group decisions.' },

  // JP (25–32)
  { code: 'P25', dim: 'JP', agreePole: 'J', text: 'I prefer structured plans before starting work.' },
  { code: 'P26', dim: 'JP', agreePole: 'P', text: 'I enjoy keeping options open.' },
  { code: 'P27', dim: 'JP', agreePole: 'J', text: 'I complete tasks ahead of schedule.' },
  { code: 'P28', dim: 'JP', agreePole: 'P', text: 'I adapt comfortably to sudden changes.' },
  { code: 'P29', dim: 'JP', agreePole: 'J', text: 'I prefer organized routines.' },
  { code: 'P30', dim: 'JP', agreePole: 'P', text: 'I enjoy spontaneity.' },
  { code: 'P31', dim: 'JP', agreePole: 'P', text: 'I delay decisions to gather more information.' },
  { code: 'P32', dim: 'JP', agreePole: 'J', text: 'I prefer closure once a decision is made.' },
];

async function main() {
  await connectDB();

  const section = await AssessmentSection.findOne({ title: 'Personality' });
  if (!section) throw new Error('Personality section not found. Run seed:sections first.');

  let upserted = 0;

  for (const q of personalityQuestions) {
    const doc = {
      sectionId: section._id,
      category: 'personality',
      questionCode: q.code,
      answerType: 'likert',
      text: q.text,
      options: LIKERT_OPTIONS,
      meta: {
        personality: {
          dimension: q.dim,
          agreePole: q.agreePole,
        },
      },
    };

    await Question.findOneAndUpdate(
      { questionCode: q.code },
      { $set: doc },
      { upsert: true, new: true }
    );
    upserted++;
  }

  console.log(`✅ Personality questions upserted: ${upserted}`);
  await mongoose.disconnect();
  process.exit(0);
}

main().catch(async (err) => {
  console.error(err);
  await mongoose.disconnect();
  process.exit(1);
});