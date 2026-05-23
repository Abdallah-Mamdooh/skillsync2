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
  const data = await adminService.updateUserStatus(
    req.params.userId,
    req.body,
    req.user
  );
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
  const data = await adminService.verifyMentorProfile(
    req.params.mentorProfileId,
    req.user
  );
  res.status(200).json({ success: true, data });
});

const unverifyMentorProfile = asyncHandler(async (req, res) => {
  const data = await adminService.unverifyMentorProfile(
    req.params.mentorProfileId,
    req.user
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

const getAnalyticsOverview = asyncHandler(async (req, res) => {
  const data = await adminService.getAnalyticsOverview();
  res.status(200).json({ success: true, data });
});

const getUserGrowthAnalytics = asyncHandler(async (req, res) => {
  const data = await adminService.getUserGrowthAnalytics(req.query.days);
  res.status(200).json({ success: true, data });
});

const getMentorGrowthAnalytics = asyncHandler(async (req, res) => {
  const data = await adminService.getMentorGrowthAnalytics(req.query.days);
  res.status(200).json({ success: true, data });
});

const getSessionTrendAnalytics = asyncHandler(async (req, res) => {
  const data = await adminService.getSessionTrendAnalytics(req.query.days);
  res.status(200).json({ success: true, data });
});

const getTopCareersAnalytics = asyncHandler(async (req, res) => {
  const data = await adminService.getTopCareersAnalytics(req.query.limit);
  res.status(200).json({ success: true, data });
});

const getTopSkillsAnalytics = asyncHandler(async (req, res) => {
  const data = await adminService.getTopSkillsAnalytics(req.query.limit);
  res.status(200).json({ success: true, data });
});

const getCareers = asyncHandler(async (req, res) => {
  const data = await adminService.getCareers(req.query);
  res.status(200).json({ success: true, data });
});

const getCareerDetails = asyncHandler(async (req, res) => {
  const data = await adminService.getCareerDetails(req.params.careerId);
  res.status(200).json({ success: true, data });
});

const createCareer = asyncHandler(async (req, res) => {
  const data = await adminService.createCareer(req.body);
  res.status(201).json({ success: true, data });
});

const updateCareer = asyncHandler(async (req, res) => {
  const data = await adminService.updateCareer(req.params.careerId, req.body);
  res.status(200).json({ success: true, data });
});

const deleteCareer = asyncHandler(async (req, res) => {
  const data = await adminService.deleteCareer(req.params.careerId);
  res.status(200).json({ success: true, data });
});

const getCareerRoadmap = asyncHandler(async (req, res) => {
  const data = await adminService.getCareerRoadmap(req.params.careerId);
  res.status(200).json({ success: true, data });
});

const updateRoadmapStepResources = asyncHandler(async (req, res) => {
  const data = await adminService.updateRoadmapStepResources(
    req.params.careerId,
    req.params.stepId,
    req.body
  );
  res.status(200).json({ success: true, data });
});

const getPendingMentorCancellations = asyncHandler(async (req, res) => {
  const data = await adminService.getPendingMentorCancellations();
  res.status(200).json({ success: true, data });
});

const reviewMentorCancellation = asyncHandler(async (req, res) => {
  const data = await adminService.reviewMentorCancellation(
    req.params.sessionId,
    req.body,
    req.user
  );

  res.status(200).json({ success: true, data });
});
const getMentorActivityLogs = asyncHandler(async (req, res) => {
  const data = await adminService.getMentorActivityLogs(req.query);
  res.status(200).json({ success: true, data });
});

const getPendingScheduleChangeRequests = asyncHandler(async (req, res) => {
  const data = await adminService.getPendingScheduleChangeRequests();
  res.status(200).json({ success: true, data });
});

const approveScheduleChangeRequest = asyncHandler(async (req, res) => {
  const data = await adminService.approveScheduleChangeRequest(
    req.params.requestId,
    req.user,
    req.body
  );

  res.status(200).json({ success: true, data });
});

const rejectScheduleChangeRequest = asyncHandler(async (req, res) => {
  const data = await adminService.rejectScheduleChangeRequest(
    req.params.requestId,
    req.user,
    req.body
  );

  res.status(200).json({ success: true, data });
});

const getMentorAvailabilityExceptions = asyncHandler(async (req, res) => {
  const data = await adminService.getMentorAvailabilityExceptions(req.query);
  res.status(200).json({ success: true, data });
});

const getScheduleChangeRequests = asyncHandler(async (req, res) => {
  const data = await adminService.getScheduleChangeRequests(req.query);
  res.status(200).json({ success: true, data });
});

const getMentorBehaviorAnalytics = asyncHandler(async (req, res) => {
  const data = await adminService.getMentorBehaviorAnalytics();

  res.status(200).json({
    success: true,
    data,
  });
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
  getAnalyticsOverview,
  getUserGrowthAnalytics,
  getMentorGrowthAnalytics,
  getSessionTrendAnalytics,
  getTopCareersAnalytics,
  getTopSkillsAnalytics,
  getCareers,
  getCareerDetails,
  createCareer,
  updateCareer,
  deleteCareer,
  getCareerRoadmap,
  updateRoadmapStepResources,
  getPendingMentorCancellations,
  reviewMentorCancellation,
  getMentorActivityLogs,
  getPendingScheduleChangeRequests,
  approveScheduleChangeRequest,
  rejectScheduleChangeRequest,
  getMentorAvailabilityExceptions,
  getScheduleChangeRequests,
  getMentorBehaviorAnalytics,
};