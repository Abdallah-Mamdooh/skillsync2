const GroupEvent = require('./groupEvent.model');
const EventRegistration = require('./eventRegistration.model');
const MentorProfile = require('../mentor/mentorProfile.model');
const paymentService = require('../payment/payment.service');
const User = require('../auth/user.model');
const Transaction = require('../payment/transaction.model');
const notificationService = require('../notification/notification.service');

function ensureFutureDate(dateValue) {
  const date = new Date(dateValue);
  if (Number.isNaN(date.getTime())) {
    throw new Error('Invalid event date');
  }
  if (date <= new Date()) {
    throw new Error('Event must be scheduled in the future');
  }
  return date;
}

function canRegisterForEvent(event) {
  if (!event) throw new Error('Event not found');
  if (event.status !== 'published') {
    throw new Error('Only published events can be registered');
  }
  if (new Date(event.scheduledAt) <= new Date()) {
    throw new Error('Registration is closed because the event time has passed');
  }
  if (Number(event.registeredCount || 0) >= Number(event.capacity || 0)) {
    throw new Error('Event is full');
  }
}

async function incrementEventSeatCount(eventId) {
  const updated = await GroupEvent.findOneAndUpdate(
    {
      _id: eventId,
      $expr: { $lt: ['$registeredCount', '$capacity'] },
    },
    { $inc: { registeredCount: 1 } },
    { new: true }
  );

  if (!updated) {
    throw new Error('Event is full');
  }

  return updated;
}

async function decrementEventSeatCount(eventId) {
  await GroupEvent.findByIdAndUpdate(
    eventId,
    [
      {
        $set: {
          registeredCount: {
            $cond: [
              { $gt: ['$registeredCount', 0] },
              { $subtract: ['$registeredCount', 1] },
              0,
            ],
          },
        },
      },
    ],
    { new: true }
  );
}

async function normalizeSpeakers(speakers = []) {
  const normalizedSpeakers = [];

  for (const s of speakers) {
    const mentorProfile = await MentorProfile.findById(s.mentorProfileId).populate(
      'userId',
      '_id'
    );

    if (!mentorProfile) {
      throw new Error(`Speaker mentor profile not found: ${s.mentorProfileId}`);
    }

    normalizedSpeakers.push({
      mentorProfileId: mentorProfile._id,
      mentorUserId: mentorProfile.userId._id,
      roleLabel: s.roleLabel || 'Speaker',
    });
  }

  return normalizedSpeakers;
}

const createEvent = async (organizerUserId, payload) => {
  const speakers = Array.isArray(payload.speakers) ? payload.speakers : [];
  const normalizedSpeakers = await normalizeSpeakers(speakers);

  const event = await GroupEvent.create({
    organizerUserId,
    title: payload.title,
    description: payload.description || '',
    topic: payload.topic || '',
    speakers: normalizedSpeakers,
    fee: payload.fee || 0,
    currency: payload.currency || 'EGP',
    capacity: payload.capacity || 100,
    meetingProvider: payload.meetingProvider || 'google_meet',
    meetingLink: payload.meetingLink,
    scheduledAt: ensureFutureDate(payload.scheduledAt),
    durationMinutes: payload.durationMinutes || 60,
    status: payload.status || 'draft',
    coverImageUrl: payload.coverImageUrl || '',
  });

  return event;
};

const updateEvent = async (organizerUserId, eventId, payload) => {
  const event = await GroupEvent.findById(eventId);
  if (!event) {
    throw new Error('Event not found');
  }

  if (String(event.organizerUserId) !== String(organizerUserId)) {
    throw new Error('You are not allowed to update this event');
  }

  if (['completed', 'cancelled'].includes(event.status)) {
    throw new Error('Completed or cancelled events cannot be updated');
  }

  const updatableFields = [
    'title',
    'description',
    'topic',
    'fee',
    'currency',
    'capacity',
    'meetingProvider',
    'meetingLink',
    'durationMinutes',
    'status',
    'coverImageUrl',
  ];

  for (const field of updatableFields) {
    if (payload[field] !== undefined) {
      event[field] = payload[field];
    }
  }

  if (payload.scheduledAt !== undefined) {
    event.scheduledAt = ensureFutureDate(payload.scheduledAt);
  }

  if (Array.isArray(payload.speakers)) {
    event.speakers = await normalizeSpeakers(payload.speakers);
  }

  if (Number(event.capacity || 0) < Number(event.registeredCount || 0)) {
    throw new Error('Capacity cannot be reduced below current registeredCount');
  }

  await event.save();
  return event;
};

