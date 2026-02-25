const Roadmap = require('./roadmap.model');
const UserRoadmapProgress = require('./userRoadmapProgress.model');
const UserAssessmentResult = require('../assessment/userAssessmentResult.model');

const getUserRoadmap = async (userId) => {

  const assessment = await UserAssessmentResult
    .findOne({ userId })
    .populate('chosenCareer');

  if (!assessment || !assessment.chosenCareer) {
    throw new Error('Assessment not completed or career not selected');
  }

  const roadmap = await Roadmap.findOne({
    careerId: assessment.chosenCareer._id
  });

  if (!roadmap) {
    throw new Error('Roadmap not found');
  }

  // Sort phases
  roadmap.phases.sort((a, b) => a.order - b.order);

  // Sort steps inside each phase
  roadmap.phases.forEach(phase => {
    phase.steps.sort((a, b) => a.order - b.order);
  });

  return roadmap;
};


const initializeProgress = async (userId) => {

  const assessment = await UserAssessmentResult.findOne({ userId });

  if (!assessment || !assessment.chosenCareer) {
    throw new Error('Career must be selected first');
  }

  const roadmap = await Roadmap.findOne({
    careerId: assessment.chosenCareer
  });

  if (!roadmap) {
    throw new Error('Roadmap not found');
  }

  // Delete old progress if exists
  await UserRoadmapProgress.deleteMany({ userId });

  const progress = await UserRoadmapProgress.create({
    userId,
    roadmapId: roadmap._id,
    completedSteps: []
  });

  return progress;
};


const completeStep = async (userId, stepId) => {

  const progress = await UserRoadmapProgress.findOne({ userId });

  if (!progress) {
    throw new Error('Roadmap not initialized');
  }

  const alreadyCompleted = progress.completedSteps.includes(stepId);

  if (!alreadyCompleted) {
    progress.completedSteps.push(stepId);
    await progress.save();
  }

  return { message: 'Step completed successfully' };
};


const calculateProgressPercentage = async (userId) => {

  const progress = await UserRoadmapProgress
    .findOne({ userId })
    .populate('roadmapId');

  if (!progress) return 0;

  let totalSteps = 0;

  progress.roadmapId.phases.forEach(phase => {
    totalSteps += phase.steps.length;
  });

  const completed = progress.completedSteps.length;

  if (totalSteps === 0) return 0;

  return Math.round((completed / totalSteps) * 100);
};

module.exports = {
  getUserRoadmap,
  initializeProgress,
  completeStep,
  calculateProgressPercentage
};