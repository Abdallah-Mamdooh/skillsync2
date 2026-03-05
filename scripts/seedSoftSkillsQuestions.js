require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('../src/config/db');

const AssessmentSection = require('../src/modules/assessment/assessmentSection.model');
const Question = require('../src/modules/assessment/question.model');

// Likert options (A-E)
const LIKERT_OPTIONS = [
  { key: 'A', text: 'Strongly Agree' },
  { key: 'B', text: 'Agree' },
  { key: 'C', text: 'Neutral' },
  { key: 'D', text: 'Disagree' },
  { key: 'E', text: 'Strongly Disagree' },
];

function makeSoftLikert({ code, text, softCategory, isReverse }) {
  return {
    category: 'soft',
    questionCode: code,
    answerType: 'likert',
    text,
    options: LIKERT_OPTIONS,
    meta: {
      soft: {
        softType: 'likert',
        softCategory,
        isReverse: !!isReverse,
      },
    },
  };
}

function makeSoftMCQ({ code, text, options, softCategory, softType }) {
  return {
    category: 'soft',
    questionCode: code,
    answerType: 'single',
    text,
    options: options.map((t, idx) => ({
      key: String.fromCharCode(65 + idx), // A-D
      text: t,
      // no isCorrect here (we score later by mapping points)
      isCorrect: false,
      careerWeights: [],
    })),
    meta: {
      soft: {
        softType, // "behavior" or "sjt"
        softCategory,
        isReverse: false,
      },
    },
  };
}

async function main() {
  await connectDB();

  const section = await AssessmentSection.findOne({ title: 'Soft Skills' });
  if (!section) throw new Error('Soft Skills section not found. Run seed:sections first.');

  const Q = [];

  // ===== Section A: Likert (8) =====
  // Reverse ones: miss deadlines, panic, misunderstand, wait for instructions
  Q.push(
    makeSoftLikert({ code: 'S61', text: 'I manage my time effectively.', softCategory: 'timeManagement', isReverse: false }),
    makeSoftLikert({ code: 'S62', text: 'I frequently miss deadlines.', softCategory: 'timeManagement', isReverse: true }),

    makeSoftLikert({ code: 'S63', text: 'I handle stress well.', softCategory: 'selfManagement', isReverse: false }),
    makeSoftLikert({ code: 'S64', text: 'I panic under pressure.', softCategory: 'selfManagement', isReverse: true }),

    makeSoftLikert({ code: 'S65', text: 'I communicate clearly.', softCategory: 'communication', isReverse: false }),
    makeSoftLikert({ code: 'S66', text: 'I often misunderstand instructions.', softCategory: 'communication', isReverse: true }),

    makeSoftLikert({ code: 'S67', text: 'I take initiative.', softCategory: 'leadership', isReverse: false }),
    makeSoftLikert({ code: 'S68', text: 'I wait for instructions before acting.', softCategory: 'leadership', isReverse: true })
  );

  // ===== Section B: Behavior MCQ (6) =====
  Q.push(
    makeSoftMCQ({
      code: 'S69',
      softType: 'behavior',
      softCategory: 'communication',
      text: 'When explaining a complex idea to a team, I:',
      options: [
        'Break it into simple parts and check understanding',
        'Explain quickly and assume they understand',
        'Give written instructions only',
        'Avoid explaining and let them figure it out',
      ],
    }),
    makeSoftMCQ({
      code: 'S70',
      softType: 'behavior',
      softCategory: 'teamwork',
      text: 'In a group project, I usually:',
      options: [
        'Offer help to teammates who are struggling',
        'Focus only on my assigned tasks',
        'Take over tasks from others without asking',
        'Avoid collaboration as much as possible',
      ],
    }),
    makeSoftMCQ({
      code: 'S71',
      softType: 'behavior',
      softCategory: 'adaptability',
      text: 'When project requirements suddenly change, I:',
      options: [
        'Adjust plans quickly and continue',
        'Complain about the change',
        'Wait for someone else to decide what to do',
        'Stop working until direction is clear',
      ],
    }),
    makeSoftMCQ({
      code: 'S72',
      softType: 'behavior',
      softCategory: 'problemSolving',
      text: 'When encountering a technical problem I do not know, I:',
      options: [
        'Research and try multiple solutions',
        'Ask someone else to solve it immediately',
        'Ignore it and continue with other work',
        'Document the problem and wait without trying',
      ],
    }),
    makeSoftMCQ({
      code: 'S73',
      softType: 'behavior',
      softCategory: 'leadership',
      text: 'If a teammate is demotivated, I:',
      options: [
        'Encourage them and offer guidance',
        'Leave them to handle it alone',
        'Complain to management about them',
        'Take over their tasks without discussion',
      ],
    }),
    makeSoftMCQ({
      code: 'S74',
      softType: 'behavior',
      softCategory: 'timeManagement',
      text: 'When I have multiple deadlines, I:',
      options: [
        'Prioritize tasks and plan my time efficiently',
        'Work on whichever task I feel like first',
        'Rush everything at the last minute',
        'Delegate all tasks whenever possible',
      ],
    })
  );

  // ===== Section C: Conflict SJT (1) =====
  Q.push(
    makeSoftMCQ({
      code: 'S75',
      softType: 'sjt',
      softCategory: 'conflictManagement',
      text: 'A conflict arises between team members. You:',
      options: [
        'Stay out of it completely',
        'Mediate professionally and help clarify the issue',
        'Escalate immediately without discussion',
        'Take sides based on who seems stronger',
      ],
    })
  );

  const docs = Q.map((q) => ({ ...q, sectionId: section._id }));

  let upserted = 0;
  for (const doc of docs) {
    await Question.findOneAndUpdate(
      { questionCode: doc.questionCode },
      { $set: doc },
      { upsert: true, new: true }
    );
    upserted++;
  }

  console.log(`✅ Soft skills questions upserted: ${upserted}`);
  await mongoose.disconnect();
  process.exit(0);
}

main().catch(async (err) => {
  console.error(err);
  await mongoose.disconnect();
  process.exit(1);
});