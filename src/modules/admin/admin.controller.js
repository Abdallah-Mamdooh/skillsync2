const asyncHandler = require('../../middlewares/async.middleware');
const adminService = require('./admin.service');

const getDashboardSummary = asyncHandler(async (req, res) => {
  const data = await adminService.getDashboardSummary();

  res.status(200).json({
    success: true,
    data,
  });
});

const getUsers = asyncHandler(async (req, res) => {
  const data = await adminService.getUsers(req.query);

  res.status(200).json({
    success: true,
    data,
  });
});

const updateUserStatus = asyncHandler(async (req, res) => {
  const { userId } = req.params;

  const data = await adminService.updateUserStatus(userId, {
    isActive: req.body.isActive,
  });

  res.status(200).json({
    success: true,
    data,
  });
});

const getAllMentorProfiles = asyncHandler(async (req, res) => {
  const data = await adminService.getAllMentorProfiles();
  res.status(200).json({ success: true, data });
});

const getPendingMentorProfiles = asyncHandler(async (req, res) => {
  const data = await adminService.getPendingMentorProfiles();
  res.status(200).json({ success: true, data });
});

const verifyMentorProfile = asyncHandler(async (req, res) => {
  const data = await adminService.verifyMentorProfile(req.params.mentorProfileId);
  res.status(200).json({ success: true, data });
});

const unverifyMentorProfile = asyncHandler(async (req, res) => {
  const data = await adminService.unverifyMentorProfile(req.params.mentorProfileId);
  res.status(200).json({ success: true, data });
});

const getOpenComplaints = asyncHandler(async (req, res) => {
  const data = await adminService.getOpenComplaints();
  res.status(200).json({ success: true, data });
});

const updateComplaintStatus = asyncHandler(async (req, res) => {
  const data = await adminService.updateComplaintStatus(
    req.params.feedbackId,
    req.body.complaintStatus
  );

  res.status(200).json({ success: true, data });
});

module.exports = {
  getDashboardSummary,
  getUsers,
  updateUserStatus,
  getAllMentorProfiles,
  getPendingMentorProfiles,
  verifyMentorProfile,
  unverifyMentorProfile,
  getOpenComplaints,
  updateComplaintStatus,
};