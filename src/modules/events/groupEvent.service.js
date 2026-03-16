const GroupEvent = require('./groupEvent.model');
const EventRegistration = require('./eventRegistration.model');
const MentorProfile = require('../mentor/mentorProfile.model');
const paymentService = require('../payment/payment.service');
const User = require('../auth/user.model');
const Transaction = require('../payment/transaction.model');
const createEvent = async (organizerUserId, payload) => {
    const notificationService = require('../notification/notification.service');
  const speakers = Array.isArray(payload.speakers) ? payload.speakers : [];

  const normalizedSpeakers = [];
  for (const s of speakers) {
    const mentorProfile = await MentorProfile.findById(s.mentorProfileId).populate('userId', '_id');
    if (!mentorProfile) {
      throw new Error(`Speaker mentor profile not found: ${s.mentorProfileId}`);
    }

    normalizedSpeakers.push({
      mentorProfileId: mentorProfile._id,
      mentorUserId: mentorProfile.userId._id,
      roleLabel: s.roleLabel || 'Speaker',
    });
  }

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
    scheduledAt: payload.scheduledAt,
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

  const updatableFields = [
    'title',
    'description',
    'topic',
    'fee',
    'currency',
    'capacity',
    'meetingProvider',
    'meetingLink',
    'scheduledAt',
    'durationMinutes',
    'status',
    'coverImageUrl',
  ];

  for (const field of updatableFields) {
    if (payload[field] !== undefined) {
      event[field] = payload[field];
    }
  }

  if (Array.isArray(payload.speakers)) {
    const normalizedSpeakers = [];

    for (const s of payload.speakers) {
      const mentorProfile = await MentorProfile.findById(s.mentorProfileId).populate('userId', '_id');
      if (!mentorProfile) {
        throw new Error(`Speaker mentor profile not found: ${s.mentorProfileId}`);
      }

      normalizedSpeakers.push({
        mentorProfileId: mentorProfile._id,
        mentorUserId: mentorProfile.userId._id,
        roleLabel: s.roleLabel || 'Speaker',
      });
    }

    event.speakers = normalizedSpeakers;
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

  if (event.status !== 'published') {
    throw new Error('Only published events can be registered');
  }

  if (event.registeredCount >= event.capacity) {
    throw new Error('Event is full');
  }

  const existing = await EventRegistration.findOne({ eventId, userId });
  if (existing) {
    throw new Error('You are already registered for this event');
  }

  const defaultMethod = await paymentService.getDefaultPaymentMethod(userId);

  const registration = await EventRegistration.create({
    eventId,
    userId,
    paymentStatus: 'held',
    amountPaid: event.fee,
    currency: event.currency,
  });

  await paymentService.holdFunds({
    userId,
    sessionId: null,
    amount: event.fee,
    paymentMethodId: defaultMethod?._id || null,
    currency: event.currency,
  });

  event.registeredCount += 1;
  await event.save();

  await notificationService.createNotification({
    userId,
    type: 'event_registered',
    title: 'Event registration confirmed',
    message: `You registered for "${event.title}". ${event.fee} ${event.currency} was placed on hold.`,
    data: {
      eventId: event._id,
      registrationId: registration._id,
      amount: event.fee,
      currency: event.currency,
      paymentStatus: registration.paymentStatus,
    },
  });

  return registration;
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

  if (externalPaidTx) {
    // Fawry path:
    // no internal wallet hold to capture
    registration.paymentStatus = 'captured';
    await registration.save();
  } else {
    // Internal wallet path:
    await paymentService.captureHeldFunds({
      userId: registration.userId,
      sessionId: null,
      amount: registration.amountPaid,
      currency: registration.currency,
    });

    registration.paymentStatus = 'captured';
    await registration.save();
  }

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

  if (externalPaidTx) {
    // Fawry path:
    // no internal wallet hold to release
    registration.paymentStatus = 'released';
    await registration.save();
  } else {
    // Internal wallet path:
    await paymentService.releaseHeldFunds({
      userId: registration.userId,
      sessionId: null,
      amount: registration.amountPaid,
      currency: registration.currency,
    });

    registration.paymentStatus = 'released';
    await registration.save();
  }
  await notificationService.createNotification({
    userId: registration.userId,
    type: 'event_payment_released',
    title: 'Event payment released',
    message: `Your held registration payment for "${event.title}" was released back to your wallet.`,
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

  registration.attended = true;
  registration.checkedInAt = new Date();
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

  const registrations = await EventRegistration.find({
    eventId: event._id,
    paymentStatus: 'held',
  });

  let capturedCount = 0;

    for (const registration of registrations) {
    const externalPaidTx = await Transaction.findOne({
      eventRegistrationId: registration._id,
      provider: 'fawry',
      entityType: 'group_event',
      status: 'completed',
    }).sort({ createdAt: -1 });

    if (externalPaidTx) {
      // Fawry path:
      registration.paymentStatus = 'captured';
      await registration.save();
      capturedCount++;
    } else {
      // Internal wallet path:
      await paymentService.captureHeldFunds({
        userId: registration.userId,
        sessionId: null,
        amount: registration.amountPaid,
        currency: registration.currency,
      });

      registration.paymentStatus = 'captured';
      await registration.save();
      capturedCount++;
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
      status: event.status,
    },
  });

  return {
    eventId: event._id,
    status: event.status,
    capturedCount,
  };
};

const registerForEventWithFawry = async (userId, eventId, payload = {}) => {
  const event = await GroupEvent.findById(eventId);

  if (!event) {
    throw new Error('Event not found');
  }

  if (event.status !== 'published') {
    throw new Error('Only published events can be registered');
  }

  if (event.registeredCount >= event.capacity) {
    throw new Error('Event is full');
  }

  const existing = await EventRegistration.findOne({ eventId, userId });
  if (existing) {
    throw new Error('You are already registered for this event');
  }

  const registration = await EventRegistration.create({
    eventId,
    userId,
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
      id: event._id,
      title: event.title,
      fee: event.fee,
      currency: event.currency,
      scheduledAt: event.scheduledAt,
    },
    paymentStatus: registration.paymentStatus,
    checkout,
  };
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
};