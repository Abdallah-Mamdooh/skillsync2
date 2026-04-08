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

function buildSearchResources(skillTag, stepTitle) {
  const keyword = normalizeText(skillTag || stepTitle);
  const query = encodeURIComponent(keyword);

  return [
    {
      title: `YouTube: ${keyword}`,
      type: 'video',
      url: `https://www.youtube.com/results?search_query=${query}`,
    },
    {
      title: `Coursera: ${keyword}`,
      type: 'course',
      url: `https://www.coursera.org/search?query=${query}`,
    },
    {
      title: `Udemy: ${keyword}`,
      type: 'course',
      url: `https://www.udemy.com/courses/search/?q=${query}`,
    },
    {
      title: `Documentation: ${keyword}`,
      type: 'documentation',
      url: `https://www.google.com/search?q=${query}+documentation`,
    },
  ];
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
        step.resources = buildSearchResources(step.skillTag, step.title);
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