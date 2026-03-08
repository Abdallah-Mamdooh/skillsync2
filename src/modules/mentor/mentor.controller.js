const asyncHandler = require('../../middlewares/async.middleware');
const mentorService = require('./mentor.service');

const createMentorProfile = asyncHandler(async (req, res) => {
  const data = await mentorService.createMentorProfile(req.user._id, req.body);

  res.status(201).json({
    success: true,
    data,
  });
});

const updateMentorProfile = asyncHandler(async (req, res) => {
  const data = await mentorService.updateMentorProfile(req.user._id, req.body);

  res.status(200).json({
    success: true,
    data,
  });
});

const getMyMentorProfile = asyncHandler(async (req, res) => {
  const data = await mentorService.getMyMentorProfile(req.user._id);

  res.status(200).json({
    success: true,
    data,
  });
});

const getPublicMentors = asyncHandler(async (req, res) => {
  const data = await mentorService.getPublicMentors();

  res.status(200).json({
    success: true,
    data,
  });
});

const getMentorById = asyncHandler(async (req, res) => {
  const data = await mentorService.getMentorById(req.params.mentorId);

  res.status(200).json({
    success: true,
    data,
  });
});

module.exports = {
  createMentorProfile,
  updateMentorProfile,
  getMyMentorProfile,
  getPublicMentors,
  getMentorById,
};