const Roadmap = require('./roadmap.model');
const UserRoadmapProgress = require('./userRoadmapProgress.model');
const UserAssessmentResult = require('../assessment/userAssessmentResult.model');
const User = require('../auth/user.model');
const notificationService = require('../notification/notification.service');

// ---------- helpers ----------
function normalizeText(value) {
  return String(value || '').trim();
}

function normalizeSkill(value) {
  return normalizeText(value).toLowerCase();
}

function pickBestSkillName(step) {
  const title = normalizeText(step?.title);
  const skillTag = normalizeText(step?.skillTag);

  // Prefer meaningful step title unless it is clearly noisy/import boilerplate
  const badTitlePatterns = [
    /^find the interactive version/i,
    /^roadmap\.sh/i,
    /^untitled$/i,
  ];

  const titleLooksBad = !title || badTitlePatterns.some((rx) => rx.test(title));

  if (!titleLooksBad) return title;
  if (skillTag) return skillTag;
  return title || '';
}

function sortRoadmap(roadmap) {
  roadmap.phases.sort((a, b) => a.order - b.order);
  roadmap.phases.forEach((phase) => {
    phase.steps.sort((a, b) => a.order - b.order);
  });
}

function makeResource(title, url, type = 'course', provider = 'General') {
  return { title, url, type, provider };
}

function encodeQ(q) {
  return encodeURIComponent(String(q || '').trim());
}

const CURATED_RESOURCES = {
  html: [
    makeResource(
      'HTML Full Course - freeCodeCamp',
      'https://www.youtube.com/watch?v=pQN-pnXPaVg',
      'video',
      'YouTube'
    ),
    makeResource(
      'HTML, CSS, and Javascript for Web Developers',
      'https://www.coursera.org/learn/html-css-javascript-for-web-developers',
      'course',
      'Coursera'
    ),
    makeResource(
      'HTML5 From Scratch',
      'https://www.udemy.com/courses/search/?q=html5%20from%20scratch',
      'course',
      'Udemy'
    ),
    makeResource(
      'HTML Documentation',
      'https://developer.mozilla.org/en-US/docs/Web/HTML',
      'documentation',
      'MDN'
    ),
  ],

  css: [
    makeResource(
      'CSS Full Course - freeCodeCamp',
      'https://www.youtube.com/watch?v=OXGznpKZ_sA',
      'video',
      'YouTube'
    ),
    makeResource(
      'Intro to CSS3',
      'https://www.coursera.org/learn/introcss',
      'course',
      'Coursera'
    ),
    makeResource(
      'CSS - The Complete Guide',
      'https://www.udemy.com/courses/search/?q=css%20the%20complete%20guide',
      'course',
      'Udemy'
    ),
    makeResource(
      'CSS Documentation',
      'https://developer.mozilla.org/en-US/docs/Web/CSS',
      'documentation',
      'MDN'
    ),
  ],

  javascript: [
    makeResource(
      'JavaScript Full Course - freeCodeCamp',
      'https://www.youtube.com/watch?v=PkZNo7MFNFg',
      'video',
      'YouTube'
    ),
    makeResource(
      'Programming Foundations with JavaScript, HTML and CSS',
      'https://www.coursera.org/learn/duke-programming-web',
      'course',
      'Coursera'
    ),
    makeResource(
      'The Complete JavaScript Course',
      'https://www.udemy.com/courses/search/?q=the%20complete%20javascript%20course',
      'course',
      'Udemy'
    ),
    makeResource(
      'JavaScript Documentation',
      'https://developer.mozilla.org/en-US/docs/Web/JavaScript',
      'documentation',
      'MDN'
    ),
  ],

  react: [
    makeResource(
      'React Course - freeCodeCamp',
      'https://www.youtube.com/watch?v=bMknfKXIFA8',
      'video',
      'YouTube'
    ),
    makeResource(
      'Front-End Web Development with React',
      'https://www.coursera.org/learn/front-end-react',
      'course',
      'Coursera'
    ),
    makeResource(
      'React - The Complete Guide',
      'https://www.udemy.com/courses/search/?q=react%20the%20complete%20guide',
      'course',
      'Udemy'
    ),
    makeResource(
      'React Documentation',
      'https://react.dev/',
      'documentation',
      'React'
    ),
  ],

  nodejs: [
    makeResource(
      'Node.js and Express.js - freeCodeCamp',
      'https://www.youtube.com/watch?v=Oe421EPjeBE',
      'video',
      'YouTube'
    ),
    makeResource(
      'Server-side Development with NodeJS, Express and MongoDB',
      'https://www.coursera.org/learn/server-side-nodejs',
      'course',
      'Coursera'
    ),
    makeResource(
      'The Complete Node.js Developer Course',
      'https://www.udemy.com/courses/search/?q=complete%20nodejs%20developer%20course',
      'course',
      'Udemy'
    ),
    makeResource(
      'Node.js Documentation',
      'https://nodejs.org/en/docs',
      'documentation',
      'Node.js'
    ),
  ],

  mongodb: [
    makeResource(
      'MongoDB Tutorial for Beginners',
      'https://www.youtube.com/watch?v=ExcRbA7fy_A',
      'video',
      'YouTube'
    ),
    makeResource(
      'Introduction to MongoDB',
      'https://www.coursera.org/search?query=introduction%20to%20mongodb',
      'course',
      'Coursera'
    ),
    makeResource(
      'MongoDB - The Complete Developer Guide',
      'https://www.udemy.com/courses/search/?q=mongodb%20complete%20developer%20guide',
      'course',
      'Udemy'
    ),
    makeResource(
      'MongoDB Documentation',
      'https://www.mongodb.com/docs/',
      'documentation',
      'MongoDB'
    ),
  ],

  flutter: [
    makeResource(
      'Flutter Course for Beginners - freeCodeCamp',
      'https://www.youtube.com/watch?v=VPvVD8t02U8',
      'video',
      'YouTube'
    ),
    makeResource(
      'Build Native Mobile Apps with Flutter',
      'https://www.coursera.org/search?query=flutter',
      'course',
      'Coursera'
    ),
    makeResource(
      'Flutter & Dart - The Complete Guide',
      'https://www.udemy.com/courses/search/?q=flutter%20dart%20complete%20guide',
      'course',
      'Udemy'
    ),
    makeResource(
      'Flutter Documentation',
      'https://docs.flutter.dev/',
      'documentation',
      'Flutter'
    ),
  ],

  python: [
    makeResource(
      'Python for Beginners - freeCodeCamp',
      'https://www.youtube.com/watch?v=rfscVS0vtbw',
      'video',
      'YouTube'
    ),
    makeResource(
      'Python for Everybody',
      'https://www.coursera.org/specializations/python',
      'course',
      'Coursera'
    ),
    makeResource(
      'Complete Python Bootcamp',
      'https://www.udemy.com/courses/search/?q=complete%20python%20bootcamp',
      'course',
      'Udemy'
    ),
    makeResource(
      'Python Documentation',
      'https://docs.python.org/3/',
      'documentation',
      'Python'
    ),
  ],
};

