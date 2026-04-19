const path = require('path');
const asyncHandler = require('../../middlewares/async.middleware');
const cvAnalysisService = require('./cvAnalysis.service');

function buildFileUrl(req, filePath) {
  const baseUrl = `${req.protocol}://${req.get('host')}`;
  return `${baseUrl}/${filePath.replace(/\\/g, '/')}`;
}

const analyzeMyCv = asyncHandler(async (req, res) => {
  if (!req.file) {
    return res.status(400).json({
      success: false,
      message: 'CV file is required',
    });
  }

  const filePath = path.join('uploads', 'cvs', req.file.filename);
  const cvUrl = buildFileUrl(req, filePath);

  const data = await cvAnalysisService.analyzeCv({
    userId: req.user._id,
    file: req.file,
    cvUrl,
    detectedFieldOverride: req.body.field || '',
    jobDescription: req.body.jobDescription || '',
  });

  res.status(201).json({
    success: true,
    data,
  });
});

const getLatestMyCvAnalysis = asyncHandler(async (req, res) => {
  const data = await cvAnalysisService.getLatestAnalysis(req.user._id);

  res.status(200).json({
    success: true,
    data,
  });
});

const getMyCvAnalysisHistory = asyncHandler(async (req, res) => {
  const data = await cvAnalysisService.getMyAnalysisHistory(req.user._id);

  res.status(200).json({
    success: true,
    data,
  });
});

module.exports = {
  analyzeMyCv,
  getLatestMyCvAnalysis,
  getMyCvAnalysisHistory,
};