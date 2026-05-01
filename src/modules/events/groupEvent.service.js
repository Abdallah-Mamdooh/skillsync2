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

function ensureFutureDateOrNull(dateValue) {
  if (!dateValue) {
    return null;
  }

  return ensureFutureDate(dateValue);
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
function buildEventAvailability(event) {
  const capacity = Number(event.capacity || 0);
  const registeredCount = Number(event.registeredCount || 0);
  const availableSeats = Math.max(capacity - registeredCount, 0);
  const isFull = availableSeats <= 0;

  let registrationState = 'closed';

  if (event.status === 'published' && new Date(event.scheduledAt) > new Date()) {
    registrationState = isFull ? 'full' : 'open';
  }

  return {
    capacity,
    registeredCount,
    availableSeats,
    isFull,
    registrationState,
  };
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

function normalizeLearningOutcomes(value) {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((item) => String(item || '').trim())
    .filter(Boolean);
}

const createEvent = async (organizerUserId, payload) => {
  const speakers = Array.isArray(payload.speakers) ? payload.speakers : [];
  const normalizedSpeakers = await normalizeSpeakers(speakers);

  const requestedScheduledAt = ensureFutureDateOrNull(
    payload.requestedScheduledAt || payload.scheduledAt
  );

  const requestedDurationMinutes =
    payload.requestedDurationMinutes || payload.durationMinutes || null;

  const requestedCapacity =
    payload.requestedCapacity || payload.capacity || null;

  const requestedFee =
    payload.requestedFee !== undefined
      ? payload.requestedFee
      : payload.fee !== undefined
        ? payload.fee
        : null;

  const event = await GroupEvent.create({
    organizerUserId,

    title: payload.title,
    description: payload.description || '',
    topic: payload.topic || '',
    eventType: payload.eventType || 'webinar',
    targetAudience: payload.targetAudience || '',
    agenda: payload.agenda || '',
    learningOutcomes: normalizeLearningOutcomes(payload.learningOutcomes),
    requirements: payload.requirements || '',

    speakers: normalizedSpeakers,

    // Final admin-confirmed values.
    // These can be filled later by admin during approval.
    fee: payload.fee || 0,
    currency: payload.currency || 'EGP',
    capacity: payload.capacity || 100,
    meetingProvider: payload.meetingProvider || 'google_meet',
    meetingLink: payload.meetingLink || '',
    scheduledAt: ensureFutureDateOrNull(payload.scheduledAt),
    durationMinutes: payload.durationMinutes || 60,

    // Mentor-requested values.
    requestedScheduledAt,
    requestedDurationMinutes,
    requestedCapacity,
    requestedFee,
    mentorNotes: payload.mentorNotes || '',

    status: 'draft',
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

  if (!['draft', 'rejected'].includes(event.status)) {
    throw new Error('Only draft or rejected event requests can be edited by the mentor');
  }

  const updatableFields = [
    'title',
    'description',
    'topic',
    'eventType',
    'targetAudience',
    'agenda',
    'requirements',
    'mentorNotes',
    'coverImageUrl',
  ];

  for (const field of updatableFields) {
    if (payload[field] !== undefined) {
      event[field] = payload[field];
    }
  }

  if (payload.learningOutcomes !== undefined) {
    event.learningOutcomes = normalizeLearningOutcomes(payload.learningOutcomes);
  }

  if (payload.requestedScheduledAt !== undefined || payload.scheduledAt !== undefined) {
    event.requestedScheduledAt = ensureFutureDateOrNull(
      payload.requestedScheduledAt || payload.scheduledAt
    );
  }

  if (payload.requestedDurationMinutes !== undefined || payload.durationMinutes !== undefined) {
    event.requestedDurationMinutes =
      payload.requestedDurationMinutes || payload.durationMinutes || null;
  }

  if (payload.requestedCapacity !== undefined || payload.capacity !== undefined) {
    event.requestedCapacity =
      payload.requestedCapacity || payload.capacity || null;
  }

  if (payload.requestedFee !== undefined || payload.fee !== undefined) {
    event.requestedFee =
      payload.requestedFee !== undefined ? payload.requestedFee : payload.fee;
  }

  if (Array.isArray(payload.speakers)) {
    event.speakers = await normalizeSpeakers(payload.speakers);
  }

  // If admin rejected it before, editing it should return it to draft.
  if (event.status === 'rejected') {
    event.status = 'draft';
    event.rejectionReason = '';
    event.adminNotes = '';
    event.adminReviewedBy = null;
    event.adminReviewedAt = null;
  }

  await event.save();
  return event;
};
const submitEventRequest = async (organizerUserId, eventId) => {
  const event = await GroupEvent.findById(eventId);
  if (!event) {
    throw new Error('Event not found');
  }

  if (String(event.organizerUserId) !== String(organizerUserId)) {
    throw new Error('You are not allowed to submit this event request');
  }

  if (!['draft', 'rejected'].includes(event.status)) {
    throw new Error('Only draft or rejected event requests can be submitted');
  }

  if (!event.title) {
    throw new Error('Event title is required');
  }

  if (!event.description) {
    throw new Error('Event description is required');
  }

  if (!event.topic) {
    throw new Error('Event topic is required');
  }

  event.status = 'pending_review';
  event.submittedAt = new Date();

  // Clear old rejection/admin data if resubmitting.
  event.rejectionReason = '';
  event.adminNotes = '';
  event.adminReviewedBy = null;
  event.adminReviewedAt = null;
  event.approvedAt = null;

  await event.save();

  await notificationService.createNotification({
    userId: event.organizerUserId,
    type: 'event_request_submitted',
    title: 'Event request submitted',
    message: `Your event request "${event.title}" was submitted for admin review.`,
    data: {
      eventId: event._id,
      status: event.status,
    },
  });

  return event;
};

const getPendingEventRequests = async () => {
  return GroupEvent.find({ status: 'pending_review' })
    .sort({ submittedAt: 1, createdAt: 1 })
    .populate('organizerUserId', 'fullName email phoneNumber role')
    .populate('speakers.mentorUserId', 'fullName email')
    .populate('speakers.mentorProfileId');
};

const getAllAdminEvents = async (filters = {}) => {
  const query = {};

  if (filters.status) {
    query.status = filters.status;
  }

  const events = await GroupEvent.find(query)
    .sort({ createdAt: -1 })
    .populate('organizerUserId', 'fullName email phoneNumber role')
    .populate('speakers.mentorUserId', 'fullName email')
    .populate('speakers.mentorProfileId');

  return events.map((event) => {
    const obj = event.toObject();

    return {
      ...obj,
      availability: buildEventAvailability(event),
    };
  });
};

const approveEventRequest = async (adminUserId, eventId, payload = {}) => {
  const event = await GroupEvent.findById(eventId);
  if (!event) {
    throw new Error('Event not found');
  }

  if (event.status !== 'pending_review') {
    throw new Error('Only pending event requests can be approved');
  }

  const finalScheduledAt = payload.scheduledAt || event.requestedScheduledAt;
  const finalDurationMinutes =
    payload.durationMinutes || event.requestedDurationMinutes || event.durationMinutes;
  const finalCapacity =
    payload.capacity || event.requestedCapacity || event.capacity;
  const finalFee =
    payload.fee !== undefined
      ? payload.fee
      : event.requestedFee !== null && event.requestedFee !== undefined
        ? event.requestedFee
        : event.fee;

  if (!finalScheduledAt) {
    throw new Error('scheduledAt is required before approval');
  }

  event.scheduledAt = ensureFutureDate(finalScheduledAt);
  event.durationMinutes = finalDurationMinutes || 60;
  event.capacity = finalCapacity || 100;
  event.fee = finalFee || 0;
  event.currency = payload.currency || event.currency || 'EGP';

  if (payload.meetingProvider !== undefined) {
    event.meetingProvider = payload.meetingProvider;
  }

  if (payload.meetingLink !== undefined) {
    event.meetingLink = payload.meetingLink;
  }

  if (payload.adminNotes !== undefined) {
    event.adminNotes = payload.adminNotes;
  }

  event.status = 'approved';
  event.adminReviewedBy = adminUserId;
  event.adminReviewedAt = new Date();
  event.approvedAt = new Date();
  event.rejectionReason = '';

  await event.save();

  await notificationService.createNotification({
    userId: event.organizerUserId,
    type: 'event_request_approved',
    title: 'Event request approved',
    message: `Your event request "${event.title}" was approved.`,
    data: {
      eventId: event._id,
      status: event.status,
      scheduledAt: event.scheduledAt,
      durationMinutes: event.durationMinutes,
      capacity: event.capacity,
      fee: event.fee,
      currency: event.currency,
    },
  });

  return event;
};

const rejectEventRequest = async (adminUserId, eventId, payload = {}) => {
  const event = await GroupEvent.findById(eventId);
  if (!event) {
    throw new Error('Event not found');
  }

  if (!['pending_review', 'approved'].includes(event.status)) {
    throw new Error('Only pending or approved event requests can be rejected');
  }

  event.status = 'rejected';
  event.adminReviewedBy = adminUserId;
  event.adminReviewedAt = new Date();
  event.adminNotes = payload.adminNotes || '';
  event.rejectionReason = payload.rejectionReason || 'Event request was rejected by admin';
  event.approvedAt = null;

  await event.save();

  await notificationService.createNotification({
    userId: event.organizerUserId,
    type: 'event_request_rejected',
    title: 'Event request rejected',
    message: `Your event request "${event.title}" was rejected.`,
    data: {
      eventId: event._id,
      status: event.status,
      rejectionReason: event.rejectionReason,
    },
  });

  return event;
};

const publishEvent = async (adminUserId, eventId) => {
  const event = await GroupEvent.findById(eventId);
  if (!event) {
    throw new Error('Event not found');
  }

  if (event.status !== 'approved') {
    throw new Error('Only approved events can be published');
  }

  if (!event.scheduledAt) {
    throw new Error('Event scheduledAt is required before publishing');
  }

  ensureFutureDate(event.scheduledAt);

  if (Number(event.capacity || 0) < 1) {
    throw new Error('Event capacity must be at least 1');
  }

  if (Number(event.registeredCount || 0) >= Number(event.capacity || 0)) {
    throw new Error('Cannot publish a full event');
  }

  event.status = 'published';
  event.adminReviewedBy = event.adminReviewedBy || adminUserId;
  event.publishedAt = new Date();

  await event.save();

  await notificationService.createNotification({
    userId: event.organizerUserId,
    type: 'event_published',
    title: 'Event published',
    message: `Your event "${event.title}" has been published.`,
    data: {
      eventId: event._id,
      title: event.title,
      scheduledAt: event.scheduledAt,
      capacity: event.capacity,
      fee: event.fee,
      currency: event.currency,
    },
  });

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
  const events = await GroupEvent.find({ status: 'published' })
    .sort({ scheduledAt: 1 })
    .populate('speakers.mentorUserId', 'fullName email');

  return events.map((event) => {
    const obj = event.toObject();

    return {
      ...obj,
      availability: buildEventAvailability(event),
    };
  });
};

const getMyCreatedEvents = async (organizerUserId) => {
  const events = await GroupEvent.find({ organizerUserId })
    .sort({ createdAt: -1 })
    .populate('speakers.mentorUserId', 'fullName email')
    .populate('speakers.mentorProfileId');

  return events.map((event) => {
    const obj = event.toObject();

    return {
      ...obj,
      availability: buildEventAvailability(event),
    };
  });
};

const getEventById = async (eventId) => {
  const event = await GroupEvent.findById(eventId)
    .populate('organizerUserId', 'fullName email')
    .populate('speakers.mentorUserId', 'fullName email')
    .populate('speakers.mentorProfileId');

  if (!event) {
    throw new Error('Event not found');
  }

  const obj = event.toObject();

  return {
    ...obj,
    availability: buildEventAvailability(event),
  };
};

const registerForEvent = async (userId, eventId) => {
  const event = await GroupEvent.findById(eventId);
  if (!event) {
    throw new Error('Event not found');
  }

  canRegisterForEvent(event);

const availability = buildEventAvailability(event);
if (availability.registrationState !== 'open') {
  throw new Error(
    availability.isFull
      ? 'Event is full and no longer accepts registrations'
      : 'Event registration is closed'
  );
}
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

const availability = buildEventAvailability(event);
if (availability.registrationState !== 'open') {
  throw new Error(
    availability.isFull
      ? 'Event is full and no longer accepts registrations'
      : 'Event registration is closed'
  );
}

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
  submitEventRequest,

  getMyCreatedEvents,
  getPendingEventRequests,
  getAllAdminEvents,
  approveEventRequest,
  rejectEventRequest,
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