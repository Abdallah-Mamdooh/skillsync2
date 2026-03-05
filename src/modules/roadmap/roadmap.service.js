const Roadmap = require('./roadmap.model');
const UserRoadmapProgress = require('./userRoadmapProgress.model');
const UserAssessmentResult = require('../assessment/userAssessmentResult.model');
const User = require('../auth/user.model');

function sortRoadmap(roadmap) {
  roadmap.phases.sort((a, b) => a.order - b.order);
  roadmap.phases.forEach((phase) => {
    phase.steps.sort((a, b) => a.order - b.order);
  });
}

async function getChosenCareerAndRoadmap(userId) {
  const assessment = await UserAssessmentResult.findOne({ userId }).populate('chosenCareer');

  if (!assessment || !assessment.chosenCareer) {
    throw new Error('Assessment not completed or career not selected');
  }

  const roadmap = await Roadmap.findOne({ careerId: assessment.chosenCareer._id });
  if (!roadmap) throw new Error('Roadmap not found');

  sortRoadmap(roadmap);

  return { assessment, career: assessment.chosenCareer, roadmap };
}

function findStepInRoadmap(roadmap, stepId) {
  for (const phase of roadmap.phases) {
    for (const step of phase.steps) {
      if (String(step._id) === String(stepId)) return step;
    }
  }
  return null;
}

function normalizeSkillTag(s) {
  return String(s || '')
    .trim()
    .replace(/\s+/g, ' ');
}

// -------------------- Step 12 helpers (resources) --------------------
function makeResource(title, url, provider = 'General') {
  return { title, url, provider };
}

function encodeQ(q) {
  return encodeURIComponent(String(q || '').trim());
}

function defaultResourcesForStep(stepTitle, skillTag, careerName) {
  const q = `${skillTag || stepTitle} ${careerName || ''}`.trim();

  return [
    makeResource(
      `YouTube: ${q}`,
      `https://www.youtube.com/results?search_query=${encodeQ(q)}`,
      'YouTube'
    ),
    makeResource(
      `Coursera: ${q}`,
      `https://www.coursera.org/search?query=${encodeQ(q)}`,
      'Coursera'
    ),
    makeResource(
      `Udemy: ${q}`,
      `https://www.udemy.com/courses/search/?q=${encodeQ(q)}`,
      'Udemy'
    ),
  ];
}
// --------------------------------------------------------------------

const getUserRoadmap = async (userId) => {
  const { roadmap } = await getChosenCareerAndRoadmap(userId);
  return roadmap;
};

// ✅ return roadmap + progress together (for checklist UI)
const getUserRoadmapWithProgress = async (userId) => {
  const { career, roadmap } = await getChosenCareerAndRoadmap(userId);

  let progress = await UserRoadmapProgress.findOne({ userId, careerId: career._id });

  if (!progress) {
    progress = await UserRoadmapProgress.create({
      userId,
      careerId: career._id,
      roadmapId: roadmap._id,
      completedSteps: [],
      completionPercent: 0,
    });
  }

  const completionPercent = await calculateProgressPercentage(userId);
  progress.completionPercent = completionPercent;
  await progress.save();

  return {
    career: { id: career._id, name: career.name },
    progress: {
      completionPercent,
      completedSteps: progress.completedSteps,
    },
    roadmap,
  };
};

const initializeProgress = async (userId) => {
  const assessment = await UserAssessmentResult.findOne({ userId });

  if (!assessment || !assessment.chosenCareer) {
    throw new Error('Career must be selected first');
  }

  const roadmap = await Roadmap.findOne({ careerId: assessment.chosenCareer });
  if (!roadmap) throw new Error('Roadmap not found');

  // Delete old progress if exists (for any previous career)
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

// ✅ TOGGLE step (complete/uncomplete)
// on complete -> add skillTag/title to user.skills if not already there
const toggleStep = async (userId, stepId) => {
  const { career, roadmap } = await getChosenCareerAndRoadmap(userId);

  const progress = await UserRoadmapProgress.findOne({ userId, careerId: career._id });
  if (!progress) throw new Error('Roadmap not initialized');

  const idx = progress.completedSteps.findIndex((s) => String(s) === String(stepId));

  let action = 'completed';

  if (idx === -1) {
    // complete
    progress.completedSteps.push(stepId);
    action = 'completed';

    const step = findStepInRoadmap(roadmap, stepId);
    const skillRaw = step?.skillTag || step?.title;
    const skill = normalizeSkillTag(skillRaw);

    if (skill) {
      const user = await User.findById(userId);
      if (user) {
        const exists = (user.skills || []).some(
          (x) => normalizeSkillTag(x).toLowerCase() === skill.toLowerCase()
        );
        if (!exists) {
          user.skills.push(skill);
          await user.save();
        }
      }
    }
  } else {
    // uncomplete
    progress.completedSteps.splice(idx, 1);
    action = 'uncompleted';
  }

  const percent = await calculateProgressPercentage(userId);
  progress.completionPercent = percent;
  await progress.save();

  return {
    message: `Step ${action} successfully`,
    action,
    progress: {
      completionPercent: percent,
      completedSteps: progress.completedSteps,
    },
  };
};

// keep your old API name too (backward compatible)
const completeStep = async (userId, stepId) => {
  const res = await toggleStep(userId, stepId);
  return res;
};

const calculateProgressPercentage = async (userId) => {
  const assessment = await UserAssessmentResult.findOne({ userId });
  if (!assessment || !assessment.chosenCareer) return 0;

  const progress = await UserRoadmapProgress
    .findOne({ userId, careerId: assessment.chosenCareer })
    .populate('roadmapId');

  if (!progress || !progress.roadmapId) return 0;

  let totalSteps = 0;
  progress.roadmapId.phases.forEach((phase) => {
    totalSteps += phase.steps.length;
  });

  const completed = progress.completedSteps.length;

  if (totalSteps === 0) return 0;

  return Math.round((completed / totalSteps) * 100);
};

// ✅ Step 12: Generate resources for steps that have none
const generateResourcesForCurrentRoadmap = async (userId) => {
  const { career, roadmap } = await getChosenCareerAndRoadmap(userId);

  let updatedSteps = 0;

  for (const phase of roadmap.phases) {
    for (const step of phase.steps) {
      const hasResources = Array.isArray(step.resources) && step.resources.length > 0;
      if (hasResources) continue;

      const stepTitle = step.title || '';
      const skillTag = step.skillTag || '';

      step.resources = defaultResourcesForStep(stepTitle, skillTag, career.name);
      updatedSteps++;
    }
  }

  await roadmap.save();

  return {
    message: `Resources generated for ${updatedSteps} steps`,
    updatedSteps,
  };
};

module.exports = {
  getUserRoadmap,
  getUserRoadmapWithProgress,
  initializeProgress,
  toggleStep,
  completeStep,
  calculateProgressPercentage,
  generateResourcesForCurrentRoadmap,
};