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
  for (let i = a.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

function normalizeInterest(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, '_')
    .replace(/[/-]+/g, '_');
}

function isTechnicalSection(section) {
  const type = String(section?.type || '').toLowerCase();
  const title = String(section?.title || '').toLowerCase();
  return type === 'technical' || title === 'technical';
}

function toObjectIdString(value) {
  return String(value || '');
}

function ensureArray(value) {
  return Array.isArray(value) ? value : [];
}

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

// optional aliases so frontend labels can still work
const INTEREST_ALIASES = {
  web_development: 'web',
  webdevelopment: 'web',
  'web development': 'web',
  data: 'data_ai',
  ai: 'data_ai',
  'data / ai': 'data_ai',
  data_ai: 'data_ai',
  infrastructure: 'devops',
  infrastructure_devops: 'devops',
  'infrastructure / devops': 'devops',
  testing: 'qa',
  qa_testing: 'qa',
  'qa / testing': 'qa',
  mobile: 'mobile_game',
  game: 'mobile_game',
  mobile_game: 'mobile_game',
  'mobile / game': 'mobile_game',
};

function cleanInterest(value) {
  const normalized = normalizeInterest(value);
  return INTEREST_ALIASES[normalized] || normalized;
}

function buildSuggestions(arr) {
  const list = ensureArray(arr);

  return list
    .map((item) => {
      const finalScore = Number(item.finalScore ?? item.score ?? item.percentage ?? 0);
      const safeScore = Math.max(0, Math.min(100, Math.round(finalScore)));

      return {
        careerId: item.careerId || item.id || item._id || null,
        name: item.name || 'Unknown Career',
        percentage: safeScore,
        distance: 100 - safeScore,
        breakdown: {
          technical: Math.max(0, Math.min(100, Math.round(Number(item.technical || 0)))),
          personality: Math.max(0, Math.min(100, Math.round(Number(item.personality || 0)))),
          soft: Math.max(0, Math.min(100, Math.round(Number(item.soft || 0)))),
        },
      };
    })
    .sort((a, b) => b.percentage - a.percentage);
}

// -------------------- base queries --------------------
const getSections = async () => {
  return AssessmentSection.find().sort({ order: 1 }).lean();
};

/**
 * For non-technical sections:
 *   return all questions ordered by questionCode
 *
 * For technical section:
 *   return core + specialty questions based on user selected interests
 */
const getQuestionsBySection = async (sectionId, userId) => {
  const section = await AssessmentSection.findById(sectionId).lean();
  if (!section) {
    throw new Error('Section not found');
  }

  if (!isTechnicalSection(section)) {
    return Question.find({ sectionId }).sort({ questionCode: 1 }).lean();
  }

  if (!userId) {
    throw new Error('userId is required for technical questions');
  }

  const user = await User.findById(userId).lean();
  if (!user) {
    throw new Error('User not found');
  }

  const selectedInterests = ensureArray(user.selectedInterests).map(cleanInterest);

  if (!selectedInterests.length) {
    return Question.find({
      sectionId,
      category: 'technical',
      'meta.technical.isSpecialty': { $ne: true },
    })
      .sort({ questionCode: 1 })
      .lean();
  }

  const techBundle = await generateTechnicalQuestions({
    sectionId,
    selectedInterests,
  });

  return techBundle.questions;
};

/**
 * Technical question generator
 *
 * Rules:
 * - core questions = technical questions where meta.technical.isSpecialty !== true
 * - specialty questions = technical questions where meta.technical.isSpecialty === true
 * - for each selected interest (max 3):
 *   pick 3 questions: 1 concept + 1 tool + 1 applied
 */
const generateTechnicalQuestions = async ({ sectionId, selectedInterests }) => {
  const interests = ensureArray(selectedInterests)
    .map(cleanInterest)
    .filter((x) => ALLOWED_INTERESTS.includes(x))
    .slice(0, 3);

  if (!interests.length) {
    throw new Error('selectedInterests is required (array)');
  }

  const allTech = await Question.find({
    sectionId,
    category: 'technical',
  }).lean();

  const core = allTech.filter((q) => {
    const code = String(q.questionCode || '');
    const isSpecialty = q?.meta?.technical?.isSpecialty === true || code.startsWith('TS-');

    // keep your current MVP base question range if present
    const isMvpBaseRange = /^T(3[3-9]|4[0-9]|5[01])$/.test(code);

    // fallback: if future seeds change, still allow any non-specialty technical question
    return !isSpecialty && (isMvpBaseRange || !code.startsWith('TS-'));
  });

  const specialty = allTech.filter((q) => {
    const code = String(q.questionCode || '');
    return q?.meta?.technical?.isSpecialty === true || code.startsWith('TS-');
  });

  const pickRandom = (arr) => (arr.length ? arr[Math.floor(Math.random() * arr.length)] : null);
  const pickedSpecialty = [];

  for (const interest of interests) {
    const pool = specialty.filter(
      (q) => cleanInterest(q?.meta?.technical?.interest) === interest
    );

    const conceptPool = pool.filter(
      (q) => normalizeInterest(q?.meta?.technical?.area) === 'concept'
    );
    const toolPool = pool.filter(
      (q) => normalizeInterest(q?.meta?.technical?.area) === 'tool'
    );
    const appliedPool = pool.filter(
      (q) => normalizeInterest(q?.meta?.technical?.area) === 'applied'
    );

    const concept = pickRandom(conceptPool);
    const tool = pickRandom(toolPool);
    const applied = pickRandom(appliedPool);

    if (concept) pickedSpecialty.push(concept);
    if (tool) pickedSpecialty.push(tool);
    if (applied) pickedSpecialty.push(applied);
  }

  const unique = new Map();
  [...core, ...pickedSpecialty].forEach((q) => {
    unique.set(toObjectIdString(q._id), q);
  });

  const finalQuestions = shuffle([...unique.values()]);

  return {
    count: finalQuestions.length,
    coreCount: core.length,
    specialtyCount: pickedSpecialty.length,
    selectedInterests: interests,
    questions: finalQuestions,
  };
};

