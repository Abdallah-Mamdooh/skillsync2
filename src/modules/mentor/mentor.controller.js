const asyncHandler = require('../../middlewares/async.middleware');
const mentorService = require('./mentor.service');
const availabilityService = require('./mentorAvailability.service');

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

const getMentorAvailableSlots = asyncHandler(async (req, res) => {
  const { date, durationMinutes } = req.query;

  const data = await availabilityService.getAvailableSlots(
    req.params.mentorId,
    date,
    Number(durationMinutes)
  );

  res.status(200).json({
    success: true,
    data,
  });
});

const updateMentorAvailabilityStatus = asyncHandler(async (req, res) => {
  const data = await mentorService.updateMentorAvailabilityStatus(
    req.user._id,
    req.body
  );

  res.status(200).json({
    success: true,
    data,
  });
});

const expireFinishedBreaks = asyncHandler(async (req, res) => {
  const data = await mentorService.expireFinishedBreaks();

  res.status(200).json({
    success: true,
    data,
  });
});

const submitScheduleChangeRequest = asyncHandler(async (req, res) => {
  const data =
    await mentorService.submitScheduleChangeRequest(
      req.user._id,
      req.body
    );

  res.status(201).json({
    success: true,
    data,
  });
});

const applyApprovedScheduleChanges = asyncHandler(async (req, res) => {
  const data = await mentorService.applyApprovedScheduleChanges();

  res.status(200).json({
    success: true,
    data,
  });
});

const createAvailabilityException = asyncHandler(async (req, res) => {
  const data = await mentorService.createAvailabilityException(
    req.user._id,
    req.body
  );

  res.status(201).json({
    success: true,
    data,
  });
});

const removeAvailabilityException = asyncHandler(async (req, res) => {
  const data = await mentorService.removeAvailabilityException(
    req.user._id,
    req.params.exceptionId
  );

  res.status(200).json({
    success: true,
    data,
  });
});

const getMyAvailabilityExceptions = asyncHandler(async (req, res) => {
  const data = await mentorService.getMyAvailabilityExceptions(req.user._id);

  res.status(200).json({
    success: true,
    data,
  });
});

const getMyScheduleChangeRequests = asyncHandler(async (req, res) => {
  const data = await mentorService.getMyScheduleChangeRequests(req.user._id);

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
  getMentorAvailableSlots,
  updateMentorAvailabilityStatus,
  expireFinishedBreaks,
  submitScheduleChangeRequest,
  applyApprovedScheduleChanges,
  createAvailabilityException,
  removeAvailabilityException,
  getMyAvailabilityExceptions,
  getMyScheduleChangeRequests,
};