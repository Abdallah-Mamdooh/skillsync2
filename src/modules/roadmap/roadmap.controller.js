const asyncHandler = require('../../middlewares/async.middleware');
const roadmapService = require('./roadmap.service');

const getMyRoadmap = asyncHandler(async (req, res) => {
  const data = await roadmapService.getUserRoadmapWithProgress(req.user._id);

  res.status(200).json({
    success: true,
    data,
  });
});

const toggleStep = asyncHandler(async (req, res) => {
  const { stepId } = req.body;

  if (!stepId) {
    return res.status(400).json({
      success: false,
      message: 'stepId is required',
    });
  }

  const response = await roadmapService.toggleStep(req.user._id, stepId);

  res.status(200).json({
    success: true,
    ...response,
  });
});

const getProgress = asyncHandler(async (req, res) => {
  const data = await roadmapService.getProgressSummary(req.user._id);

  res.status(200).json({
    success: true,
    progress: data.completionPercent,
    data,
  });
});

const generateResources = asyncHandler(async (req, res) => {
  const result = await roadmapService.generateResourcesForCurrentRoadmap(
    req.user._id
  );

  res.status(200).json({
    success: true,
    ...result,
  });
});

const getRecentCompletions = asyncHandler(async (req, res) => {
  const rawLimit = Number(req.query.limit) || 10;
  const limit = Math.max(1, Math.min(rawLimit, 50));

  const data = await roadmapService.getRecentCompletions(req.user._id, limit);

  res.status(200).json({
    success: true,
    data,
  });
});

module.exports = {
  getMyRoadmap,
  toggleStep,
  getProgress,
  generateResources,
  getRecentCompletions,
};