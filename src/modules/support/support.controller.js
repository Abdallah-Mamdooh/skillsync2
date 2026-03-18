const asyncHandler = require('../../middlewares/async.middleware');
const supportService = require('./support.service');

const getWhatsappSupportConfig = asyncHandler(async (req, res) => {
  const data = await supportService.getWhatsappSupportConfig();

  res.status(200).json({
    success: true,
    data,
  });
});

const getWhatsappSupportConfigAdmin = asyncHandler(async (req, res) => {
  const data = await supportService.getWhatsappSupportConfigAdmin();

  res.status(200).json({
    success: true,
    data,
  });
});

const updateWhatsappSupportConfig = asyncHandler(async (req, res) => {
  const data = await supportService.updateWhatsappSupportConfig(req.body);

  res.status(200).json({
    success: true,
    data,
  });
});

const buildWhatsappMessagePreview = asyncHandler(async (req, res) => {
  const data = await supportService.buildWhatsappMessagePreview(req.body);

  res.status(200).json({
    success: true,
    data,
  });
});

module.exports = {
  getWhatsappSupportConfig,
  getWhatsappSupportConfigAdmin,
  updateWhatsappSupportConfig,
  buildWhatsappMessagePreview,
};