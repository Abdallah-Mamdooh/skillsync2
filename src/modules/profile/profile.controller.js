const asyncHandler = require('../../middlewares/async.middleware');
const profileService = require('./profile.service');

const getProfile = asyncHandler(async (req, res) => {
  const response = await profileService.getProfile(req.user._id);
  res.status(200).json(response);
});

const updateProfile = asyncHandler(async (req, res) => {
  const response = await profileService.updateProfile(
    req.user._id,
    req.body
  );
  res.status(200).json(response);
});

module.exports = {
  getProfile,
  updateProfile
};