const publishEvent = async (organizerUserId, eventId) => {
  const event = await GroupEvent.findById(eventId);
  if (!event) {
    throw new Error('Event not found');
  }

  if (String(event.organizerUserId) !== String(organizerUserId)) {
    throw new Error('You are not allowed to publish this event');
  }

  if (!event.meetingLink) {
    throw new Error('Event meetingLink is required before publishing');
  }

  ensureFutureDate(event.scheduledAt);

  event.status = 'published';
  await event.save();

  for (const speaker of event.speakers || []) {
    await notificationService.createNotification({
      userId: speaker.mentorUserId,
      type: 'event_published',
      title: 'Event published',
      message: `You have been listed as a speaker in "${event.title}".`,
      data: {
        eventId: event._id,
        title: event.title,
        scheduledAt: event.scheduledAt,
      },
    });
  }

  return event;
};

const getPublicEvents = async () => {
  return GroupEvent.find({ status: 'published' })
    .sort({ scheduledAt: 1 })
    .populate('speakers.mentorUserId', 'fullName email');
};

const getEventById = async (eventId) => {
  const event = await GroupEvent.findById(eventId)
    .populate('organizerUserId', 'fullName email')
    .populate('speakers.mentorUserId', 'fullName email')
    .populate('speakers.mentorProfileId');

  if (!event) {
    throw new Error('Event not found');
  }

  return event;
};

const registerForEvent = async (userId, eventId) => {
  const event = await GroupEvent.findById(eventId);
  if (!event) {
    throw new Error('Event not found');
  }

  canRegisterForEvent(event);

  const existing = await EventRegistration.findOne({ eventId, userId });
  if (existing) {
    throw new Error('You are already registered for this event');
  }

  const defaultMethod = await paymentService.getDefaultPaymentMethod(userId);

  if (!defaultMethod && Number(event.fee || 0) > 0) {
    throw new Error('No default payment method found');
  }

  const updatedEvent = await incrementEventSeatCount(event._id);

  try {
    const registration = await EventRegistration.create({
      eventId,
      userId,
      registrationStatus: 'reserved',
      paymentStatus: Number(event.fee || 0) > 0 ? 'held' : 'captured',
      amountPaid: event.fee,
      currency: event.currency,
    });

    if (Number(event.fee || 0) > 0) {
      await paymentService.holdFunds({
        userId,
        sessionId: null,
        amount: event.fee,
        paymentMethodId: defaultMethod?._id || null,
        currency: event.currency,
        eventRegistrationId: registration._id,
      });
    }

    await notificationService.createNotification({
      userId,
      type: 'event_registered',
      title: 'Event registration confirmed',
      message: `You registered for "${updatedEvent.title}".`,
      data: {
        eventId: updatedEvent._id,
        registrationId: registration._id,
        amount: event.fee,
        currency: event.currency,
        paymentStatus: registration.paymentStatus,
      },
    });

    return registration;
  } catch (error) {
    await decrementEventSeatCount(event._id);
    throw error;
  }
};

const registerForEventWithFawry = async (userId, eventId, payload = {}) => {
  const event = await GroupEvent.findById(eventId);
  if (!event) {
    throw new Error('Event not found');
  }

  canRegisterForEvent(event);

  const existing = await EventRegistration.findOne({ eventId, userId });
  if (existing) {
    throw new Error('You are already registered for this event');
  }

  const updatedEvent = await incrementEventSeatCount(event._id);

  try {
    const registration = await EventRegistration.create({
      eventId,
      userId,
      registrationStatus: 'reserved',
      paymentStatus: 'unpaid',
      amountPaid: event.fee,
      currency: event.currency,
      attended: false,
      checkedInAt: null,
    });

    const user = await User.findById(userId).select(
      'fullName email phoneNumber'
    );
    if (!user) {
      throw new Error('User not found');
    }

    const checkout = await paymentService.createFawryCheckout({
      user: {
        _id: user._id,
        fullName: user.fullName,
        email: user.email,
        phoneNumber: user.phoneNumber,
      },
      amount: event.fee,
      purpose: 'hold',
      entityType: 'group_event',
      entityId: registration._id,
      description: `Event registration payment - ${event.title}`,
      paymentMethod: payload.paymentMethod || '',
      sessionId: null,
      eventRegistrationId: registration._id,
    });

    return {
      registrationId: registration._id,
      event: {
        id: updatedEvent._id,
        title: updatedEvent.title,
        fee: updatedEvent.fee,
        currency: updatedEvent.currency,
        scheduledAt: updatedEvent.scheduledAt,
      },
      paymentStatus: registration.paymentStatus,
      checkout,
    };
  } catch (error) {
    await decrementEventSeatCount(event._id);
    throw error;
  }
};

