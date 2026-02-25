const asyncHandler = require('../../middlewares/async.middleware');
const roadmapService = require('./roadmap.service');

const getMyRoadmap = asyncHandler(async (req, res) => {

  const roadmap = await roadmapService.getUserRoadmap(req.user._id);

  res.status(200).json({
    success: true,
    data: roadmap
  });
});

const completeStep = asyncHandler(async (req, res) => {

  const { stepId } = req.body;

  const response = await roadmapService.completeStep(
    req.user._id,
    stepId
  );

  res.status(200).json({
    success: true,
    ...response
  });
});

const getProgress = asyncHandler(async (req, res) => {

  const percentage = await roadmapService.calculateProgressPercentage(
    req.user._id
  );

  res.status(200).json({
    success: true,
    progress: percentage
  });
});

module.exports = {
  getMyRoadmap,
  completeStep,
  getProgress
};