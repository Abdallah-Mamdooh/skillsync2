const UserAssessmentResult = require('./userAssessmentResult.model');
const AssessmentSection = require('./assessmentSection.model');
const Question = require('./question.model');
const Career = require('../career/career.model');
const User = require('../auth/user.model');
const { scoreAssessment } = require('./scoring');
const { initializeProgress } = require('../roadmap/roadmap.service');

// -------------------- helpers --------------------
function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

function normalizeInterest(s) {
  return String(s || '').toLowerCase().trim();
}

// -------------------- base queries --------------------
const getSections = async () => {
  return AssessmentSection.find().sort({ order: 1 });
};

/**
 * ✅ Smart questions loader
 * - For non-technical sections: return all questions ordered by questionCode
 * - For Technical: return (core + specialty) based on user's selectedInterests
 */
const getQuestionsBySection = async (sectionId, userId) => {
  const section = await AssessmentSection.findById(sectionId);
  if (!section) throw new Error('Section not found');

  const isTechnical = String(section.title || '').toLowerCase() === 'technical';

  if (!isTechnical) {
    return Question.find({ sectionId }).sort({ questionCode: 1 });
  }

  // Technical section needs user interests
  if (!userId) throw new Error('userId is required for technical questions');

  const user = await User.findById(userId);
  const selectedInterests = Array.isArray(user?.selectedInterests) ? user.selectedInterests : [];

  if (!selectedInterests.length) {
    // If they didn't pick interests yet, return only non-specialty technical questions (core)
    return Question.find({
      sectionId,
      category: 'technical',
      'meta.technical.isSpecialty': { $ne: true },
    }).sort({ questionCode: 1 });
  }

  const techBundle = await generateTechnicalQuestions({
    sectionId,
    selectedInterests,
  });

  return techBundle.questions;
};

/**
 * ✅ Technical generator (matches YOUR schema)
 *
 * Rules:
 * - base/core questions = technical questions where meta.technical.isSpecialty !== true
 * - specialty questions = technical questions where meta.technical.isSpecialty === true
 * - for each selected interest (max 3):
 *   pick 3 questions: 1 concept + 1 tool + 1 applied
 *
 * We map "kind" using meta.technical.area:
 *   area: "concept" | "tool" | "applied"
 *   interest: "web" | "data_ai" | "security" | ...
 */
const generateTechnicalQuestions = async ({ sectionId, selectedInterests }) => {
  if (!Array.isArray(selectedInterests) || selectedInterests.length === 0) {
    throw new Error('selectedInterests is required (array)');
  }

  // limit to 3 and normalize
  const interests = selectedInterests.slice(0, 3).map(normalizeInterest);

  // get all technical questions for this section
  const allTech = await Question.find({
    sectionId,
    category: 'technical',
  });

  // Core = ONLY non-specialty questions that start with T (not TX...) AND are within your base set
// Easiest reliable rule: questionCode starts with "T" AND does NOT start with "TS-"
const core = allTech.filter((q) => {
  const code = String(q.questionCode || '');
  const isSpecialty = q.meta?.technical?.isSpecialty === true || code.startsWith('TS-');
  const isBase = /^T(3[3-9]|4[0-9]|5[01])$/.test(code); // T33..T51 (19 questions)
  return !isSpecialty && isBase;
});

const specialty = allTech.filter((q) => {
  const code = String(q.questionCode || '');
  return q.meta?.technical?.isSpecialty === true || code.startsWith('TS-');
});

  const pickedSpecialty = [];

  const pickRandom = (arr) => (arr.length ? arr[Math.floor(Math.random() * arr.length)] : null);

  for (const interest of interests) {
    const pool = specialty.filter(
      (q) => normalizeInterest(q?.meta?.technical?.interest) === interest
    );

    // Use meta.technical.area as "kind"
    const concept = pool.filter((q) => normalizeInterest(q?.meta?.technical?.area) === 'concept');
    const tool = pool.filter((q) => normalizeInterest(q?.meta?.technical?.area) === 'tool');
    const applied = pool.filter((q) => normalizeInterest(q?.meta?.technical?.area) === 'applied');

    const c = pickRandom(concept);
    const t = pickRandom(tool);
    const a = pickRandom(applied);

    if (c) pickedSpecialty.push(c);
    if (t) pickedSpecialty.push(t);
    if (a) pickedSpecialty.push(a);
  }

  // Avoid duplicates (in case DB has overlaps)
  const uniq = new Map();
  [...core, ...pickedSpecialty].forEach((q) => {
    uniq.set(String(q._id), q);
  });

  const final = shuffle([...uniq.values()]);

  return {
    count: final.length,
    coreCount: core.length,
    specialtyCount: pickedSpecialty.length,
    selectedInterests: interests,
    questions: final,
  };
};