const getMyEventRegistrations = async (userId) => {
  return EventRegistration.find({ userId })
    .populate('eventId')
    .sort({ createdAt: -1 });
};

const captureEventRegistrationPayment = async (organizerUserId, registrationId) => {
  const registration = await EventRegistration.findById(registrationId).populate('eventId');
  if (!registration) {
    throw new Error('Registration not found');
  }

  const event = registration.eventId;
  if (!event) {
    throw new Error('Event not found');
  }

  if (String(event.organizerUserId) !== String(organizerUserId)) {
    throw new Error('You are not allowed to capture this event payment');
  }

  if (registration.paymentStatus !== 'held') {
    throw new Error('Only held registrations can be captured');
  }

  const externalPaidTx = await Transaction.findOne({
    eventRegistrationId: registration._id,
    provider: 'fawry',
    entityType: 'group_event',
    status: 'completed',
  }).sort({ createdAt: -1 });

  if (!externalPaidTx) {
    await paymentService.captureHeldFunds({
      userId: registration.userId,
      sessionId: null,
      amount: registration.amountPaid,
      currency: registration.currency,
      eventRegistrationId: registration._id,
    });
  }

  registration.paymentStatus = 'captured';
  registration.capturedAt = new Date();
  registration.registrationStatus = 'confirmed';
  await registration.save();

  await notificationService.createNotification({
    userId: registration.userId,
    type: 'event_payment_captured',
    title: 'Event payment captured',
    message: `Your registration payment for "${event.title}" was captured.`,
    data: {
      eventId: event._id,
      registrationId: registration._id,
      amount: registration.amountPaid,
      currency: registration.currency,
      paymentStatus: registration.paymentStatus,
    },
  });

  return registration;
};

const releaseEventRegistrationPayment = async (organizerUserId, registrationId) => {
  const registration = await EventRegistration.findById(registrationId).populate('eventId');
  if (!registration) {
    throw new Error('Registration not found');
  }

  const event = registration.eventId;
  if (!event) {
    throw new Error('Event not found');
  }

  if (String(event.organizerUserId) !== String(organizerUserId)) {
    throw new Error('You are not allowed to release this event payment');
  }

  if (registration.paymentStatus !== 'held') {
    throw new Error('Only held registrations can be released');
  }

  const externalPaidTx = await Transaction.findOne({
    eventRegistrationId: registration._id,
    provider: 'fawry',
    entityType: 'group_event',
    status: 'completed',
  }).sort({ createdAt: -1 });

  if (!externalPaidTx) {
    await paymentService.releaseHeldFunds({
      userId: registration.userId,
      sessionId: null,
      amount: registration.amountPaid,
      currency: registration.currency,
      eventRegistrationId: registration._id,
      reason: 'event_registration_release',
    });
  }

  registration.paymentStatus = 'released';
  registration.releasedAt = new Date();
  registration.registrationStatus = 'cancelled';
  await registration.save();

  await decrementEventSeatCount(event._id);

  await notificationService.createNotification({
    userId: registration.userId,
    type: 'event_payment_released',
    title: 'Event payment released',
    message: `Your held registration payment for "${event.title}" was released back.`,
    data: {
      eventId: event._id,
      registrationId: registration._id,
      amount: registration.amountPaid,
      currency: registration.currency,
      paymentStatus: registration.paymentStatus,
    },
  });

  return registration;
};

const markRegistrationAttended = async (organizerUserId, registrationId) => {
  const registration = await EventRegistration.findById(registrationId).populate('eventId');
  if (!registration) {
    throw new Error('Registration not found');
  }

  const event = registration.eventId;
  if (!event) {
    throw new Error('Event not found');
  }

  if (String(event.organizerUserId) !== String(organizerUserId)) {
    throw new Error('You are not allowed to mark attendance for this event');
  }

  if (event.status !== 'published') {
    throw new Error('Attendance can only be marked for published events');
  }

  registration.attended = true;
  registration.checkedInAt = new Date();

  if (registration.paymentStatus === 'held') {
    registration.paymentStatus = 'captured';
    registration.capturedAt = new Date();
    registration.registrationStatus = 'confirmed';
  }

  await registration.save();

  return registration;
};

