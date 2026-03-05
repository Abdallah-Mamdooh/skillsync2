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

const MCQ_OPTIONS = (arr) => arr.map(([key, text]) => ({ key, text }));

// S61–S68 (Likert) + reverse scoring flags
const softLikert = [
  { code: 'S61', cat: 'timeManagement', isReverse: false, text: 'I manage my time effectively.' },
  { code: 'S62', cat: 'timeManagement', isReverse: true,  text: 'I frequently miss deadlines.' },

  { code: 'S63', cat: 'adaptability',   isReverse: false, text: 'I handle stress well.' },
  { code: 'S64', cat: 'adaptability',   isReverse: true,  text: 'I panic under pressure.' },

  { code: 'S65', cat: 'communication',  isReverse: false, text: 'I communicate clearly.' },
  { code: 'S66', cat: 'communication',  isReverse: true,  text: 'I often misunderstand instructions.' },

  { code: 'S67', cat: 'leadership',     isReverse: false, text: 'I take initiative.' },
  { code: 'S68', cat: 'leadership',     isReverse: true,  text: 'I wait for instructions before acting.' },
];

// S69–S74 (Behavior MCQ) + categories (A is best in our scoring map)
const softBehavior = [
  {
    code: 'S69',
    cat: 'communication',
    text: 'When explaining a complex idea to a team, I:',
    options: MCQ_OPTIONS([
      ['A', 'Break it into simple parts and check understanding'],
      ['B', 'Explain quickly and assume they understand'],
      ['C', 'Give written instructions only'],
      ['D', 'Avoid explaining and let them figure it out'],
    ]),
  },
  {
    code: 'S70',
    cat: 'teamwork',
    text: 'In a group project, I usually:',
    options: MCQ_OPTIONS([
      ['A', 'Offer help to teammates who are struggling'],
      ['B', 'Focus only on my assigned tasks'],
      ['C', 'Take over tasks from others without asking'],
      ['D', 'Avoid collaboration as much as possible'],
    ]),
  },
  {
    code: 'S71',
    cat: 'adaptability',
    text: 'When project requirements suddenly change, I:',
    options: MCQ_OPTIONS([
      ['A', 'Adjust plans quickly and continue'],
      ['B', 'Complain about the change'],
      ['C', 'Wait for someone else to decide what to do'],
      ['D', 'Stop working until direction is clear'],
    ]),
  },
  {
    code: 'S72',
    cat: 'problemSolving',
    text: 'When encountering a technical problem I do not know, I:',
    options: MCQ_OPTIONS([
      ['A', 'Research and try multiple solutions'],
      ['B', 'Ask someone else to solve it immediately'],
      ['C', 'Ignore it and continue with other work'],
      ['D', 'Document the problem and wait without trying'],
    ]),
  },
  {
    code: 'S73',
    cat: 'leadership',
    text: 'If a teammate is demotivated, I:',
    options: MCQ_OPTIONS([
      ['A', 'Encourage them and offer guidance'],
      ['B', 'Leave them to handle it alone'],
      ['C', 'Complain to management about them'],
      ['D', 'Take over their tasks without discussion'],
    ]),
  },
  {
    code: 'S74',
    cat: 'timeManagement',
    text: 'When I have multiple deadlines, I:',
    options: MCQ_OPTIONS([
      ['A', 'Prioritize tasks and plan my time efficiently'],
      ['B', 'Work on whichever task I feel like first'],
      ['C', 'Rush everything at the last minute'],
      ['D', 'Delegate all tasks whenever possible'],
    ]),
  },
];

// S75 (Conflict SJT)
const softSjt = [
  {
    code: 'S75',
    cat: 'conflictManagement',
    text: 'A conflict arises between team members. You:',
    options: MCQ_OPTIONS([
      ['A', 'Stay out of it completely'],
      ['B', 'Mediate professionally and help clarify the issue'],
      ['C', 'Escalate immediately without discussion'],
      ['D', 'Take sides based on who seems stronger'],
    ]),
  },
];

async function main() {
  await connectDB();

  // Find section by title (covers "Soft Skills" / "Soft" etc.)
  const section =
    (await AssessmentSection.findOne({ title: 'Soft Skills' })) ||
    (await AssessmentSection.findOne({ title: /soft/i }));

  if (!section) {
    throw new Error('Soft Skills section not found. Run seed:sections first.');
  }

  let upserted = 0;

  // Likert
  for (const q of softLikert) {
    const doc = {
      sectionId: section._id,
      category: 'soft',
      questionCode: q.code,
      answerType: 'likert',
      text: q.text,
      options: LIKERT_OPTIONS,
      meta: {
        soft: {
          softType: 'likert',
          softCategory: q.cat,
          isReverse: q.isReverse,
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

  // Behavior MCQs
  for (const q of softBehavior) {
    const doc = {
      sectionId: section._id,
      category: 'soft',
      questionCode: q.code,
      answerType: 'single',
      text: q.text,
      options: q.options,
      meta: {
        soft: {
          softType: 'behavior',
          softCategory: q.cat,
          isReverse: false,
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

  // SJT
  for (const q of softSjt) {
    const doc = {
      sectionId: section._id,
      category: 'soft',
      questionCode: q.code,
      answerType: 'single',
      text: q.text,
      options: q.options,
      meta: {
        soft: {
          softType: 'sjt',
          softCategory: q.cat,
          isReverse: false,
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

  console.log(`✅ Soft Skills questions upserted: ${upserted} (S61–S75)`);
  await mongoose.disconnect();
  process.exit(0);
}

main().catch(async (err) => {
  console.error(err);
  await mongoose.disconnect();
  process.exit(1);
});