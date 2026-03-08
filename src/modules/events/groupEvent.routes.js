const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const controller = require('./groupEvent.controller');

// public
router.get('/public', controller.getPublicEvents);
router.get('/public/:eventId', controller.getEventById);

// organizer
router.post('/', authMiddleware, controller.createEvent);
router.put('/:eventId', authMiddleware, controller.updateEvent);
router.post('/:eventId/publish', authMiddleware, controller.publishEvent);
router.post('/registrations/:registrationId/capture', authMiddleware, controller.captureEventRegistrationPayment);
router.post('/registrations/:registrationId/release', authMiddleware, controller.releaseEventRegistrationPayment);
router.post('/registrations/:registrationId/attend', authMiddleware, controller.markRegistrationAttended);
router.post('/:eventId/complete', authMiddleware, controller.completeEvent);


// attendee
router.post('/:eventId/register', authMiddleware, controller.registerForEvent);
router.get('/me/registrations', authMiddleware, controller.getMyEventRegistrations);



module.exports = router;