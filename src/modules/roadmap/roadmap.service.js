const Roadmap = require('./roadmap.model');
const UserRoadmapProgress = require('./userRoadmapProgress.model');
const UserAssessmentResult = require('../assessment/userAssessmentResult.model');
const User = require('../auth/user.model');

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

async function getChosenCareerAndRoadmap(userId) {
  const assessment = await UserAssessmentResult.findOne({ userId }).populate('chosenCareer');

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

// ---------- main ----------
const getUserRoadmap = async (userId) => {
  const { roadmap } = await getChosenCareerAndRoadmap(userId);
  return roadmap;
};

const getUserRoadmapWithProgress = async (userId) => {
  const { career, roadmap } = await getChosenCareerAndRoadmap(userId);

  let progress = await UserRoadmapProgress.findOne({
    userId,
    careerId: career._id,
  });

  if (!progress) {
    progress = await UserRoadmapProgress.create({
      userId,
      careerId: career._id,
      roadmapId: roadmap._id,
      completedSteps: [],
      completionPercent: 0,
    });
  }

  // Enrich response resources without forcing DB update
  const roadmapObj = roadmap.toObject();
  roadmapObj.phases = (roadmapObj.phases || []).map((phase) => ({
    ...phase,
    steps: (phase.steps || []).map((step) => {
      const hasResources = Array.isArray(step.resources) && step.resources.length > 0;
      if (!hasResources) {
        return {
          ...step,
          resources: buildSearchResources(step.skillTag, step.title),
        };
      }
      return step;
    }),
  }));

  return {
    career: {
      id: career._id,
      name: career.name,
    },
    roadmap: roadmapObj,
    completedSteps: progress.completedSteps || [],
    completionPercent: progress.completionPercent || 0,
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

  // clear any old progress for this user
  await UserRoadmapProgress.deleteMany({ userId });

  const progress = await UserRoadmapProgress.create({
    userId,
    careerId: assessment.chosenCareer,
    roadmapId: roadmap._id,
    completedSteps: [],
    completionPercent: 0,
  });

  return progress;
};

const calculateProgressPercentage = async (userId) => {
  const assessment = await UserAssessmentResult.findOne({ userId });
  if (!assessment || !assessment.chosenCareer) return 0;

  const progress = await UserRoadmapProgress.findOne({
    userId,
    careerId: assessment.chosenCareer,
  }).populate('roadmapId');

  if (!progress || !progress.roadmapId) return 0;

  let totalSteps = 0;
  (progress.roadmapId.phases || []).forEach((phase) => {
    totalSteps += (phase.steps || []).length;
  });

  const completed = (progress.completedSteps || []).length;

  if (totalSteps === 0) return 0;

  return Math.round((completed / totalSteps) * 100);
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

  if (existingIndex >= 0) {
    progress.completedSteps.splice(existingIndex, 1);
    isCompleted = false;
  } else {
    progress.completedSteps.push(step._id);
    isCompleted = true;

    const skillTag = normalizeText(step.skillTag);
    if (skillTag) {
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      const existingSkills = Array.isArray(user.skills) ? user.skills : [];
      const alreadyHasSkill = existingSkills.some(
        (s) => normalizeSkill(s) === normalizeSkill(skillTag)
      );

      if (!alreadyHasSkill) {
        user.skills.push(skillTag);
        await user.save();
        skillAdded = true;
      }
    }
  }

  progress.completionPercent = await calculateProgressPercentageAfterToggle(progress, roadmap);
  await progress.save();

  return {
    message: isCompleted ? 'Step marked as completed' : 'Step uncompleted',
    isCompleted,
    skillTag: step.skillTag,
    skillAdded,
    completedStepsCount: progress.completedSteps.length,
    completionPercent: progress.completionPercent,
  };
};

async function calculateProgressPercentageAfterToggle(progress, roadmap) {
  let totalSteps = 0;
  (roadmap.phases || []).forEach((phase) => {
    totalSteps += (phase.steps || []).length;
  });

  const completed = (progress.completedSteps || []).length;
  if (totalSteps === 0) return 0;

  return Math.round((completed / totalSteps) * 100);
}

const generateResourcesForCurrentRoadmap = async (userId) => {
  const { career, roadmap } = await getChosenCareerAndRoadmap(userId);

  const resourcesByStepId = {};
  let stepsCount = 0;

  for (const phase of roadmap.phases || []) {
    for (const step of phase.steps || []) {
      stepsCount += 1;

      resourcesByStepId[String(step._id)] =
        Array.isArray(step.resources) && step.resources.length > 0
          ? step.resources
          : buildSearchResources(step.skillTag, step.title);
    }
  }

  return {
    career: {
      id: career._id,
      name: career.name,
    },
    roadmapId: roadmap._id,
    stepsCount,
    resourcesByStepId,
  };
};

module.exports = {
  getUserRoadmap,
  getUserRoadmapWithProgress,
  initializeProgress,
  toggleStep,
  calculateProgressPercentage,
  generateResourcesForCurrentRoadmap,
};