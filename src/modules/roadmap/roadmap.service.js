const Roadmap = require('./roadmap.model');
const UserAssessmentResult = require('../assessment/userAssessmentResult.model');

const getUserRoadmap = async (userId) => {

  // 1️⃣ Get user assessment result
  const assessment = await UserAssessmentResult
    .findOne({ userId })
    .populate('chosenCareer');

  if (!assessment) {
    throw new Error('User has not completed assessment yet');
  }

  if (!assessment.chosenCareer) {
    throw new Error('User has not selected a career yet');
  }

  // 2️⃣ Find roadmap for selected career
  const roadmap = await Roadmap.findOne({
    careerId: assessment.chosenCareer._id
  });

  if (!roadmap) {
    throw new Error('Roadmap not found for selected career');
  }

  // 3️⃣ Sort phases and steps properly
  roadmap.phases.sort((a, b) => a.order - b.order);

  roadmap.phases.forEach(phase => {
    phase.steps.sort((a, b) => a.order - b.order);
  });

  return roadmap;
};

module.exports = {
  getUserRoadmap
};