// -------------------- submit assessment --------------------
const submitAssessment = async (userId, answers, forceOverwrite = false) => {
  const existing = await UserAssessmentResult.findOne({ userId });

  if (existing && !forceOverwrite) {
    return {
      requiresConfirmation: true,
      message:
        'You have already completed the assessment. Submitting again will overwrite previous results.',
    };
  }

  if (existing && forceOverwrite) {
    await UserAssessmentResult.deleteOne({ userId });
  }

  const careers = await Career.find();
  if (!careers.length) {
    throw new Error('No careers found in system');
  }

  const questionIds = (answers || []).map((a) => a.questionId);
  const questions = await Question.find({ _id: { $in: questionIds } });
  const questionMap = new Map(questions.map((q) => [String(q._id), q]));

  const answersWithQuestions = (answers || []).map((a) => ({
    questionId: a.questionId,
    selectedOptionIndex: a.selectedOptionIndex,
    question: questionMap.get(String(a.questionId)),
  }));

  const { rankedCareers, personalityResult, technicalResult, softSkillsResult } =
    scoreAssessment({ answersWithQuestions, careers });

  // keep old compatibility array too
  const scores = rankedCareers.map((x) => ({
    careerId: x.careerId,
    percentage: Math.round(x.finalScore),
    totalScore: x.finalScore,
  }));

  const saved = await UserAssessmentResult.create({
    userId,
    rankedCareers,
    scores,
    personalityResult,
    technicalResult,
    softSkillsResult,
  });

  // (optional) mark user flag
  await User.findByIdAndUpdate(userId, { assessmentCompleted: true });

  return saved;
};

// -------------------- choose career --------------------
const chooseCareer = async (userId, careerId) => {
  const result = await UserAssessmentResult.findOne({ userId });

  if (!result) {
    throw new Error('Assessment not completed');
  }

  result.chosenCareer = careerId;
  await result.save();

  await initializeProgress(userId);

  return { message: 'Career selected and roadmap initialized' };
};

// -------------------- get assessment result --------------------
const getMyAssessmentResult = async (userId) => {
  const result = await UserAssessmentResult.findOne({ userId }).populate('chosenCareer');

  if (!result) {
    return {
      hasResult: false,
      message: 'No assessment result found for this user yet',
    };
  }

  const toPercent = (v) => {
    const n = Number(v);
    if (Number.isNaN(n)) return 0;
    return Math.max(0, Math.min(100, Math.round(n)));
  };

  const formatRanked = (arr) => {
    if (!Array.isArray(arr)) return [];
    return arr
      .map((c) => {
        const finalScore = toPercent(c.finalScore ?? c.score ?? c.percentage);
        return {
          careerId: c.careerId || c.id || c._id,
          name: c.name,
          percentage: finalScore,
          distance: 100 - finalScore,
          breakdown: {
            technical: toPercent(c.technical),
            personality: toPercent(c.personality),
            soft: toPercent(c.soft),
          },
        };
      })
      .sort((a, b) => b.percentage - a.percentage);
  };

  return {
    hasResult: true,
    chosenCareer: result.chosenCareer
      ? { id: result.chosenCareer._id, name: result.chosenCareer.name }
      : null,

    rankedCareers: result.rankedCareers || null,
    scores: result.scores || null,

    personality: result.personalityResult || result.personality || null,
    technical: result.technicalResult || result.technical || null,
    softSkills: result.softSkillsResult || result.softSkills || null,

    createdAt: result.createdAt,
    updatedAt: result.updatedAt,
    suggestions: formatRanked(result.rankedCareers || result.scores),
  };
};

// -------------------- interests --------------------
const ALLOWED_INTERESTS = [
  'web',
  'data_ai',
  'security',
  'design',
  'product',
  'devops',
  'qa',
  'mobile_game',
];

const saveInterests = async (userId, body) => {
  const interests = Array.isArray(body.interests) ? body.interests : [];

  const cleaned = interests
    .map((x) => String(x).trim().toLowerCase())
    .filter((x) => ALLOWED_INTERESTS.includes(x));

  const unique = [...new Set(cleaned)].slice(0, 3);

  const user = await User.findById(userId);
  if (!user) throw new Error('User not found');

  user.selectedInterests = unique;
  await user.save();

  return { selectedInterests: unique };
};

module.exports = {
  getSections,
  getQuestionsBySection,
  generateTechnicalQuestions,
  submitAssessment,
  chooseCareer,
  getMyAssessmentResult,
  saveInterests,
};