function buildSearchResources(skillTag, stepTitle, careerName = '') {
  const keyword = normalizeText(skillTag || stepTitle);
  const enriched = normalizeText(`${keyword} ${careerName}`.trim());
  const query = encodeQ(enriched || keyword);

  return [
    makeResource(
      `YouTube: ${keyword}`,
      `https://www.youtube.com/results?search_query=${query}`,
      'video',
      'YouTube'
    ),
    makeResource(
      `Coursera: ${keyword}`,
      `https://www.coursera.org/search?query=${query}`,
      'course',
      'Coursera'
    ),
    makeResource(
      `Udemy: ${keyword}`,
      `https://www.udemy.com/courses/search/?q=${query}`,
      'course',
      'Udemy'
    ),
    makeResource(
      `Documentation: ${keyword}`,
      `https://www.google.com/search?q=${query}+documentation`,
      'documentation',
      'Google'
    ),
  ];
}

function getBetterResourcesForStep(stepTitle, skillTag, careerName = '') {
  const normalizedSkill = String(skillTag || '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, '')
    .replace(/[-_]/g, '');

  const curated = CURATED_RESOURCES[normalizedSkill];

  if (curated && curated.length > 0) {
    return curated;
  }

  return buildSearchResources(skillTag, stepTitle, careerName);
}
function findStepInRoadmap(roadmap, stepId) {
  for (const phase of roadmap.phases || []) {
    for (const step of phase.steps || []) {
      if (String(step._id) === String(stepId)) {
        return { phase, step };
      }
    }
  }
  return null;
}

function countRoadmapSteps(roadmap) {
  let totalSteps = 0;
  for (const phase of roadmap.phases || []) {
    totalSteps += (phase.steps || []).length;
  }
  return totalSteps;
}

function calculateProgressPercentageFromRoadmap(progress, roadmap) {
  const totalSteps = countRoadmapSteps(roadmap);
  const completed = (progress.completedSteps || []).length;

  if (totalSteps === 0) return 0;
  return Math.round((completed / totalSteps) * 100);
}

function buildProgressSummary(progress, roadmap, career) {
  const totalSteps = countRoadmapSteps(roadmap);
  const completedStepsCount = Array.isArray(progress.completedSteps)
    ? progress.completedSteps.length
    : 0;

  const remainingStepsCount = Math.max(totalSteps - completedStepsCount, 0);

  const sortedHistory = Array.isArray(progress.stepHistory)
    ? [...progress.stepHistory].sort(
        (a, b) => new Date(b.completedAt) - new Date(a.completedAt)
      )
    : [];

  const latestCompletedStep = sortedHistory[0] || null;

  return {
    career: {
      id: career._id,
      name: career.name,
    },
    roadmapId: roadmap._id,
    totalSteps,
    completedStepsCount,
    remainingStepsCount,
    completionPercent: progress.completionPercent || 0,
    latestCompletedStep: latestCompletedStep
      ? {
          stepId: latestCompletedStep.stepId,
          completedAt: latestCompletedStep.completedAt,
        }
      : null,
  };
}

async function getSelectedCareerForUser(userId) {
  const [assessment, user] = await Promise.all([
    UserAssessmentResult.findOne({ userId }).populate('chosenCareer'),
    User.findById(userId).populate('chosenCareer'),
  ]);

  if (assessment?.chosenCareer) {
    return {
      source: 'assessment',
      career: assessment.chosenCareer,
      assessment,
      user,
    };
  }

  if (user?.chosenCareer) {
    return {
      source: 'user',
      career: user.chosenCareer,
      assessment,
      user,
    };
  }

  throw new Error('Assessment not completed or career not selected');
}

async function getChosenCareerAndRoadmap(userId) {
  const { assessment, career } = await getSelectedCareerForUser(userId);

  const roadmap = await Roadmap.findOne({
    careerId: career._id,
  });

  if (!roadmap) {
    throw new Error('Roadmap not found');
  }

  sortRoadmap(roadmap);

  return {
    assessment,
    career,
    roadmap,
  };
}

async function getOrCreateProgress(userId, careerId, roadmapId) {
  let progress = await UserRoadmapProgress.findOne({
    userId,
    careerId,
  });

  if (!progress) {
    progress = await UserRoadmapProgress.create({
      userId,
      careerId,
      roadmapId,
      completedSteps: [],
      stepHistory: [],
      completionPercent: 0,
    });
  }

  return progress;
}

async function syncUserSkillOnComplete(userId, step) {
  const bestSkill = pickBestSkillName(step);
  const cleanSkill = normalizeText(bestSkill);

  if (!cleanSkill) {
    return { added: false, skill: null };
  }

  const user = await User.findById(userId);
  if (!user) {
    throw new Error('User not found');
  }

  const existingSkills = Array.isArray(user.skills) ? user.skills : [];
  const alreadyHasSkill = existingSkills.some(
    (s) => normalizeSkill(s) === normalizeSkill(cleanSkill)
  );

  if (alreadyHasSkill) {
    return { added: false, skill: cleanSkill };
  }

  user.skills.push(cleanSkill);
  await user.save();

  return { added: true, skill: cleanSkill };
}

async function syncUserSkillOnUncomplete(userId, progress, roadmap, removedStep) {
  const cleanSkill = normalizeText(pickBestSkillName(removedStep));
  if (!cleanSkill) {
    return { removed: false, skill: null };
  }

  const stillCompletedStepIds = new Set(
    (progress.completedSteps || []).map((id) => String(id))
  );

  let skillStillExistsInCompletedSteps = false;

  for (const phase of roadmap.phases || []) {
    for (const step of phase.steps || []) {
      const sameSkill =
        normalizeSkill(pickBestSkillName(step)) === normalizeSkill(cleanSkill);

      const isStillCompleted = stillCompletedStepIds.has(String(step._id));

      if (sameSkill && isStillCompleted) {
        skillStillExistsInCompletedSteps = true;
        break;
      }
    }

    if (skillStillExistsInCompletedSteps) {
      break;
    }
  }

  if (skillStillExistsInCompletedSteps) {
    return { removed: false, skill: cleanSkill };
  }

  const user = await User.findById(userId);
  if (!user) {
    throw new Error('User not found');
  }

  const before = Array.isArray(user.skills) ? user.skills.length : 0;

  user.skills = (user.skills || []).filter(
    (s) => normalizeSkill(s) !== normalizeSkill(cleanSkill)
  );

  const after = user.skills.length;

  if (after !== before) {
    await user.save();
    return { removed: true, skill: cleanSkill };
  }

  return { removed: false, skill: cleanSkill };
}

// ---------- main ----------
const getUserRoadmap = async (userId) => {
  const { roadmap } = await getChosenCareerAndRoadmap(userId);
  return roadmap;
};

const getUserRoadmapWithProgress = async (userId) => {
  const { career, roadmap } = await getChosenCareerAndRoadmap(userId);

  const progress = await getOrCreateProgress(userId, career._id, roadmap._id);

  const completedSet = new Set(
    (progress.completedSteps || []).map((id) => String(id))
  );

  const historyMap = new Map(
    (progress.stepHistory || []).map((entry) => [
      String(entry.stepId),
      entry.completedAt,
    ])
  );

  const roadmapObj = roadmap.toObject();

  roadmapObj.phases = (roadmapObj.phases || []).map((phase) => ({
    ...phase,
    steps: (phase.steps || []).map((step) => ({
      ...step,
      displaySkill: pickBestSkillName(step),
      isCompleted: completedSet.has(String(step._id)),
      completedAt: historyMap.get(String(step._id)) || null,
    })),
  }));

  return {
    career: {
      id: career._id,
      name: career.name,
    },
    roadmap: roadmapObj,
    completedSteps: progress.completedSteps || [],
    completionPercent: progress.completionPercent || 0,
    summary: buildProgressSummary(progress, roadmap, career),
  };
};

const initializeProgress = async (userId) => {
  const { career, roadmap } = await getChosenCareerAndRoadmap(userId);

  await UserRoadmapProgress.deleteMany({ userId });

  const progress = await UserRoadmapProgress.create({
    userId,
    careerId: career._id,
    roadmapId: roadmap._id,
    completedSteps: [],
    stepHistory: [],
    completionPercent: 0,
  });

  return progress;
};

const calculateProgressPercentage = async (userId) => {
  const { career } = await getSelectedCareerForUser(userId);

  const progress = await UserRoadmapProgress.findOne({
    userId,
    careerId: career._id,
  }).populate('roadmapId');

  if (!progress || !progress.roadmapId) {
    return 0;
  }

  let totalSteps = 0;
  (progress.roadmapId.phases || []).forEach((phase) => {
    totalSteps += (phase.steps || []).length;
  });

  const completed = (progress.completedSteps || []).length;

  if (totalSteps === 0) return 0;

  return Math.round((completed / totalSteps) * 100);
};

const getProgressSummary = async (userId) => {
  const { career, roadmap } = await getChosenCareerAndRoadmap(userId);
  const progress = await getOrCreateProgress(userId, career._id, roadmap._id);

  return buildProgressSummary(progress, roadmap, career);
};

const toggleStep = async (userId, stepId) => {
  if (!stepId) {
    throw new Error('stepId is required');
  }

  const { career, roadmap } = await getChosenCareerAndRoadmap(userId);

  const progress = await UserRoadmapProgress.findOne({
    userId,
    careerId: career._id,
  });

  if (!progress) {
    throw new Error('Roadmap not initialized');
  }

  const found = findStepInRoadmap(roadmap, stepId);

  if (!found) {
    throw new Error('Step does not belong to this roadmap');
  }

  const { step } = found;
  const stepIdStr = String(stepId);

  const existingIndex = (progress.completedSteps || []).findIndex(
    (id) => String(id) === stepIdStr
  );

  let isCompleted = false;
  let skillAdded = false;
  let skillRemoved = false;
  let syncedSkillName = null;

  progress.stepHistory = Array.isArray(progress.stepHistory)
    ? progress.stepHistory
    : [];

  if (existingIndex >= 0) {
    progress.completedSteps.splice(existingIndex, 1);

    progress.stepHistory = progress.stepHistory.filter(
      (entry) => String(entry.stepId) !== stepIdStr
    );

    isCompleted = false;

    const removalResult = await syncUserSkillOnUncomplete(userId, progress, roadmap, step);
    skillRemoved = removalResult.removed;
    syncedSkillName = removalResult.skill;

    await notificationService.createNotification({
      userId,
      type: 'roadmap_step_uncompleted',
      title: 'Roadmap step unchecked',
      message: `You unchecked: ${step.title}`,
      data: {
        stepId: step._id,
        stepTitle: step.title,
        skillTag: step.skillTag,
        syncedSkillName,
        skillRemoved,
      },
    });
  } else {
    progress.completedSteps.push(step._id);

    progress.stepHistory = progress.stepHistory.filter(
      (entry) => String(entry.stepId) !== stepIdStr
    );

    progress.stepHistory.push({
      stepId: step._id,
      completedAt: new Date(),
    });

    isCompleted = true;

    const addResult = await syncUserSkillOnComplete(userId, step);
    skillAdded = addResult.added;
    syncedSkillName = addResult.skill;

    await notificationService.createNotification({
      userId,
      type: 'roadmap_step_completed',
      title: 'Roadmap step completed',
      message: `You completed: ${step.title}`,
      data: {
        stepId: step._id,
        stepTitle: step.title,
        skillTag: step.skillTag,
        syncedSkillName,
        skillAdded,
      },
    });

    if (skillAdded && syncedSkillName) {
      await notificationService.createNotification({
        userId,
        type: 'skill_added',
        title: 'New skill added',
        message: `${syncedSkillName} was added to your profile skills.`,
        data: {
          stepId: step._id,
          skillTag: step.skillTag,
          syncedSkillName,
        },
      });
    }
  }

  progress.completionPercent = calculateProgressPercentageFromRoadmap(
    progress,
    roadmap
  );

  await progress.save();

  const historyEntry = progress.stepHistory.find(
    (entry) => String(entry.stepId) === stepIdStr
  );

  return {
    message: isCompleted ? 'Step marked as completed' : 'Step uncompleted',
    isCompleted,
    skillTag: step.skillTag,
    syncedSkillName,
    skillAdded,
    skillRemoved,
    completedAt: historyEntry ? historyEntry.completedAt : null,
    completedStepsCount: progress.completedSteps.length,
    completionPercent: progress.completionPercent,
    summary: buildProgressSummary(progress, roadmap, career),
  };
};

const generateResourcesForCurrentRoadmap = async (userId) => {
  const { career, roadmap } = await getChosenCareerAndRoadmap(userId);

  let stepsCount = 0;
  let updatedSteps = 0;
  const resourcesByStepId = {};

  for (const phase of roadmap.phases || []) {
    for (const step of phase.steps || []) {
      stepsCount += 1;

      const hasResources =
        Array.isArray(step.resources) && step.resources.length > 0;

      if (!hasResources) {
        getBetterResourcesForStep(step.title || '', step.skillTag || '', career.name || '');

        updatedSteps += 1;
      }

      resourcesByStepId[String(step._id)] = step.resources;
    }
  }

  if (updatedSteps > 0) {
    await roadmap.save();
  }

  return {
    career: {
      id: career._id,
      name: career.name,
    },
    roadmapId: roadmap._id,
    stepsCount,
    updatedSteps,
    resourcesByStepId,
  };
};

const getRecentCompletions = async (userId, limit = 10) => {
  let selected;
  try {
    selected = await getSelectedCareerForUser(userId);
  } catch {
    return [];
  }

  const career = selected.career;

  const progress = await UserRoadmapProgress.findOne({
    userId,
    careerId: career._id,
  });

  if (
    !progress ||
    !Array.isArray(progress.stepHistory) ||
    progress.stepHistory.length === 0
  ) {
    return [];
  }

  const roadmap = await Roadmap.findOne({
    careerId: career._id,
  });

  if (!roadmap) {
    return [];
  }

  const allSteps = [];
  for (const phase of roadmap.phases || []) {
    for (const step of phase.steps || []) {
      allSteps.push(step);
    }
  }

  const stepMap = new Map(allSteps.map((step) => [String(step._id), step]));

  return [...progress.stepHistory]
    .sort((a, b) => new Date(b.completedAt) - new Date(a.completedAt))
    .slice(0, limit)
    .map((entry) => {
      const step = stepMap.get(String(entry.stepId));

      return {
        stepId: entry.stepId,
        title: step?.title || null,
        skillTag: step?.skillTag || null,
        syncedSkillName: step ? pickBestSkillName(step) : null,
        completedAt: entry.completedAt,
        career: {
          id: career._id,
          name: career.name,
        },
      };
    });
};

module.exports = {
  getUserRoadmap,
  getUserRoadmapWithProgress,
  initializeProgress,
  toggleStep,
  calculateProgressPercentage,
  getProgressSummary,
  generateResourcesForCurrentRoadmap,
  getRecentCompletions,
};