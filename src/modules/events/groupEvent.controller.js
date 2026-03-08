const asyncHandler = require('../../middlewares/async.middleware');
const eventService = require('./groupEvent.service');

const createEvent = asyncHandler(async (req, res) => {
  const data = await eventService.createEvent(req.user._id, req.body);
  res.status(201).json({ success: true, data });
});

const updateEvent = asyncHandler(async (req, res) => {
  const data = await eventService.updateEvent(req.user._id, req.params.eventId, req.body);
  res.status(200).json({ success: true, data });
});

const publishEvent = asyncHandler(async (req, res) => {
  const data = await eventService.publishEvent(req.user._id, req.params.eventId);
  res.status(200).json({ success: true, data });
});

const getPublicEvents = asyncHandler(async (req, res) => {
  const data = await eventService.getPublicEvents();
  res.status(200).json({ success: true, data });
});

const getEventById = asyncHandler(async (req, res) => {
  const data = await eventService.getEventById(req.params.eventId);
  res.status(200).json({ success: true, data });
});

const registerForEvent = asyncHandler(async (req, res) => {
  const data = await eventService.registerForEvent(req.user._id, req.params.eventId);
  res.status(201).json({ success: true, data });
});

const getMyEventRegistrations = asyncHandler(async (req, res) => {
  const data = await eventService.getMyEventRegistrations(req.user._id);
  res.status(200).json({ success: true, data });
});

const captureEventRegistrationPayment = asyncHandler(async (req, res) => {
  const data = await eventService.captureEventRegistrationPayment(
    req.user._id,
    req.params.registrationId
  );

  res.status(200).json({ success: true, data });
});

const releaseEventRegistrationPayment = asyncHandler(async (req, res) => {
  const data = await eventService.releaseEventRegistrationPayment(
    req.user._id,
    req.params.registrationId
  );

  res.status(200).json({ success: true, data });
});

module.exports = {
  createEvent,
  updateEvent,
  publishEvent,
  getPublicEvents,
  getEventById,
  registerForEvent,
  getMyEventRegistrations,
  captureEventRegistrationPayment,
  releaseEventRegistrationPayment,
};