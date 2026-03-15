const asyncHandler = require('../../middlewares/async.middleware');
const dashboardService = require('./dashboard.service');

const getUserDashboard = asyncHandler(async (req, res) => {
  const data = await dashboardService.getUserDashboardSummary(req.user._id);

  res.status(200).json({
    success: true,
    data,
  });
});

const getMentorDashboard = asyncHandler(async (req, res) => {
  const data = await dashboardService.getMentorDashboardSummary(req.user._id);

  res.status(200).json({
    success: true,
    data,
  });
});

module.exports = {
  getUserDashboard,
  getMentorDashboard,
};