// -------------------- submit assessment --------------------
const submitAssessment = async (userId, answers, forceOverwrite = false) => {
  const user = await User.findById(userId);
  if (!user) {
    throw new Error('User not found');
  }

  const safeAnswers = ensureArray(answers);
  if (!safeAnswers.length) {
    throw new Error('Answers are required');
  }

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

  const careers = await Career.find().lean();
  if (!careers.length) {
    throw new Error('No careers found in system');
  }

  const questionIds = safeAnswers.map((a) => a.questionId);
  const questions = await Question.find({ _id: { $in: questionIds } }).lean();
  const questionMap = new Map(questions.map((q) => [toObjectIdString(q._id), q]));

  const answersWithQuestions = safeAnswers.map((a) => {
    const question = questionMap.get(toObjectIdString(a.questionId));

    if (!question) {
      throw new Error(`Invalid questionId: ${a.questionId}`);
    }

    const optionIndex = Number(a.selectedOptionIndex);
    if (Number.isNaN(optionIndex) || optionIndex < 0 || optionIndex >= question.options.length) {
      throw new Error(
        `Invalid selectedOptionIndex for question ${question.questionCode || question._id}`
      );
    }

    return {
      questionId: a.questionId,
      selectedOptionIndex: optionIndex,
      question,
      selectedOption: question.options[optionIndex],
    };
  });

  const selectedInterests = ensureArray(user.selectedInterests).map(cleanInterest);

  const scoringResult = scoreAssessment({
    answersWithQuestions,
    careers,
    selectedInterests,
  });

  const {
    rankedCareers = [],
    personalityResult = null,
    technicalResult = null,
    softSkillsResult = null,
    weights = null,
  } = scoringResult || {};

  const scores = rankedCareers.map((item) => ({
    careerId: item.careerId,
    percentage: Math.max(0, Math.min(100, Math.round(Number(item.finalScore || 0)))),
    totalScore: Number(item.finalScore || 0),
  }));

  const saved = await UserAssessmentResult.create({
    userId,
    rankedCareers,
    scores,
    personalityResult,
    technicalResult,
    softSkillsResult,
    weights,
  });

  user.assessmentCompleted = true;
  await user.save();

  return {
    ...saved.toObject(),
    suggestions: buildSuggestions(rankedCareers),
  };
};

// -------------------- choose career --------------------
const chooseCareer = async (userId, careerId) => {
  const [result, career, user] = await Promise.all([
    UserAssessmentResult.findOne({ userId }),
    Career.findById(careerId),
    User.findById(userId),
  ]);

  if (!result) {
    throw new Error('Assessment not completed');
  }

  if (!career) {
    throw new Error('Career not found');
  }

  if (!user) {
    throw new Error('User not found');
  }

  const suggestedCareerIds = new Set([
    ...ensureArray(result.rankedCareers).map((x) => toObjectIdString(x.careerId)),
    ...ensureArray(result.scores).map((x) => toObjectIdString(x.careerId)),
  ]);

  if (suggestedCareerIds.size && !suggestedCareerIds.has(toObjectIdString(careerId))) {
    throw new Error('Selected career is not part of this assessment result');
  }

  result.chosenCareer = careerId;
  await result.save();

  // keep User in sync too
  user.chosenCareer = careerId;
  await user.save();

  await initializeProgress(userId);

  return {
    message: 'Career selected and roadmap initialized',
    chosenCareer: {
      id: career._id,
      name: career.name,
    },
  };
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

  return {
    hasResult: true,
    chosenCareer: result.chosenCareer
      ? { id: result.chosenCareer._id, name: result.chosenCareer.name }
      : null,
    rankedCareers: result.rankedCareers || [],
    scores: result.scores || [],
    personality: result.personalityResult || null,
    technical: result.technicalResult || null,
    softSkills: result.softSkillsResult || null,
    createdAt: result.createdAt,
    updatedAt: result.updatedAt,
    suggestions: buildSuggestions(result.rankedCareers || result.scores),
  };
};

// -------------------- interests --------------------
const saveInterests = async (userId, body) => {
  const rawInterests = ensureArray(body?.interests);
  const cleaned = rawInterests
    .map(cleanInterest)
    .filter((x) => ALLOWED_INTERESTS.includes(x));

  const unique = [...new Set(cleaned)].slice(0, 3);

  const user = await User.findById(userId);
  if (!user) {
    throw new Error('User not found');
  }

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