const completeEvent = async (organizerUserId, eventId) => {
  const event = await GroupEvent.findById(eventId);
  if (!event) {
    throw new Error('Event not found');
  }

  if (String(event.organizerUserId) !== String(organizerUserId)) {
    throw new Error('You are not allowed to complete this event');
  }

  if (event.status !== 'published') {
    throw new Error('Only published events can be completed');
  }

  const registrations = await EventRegistration.find({ eventId: event._id });

  let capturedCount = 0;
  let releasedCount = 0;

  for (const registration of registrations) {
    if (registration.paymentStatus === 'held') {
      const externalPaidTx = await Transaction.findOne({
        eventRegistrationId: registration._id,
        provider: 'fawry',
        entityType: 'group_event',
        status: 'completed',
      }).sort({ createdAt: -1 });

      if (!externalPaidTx) {
        await paymentService.captureHeldFunds({
          userId: registration.userId,
          sessionId: null,
          amount: registration.amountPaid,
          currency: registration.currency,
          eventRegistrationId: registration._id,
        });
      }

      registration.paymentStatus = 'captured';
      registration.capturedAt = new Date();
      registration.registrationStatus = 'confirmed';
      await registration.save();
      capturedCount += 1;
    }

    if (registration.registrationStatus !== 'cancelled') {
      registration.registrationStatus = 'completed';
      await registration.save();
    } else {
      releasedCount += 1;
    }
  }

  event.status = 'completed';
  await event.save();

  const allRegistrations = await EventRegistration.find({ eventId: event._id });

  for (const registration of allRegistrations) {
    await notificationService.createNotification({
      userId: registration.userId,
      type: 'event_completed',
      title: 'Event completed',
      message: `The event "${event.title}" has been completed.`,
      data: {
        eventId: event._id,
        registrationId: registration._id,
        status: event.status,
      },
    });
  }

  await notificationService.createNotification({
    userId: event.organizerUserId,
    type: 'event_completed',
    title: 'Event completed',
    message: `Your event "${event.title}" has been marked as completed.`,
    data: {
      eventId: event._id,
      capturedCount,
      releasedCount,
      status: event.status,
    },
  });

  return {
    eventId: event._id,
    status: event.status,
    capturedCount,
    releasedCount,
  };
};

const cancelEvent = async (organizerUserId, eventId) => {
  const event = await GroupEvent.findById(eventId);
  if (!event) {
    throw new Error('Event not found');
  }

  if (String(event.organizerUserId) !== String(organizerUserId)) {
    throw new Error('You are not allowed to cancel this event');
  }

  if (['cancelled', 'completed'].includes(event.status)) {
    throw new Error('This event cannot be cancelled');
  }

  const registrations = await EventRegistration.find({
    eventId: event._id,
    paymentStatus: { $in: ['held', 'captured'] },
  });

  for (const registration of registrations) {
    if (registration.paymentStatus === 'held') {
      const externalPaidTx = await Transaction.findOne({
        eventRegistrationId: registration._id,
        provider: 'fawry',
        entityType: 'group_event',
        status: 'completed',
      }).sort({ createdAt: -1 });

      if (!externalPaidTx) {
        await paymentService.releaseHeldFunds({
          userId: registration.userId,
          sessionId: null,
          amount: registration.amountPaid,
          currency: registration.currency,
          eventRegistrationId: registration._id,
          reason: 'event_cancelled',
        });
      }

      registration.paymentStatus = 'released';
      registration.releasedAt = new Date();
    } else if (registration.paymentStatus === 'captured') {
      registration.paymentStatus = 'refunded';
      registration.refundedAt = new Date();
    }

    registration.registrationStatus = 'cancelled';
    registration.cancelledAt = new Date();
    await registration.save();

    await notificationService.createNotification({
      userId: registration.userId,
      type: 'event_cancelled',
      title: 'Event cancelled',
      message: `The event "${event.title}" was cancelled.`,
      data: {
        eventId: event._id,
        registrationId: registration._id,
        paymentStatus: registration.paymentStatus,
      },
    });
  }

  event.status = 'cancelled';
  event.registeredCount = 0;
  await event.save();

  return event;
};

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
  markRegistrationAttended,
  completeEvent,
  registerForEventWithFawry,
  cancelEvent,
};