const asyncHandler = require('../../middlewares/async.middleware');
const settingsService = require('./settings.service');

const getMySettings = asyncHandler(async (req, res) => {
  const data = await settingsService.getMySettings(req.user._id);

  res.status(200).json({
    success: true,
    data,
  });
});

const updateMySettings = asyncHandler(async (req, res) => {
  const data = await settingsService.updateMySettings(req.user._id, req.body);

  res.status(200).json({
    success: true,
    data,
  });
});

const getAppSettings = asyncHandler(async (req, res) => {
  const data = await settingsService.getAppSettings();

  res.status(200).json({
    success: true,
    data,
  });
});

const updateAppSettings = asyncHandler(async (req, res) => {
  const data = await settingsService.updateAppSettings(req.body);

  res.status(200).json({
    success: true,
    data,
  });
});

module.exports = {
  getMySettings,
  updateMySettings,
  getAppSettings,
  updateAppSettings,
};