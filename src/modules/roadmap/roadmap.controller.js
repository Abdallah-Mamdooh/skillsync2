const asyncHandler = require('../../middlewares/async.middleware');
const roadmapService = require('./roadmap.service');

const getMyRoadmap = asyncHandler(async (req, res) => {
  const data = await roadmapService.getUserRoadmapWithProgress(req.user._id);

  res.status(200).json({
    success: true,
    data,
  });
});

// ✅ Toggle = mark done / undo
const toggleStep = asyncHandler(async (req, res) => {
  const { stepId } = req.body;

  const response = await roadmapService.toggleStep(req.user._id, stepId);

  res.status(200).json({
    success: true,
    ...response,
  });
});

const getProgress = asyncHandler(async (req, res) => {
  const percentage = await roadmapService.calculateProgressPercentage(req.user._id);

  res.status(200).json({
    success: true,
    progress: percentage,
  });
});

// ✅ Generate learning resources for current roadmap
const generateResources = asyncHandler(async (req, res) => {
  const result = await roadmapService.generateResourcesForCurrentRoadmap(req.user._id);

  res.status(200).json({
    success: true,
    ...result,
  });
});

module.exports = {
  getMyRoadmap,
  toggleStep,
  getProgress,
  generateResources,
};