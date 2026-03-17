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

function sortRoadmap(roadmap) {
  roadmap.phases.sort((a, b) => a.order - b.order);
  roadmap.phases.forEach((phase) => {
    phase.steps.sort((a, b) => a.order - b.order);
  });
}

function buildSearchResources(skillTag, stepTitle) {
  const query = encodeURIComponent(normalizeText(skillTag || stepTitle));

  return [
    {
      title: `YouTube: ${normalizeText(skillTag || stepTitle)}`,
      type: 'video',
      url: `https://www.youtube.com/results?search_query=${query}`,
    },
    {
      title: `Coursera: ${normalizeText(skillTag || stepTitle)}`,
      type: 'course',
      url: `https://www.coursera.org/search?query=${query}`,
    },
    {
      title: `Documentation: ${normalizeText(skillTag || stepTitle)}`,
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

async function getChosenCareerAndRoadmap(userId) {
  const assessment = await UserAssessmentResult.findOne({ userId }).populate(
    'chosenCareer'
  );

  if (!assessment || !assessment.chosenCareer) {
    throw new Error('Assessment not completed or career not selected');
  }

  const roadmap = await Roadmap.findOne({
    careerId: assessment.chosenCareer._id,
  });

  if (!roadmap) {
    throw new Error('Roadmap not found');
  }

  sortRoadmap(roadmap);

  return {
    assessment,
    career: assessment.chosenCareer,
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

async function syncUserSkillOnComplete(userId, skillTag) {
  const cleanSkill = normalizeText(skillTag);
  if (!cleanSkill) {
    return false;
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
    return false;
  }

  user.skills.push(cleanSkill);
  await user.save();

  return true;
}

async function syncUserSkillOnUncomplete(userId, progress, roadmap, removedStep) {
  const cleanSkill = normalizeText(removedStep.skillTag);
  if (!cleanSkill) {
    return false;
  }

  const stillCompletedStepIds = new Set(
    (progress.completedSteps || []).map((id) => String(id))
  );

  let skillStillExistsInCompletedSteps = false;

  for (const phase of roadmap.phases || []) {
    for (const step of phase.steps || []) {
      const sameSkill =
        normalizeSkill(step.skillTag) === normalizeSkill(cleanSkill);

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
    return false;
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
    return true;
  }

  return false;
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
  const assessment = await UserAssessmentResult.findOne({ userId });

  if (!assessment || !assessment.chosenCareer) {
    throw new Error('Career must be selected first');
  }

  const roadmap = await Roadmap.findOne({
    careerId: assessment.chosenCareer,
  });

  if (!roadmap) {
    throw new Error('Roadmap not found');
  }

  await UserRoadmapProgress.deleteMany({ userId });

  const progress = await UserRoadmapProgress.create({
    userId,
    careerId: assessment.chosenCareer,
    roadmapId: roadmap._id,
    completedSteps: [],
    stepHistory: [],
    completionPercent: 0,
  });

  return progress;
};

const calculateProgressPercentage = async (userId) => {
  const assessment = await UserAssessmentResult.findOne({ userId });

  if (!assessment || !assessment.chosenCareer) {
    return 0;
  }

  const progress = await UserRoadmapProgress.findOne({
    userId,
    careerId: assessment.chosenCareer,
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

  progress.stepHistory = Array.isArray(progress.stepHistory)
    ? progress.stepHistory
    : [];

  if (existingIndex >= 0) {
    // uncomplete
    progress.completedSteps.splice(existingIndex, 1);

    progress.stepHistory = progress.stepHistory.filter(
      (entry) => String(entry.stepId) !== stepIdStr
    );

    isCompleted = false;

    skillRemoved = await syncUserSkillOnUncomplete(userId, progress, roadmap, step);

    await notificationService.createNotification({
      userId,
      type: 'roadmap_step_uncompleted',
      title: 'Roadmap step unchecked',
      message: `You unchecked: ${step.title}`,
      data: {
        stepId: step._id,
        stepTitle: step.title,
        skillTag: step.skillTag,
        skillRemoved,
      },
    });
  } else {
    // complete
    progress.completedSteps.push(step._id);

    progress.stepHistory = progress.stepHistory.filter(
      (entry) => String(entry.stepId) !== stepIdStr
    );

    progress.stepHistory.push({
      stepId: step._id,
      completedAt: new Date(),
    });

    isCompleted = true;

    skillAdded = await syncUserSkillOnComplete(userId, step.skillTag);

    await notificationService.createNotification({
      userId,
      type: 'roadmap_step_completed',
      title: 'Roadmap step completed',
      message: `You completed: ${step.title}`,
      data: {
        stepId: step._id,
        stepTitle: step.title,
        skillTag: step.skillTag,
        skillAdded,
      },
    });

    if (skillAdded) {
      await notificationService.createNotification({
        userId,
        type: 'skill_added',
        title: 'New skill added',
        message: `${step.skillTag} was added to your profile skills.`,
        data: {
          stepId: step._id,
          skillTag: step.skillTag,
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
    message: isCompleted
      ? 'Step marked as completed'
      : 'Step uncompleted',
    isCompleted,
    skillTag: step.skillTag,
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
  const assessment = await UserAssessmentResult.findOne({ userId }).populate(
    'chosenCareer'
  );

  if (!assessment || !assessment.chosenCareer) {
    return [];
  }

  const progress = await UserRoadmapProgress.findOne({
    userId,
    careerId: assessment.chosenCareer._id,
  });

  if (
    !progress ||
    !Array.isArray(progress.stepHistory) ||
    progress.stepHistory.length === 0
  ) {
    return [];
  }

  const roadmap = await Roadmap.findOne({
    careerId: assessment.chosenCareer._id,
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
        completedAt: entry.completedAt,
        career: {
          id: assessment.chosenCareer._id,
          name: assessment.chosenCareer.name,
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