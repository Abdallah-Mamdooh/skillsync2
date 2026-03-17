const asyncHandler = require('../../middlewares/async.middleware');
const adminService = require('./admin.service');

const getDashboardSummary = asyncHandler(async (req, res) => {
  const data = await adminService.getDashboardSummary();
  res.status(200).json({ success: true, data });
});

const getUsers = asyncHandler(async (req, res) => {
  const data = await adminService.getUsers(req.query);
  res.status(200).json({ success: true, data });
});

const getUserDetails = asyncHandler(async (req, res) => {
  const data = await adminService.getUserDetails(req.params.userId);
  res.status(200).json({ success: true, data });
});

const updateUserStatus = asyncHandler(async (req, res) => {
  const data = await adminService.updateUserStatus(req.params.userId, req.body);
  res.status(200).json({ success: true, data });
});

const getAllMentorProfiles = asyncHandler(async (req, res) => {
  const data = await adminService.getAllMentorProfiles();
  res.status(200).json({ success: true, data });
});

const getPendingMentorProfiles = asyncHandler(async (req, res) => {
  const data = await adminService.getPendingMentorProfiles();
  res.status(200).json({ success: true, data });
});

const getMentors = asyncHandler(async (req, res) => {
  const data = await adminService.getMentors(req.query);
  res.status(200).json({ success: true, data });
});

const getMentorDetails = asyncHandler(async (req, res) => {
  const data = await adminService.getMentorDetails(req.params.mentorProfileId);
  res.status(200).json({ success: true, data });
});

const updateMentorStatus = asyncHandler(async (req, res) => {
  const data = await adminService.updateMentorStatus(
    req.params.mentorProfileId,
    req.body
  );
  res.status(200).json({ success: true, data });
});

const verifyMentorProfile = asyncHandler(async (req, res) => {
  const data = await adminService.verifyMentorProfile(req.params.mentorProfileId);
  res.status(200).json({ success: true, data });
});

const unverifyMentorProfile = asyncHandler(async (req, res) => {
  const data = await adminService.unverifyMentorProfile(
    req.params.mentorProfileId
  );
  res.status(200).json({ success: true, data });
});

const getOpenComplaints = asyncHandler(async (req, res) => {
  const data = await adminService.getOpenComplaints();
  res.status(200).json({ success: true, data });
});

const updateComplaintStatus = asyncHandler(async (req, res) => {
  const data = await adminService.updateComplaintStatus(
    req.params.feedbackId,
    req.body
  );
  res.status(200).json({ success: true, data });
});

const getTransactions = asyncHandler(async (req, res) => {
  const data = await adminService.getTransactions(req.query);
  res.status(200).json({ success: true, data });
});

module.exports = {
  getDashboardSummary,
  getUsers,
  getUserDetails,
  updateUserStatus,
  getAllMentorProfiles,
  getPendingMentorProfiles,
  getMentors,
  getMentorDetails,
  updateMentorStatus,
  verifyMentorProfile,
  unverifyMentorProfile,
  getOpenComplaints,
  updateComplaintStatus,
  getTransactions,
};