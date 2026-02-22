const asyncHandler = require('../../middlewares/async.middleware');
const roadmapService = require('./roadmap.service');

const getUserRoadmap = asyncHandler(async (req, res) => {
  const data = await roadmapService.getUserRoadmap(req.user._id);
  res.json({ success: true, data });
});

const completeStep = asyncHandler(async (req, res) => {
  const response = await roadmapService.completeStep(
    req.user._id,
    req.body.phaseIndex,
    req.body.stepIndex
  );

  res.json({ success: true, ...response });
});

const getProgressPercentage = asyncHandler(async (req, res) => {
  const percentage = await roadmapService.calculateProgressPercentage(
    req.user._id
  );

  res.json({ success: true, progress: percentage });
});

module.exports = {
  getUserRoadmap,
  completeStep,
  getProgressPercentage
};
