const ReminderLog = require('./reminderLog.model');
const notificationService = require('./notification.service');

const MentorSession = require('../mentor/mentorSession.model');
const GroupEvent = require('../events/groupEvent.model');
const EventRegistration = require('../events/eventRegistration.model');

async function alreadySent({ userId, entityType, entityId, reminderType }) {
  const existing = await ReminderLog.findOne({
    userId,
    entityType,
    entityId,
    reminderType,
  });

  return !!existing;
}

async function markSent({ userId, entityType, entityId, reminderType }) {
  await ReminderLog.create({
    userId,
    entityType,
    entityId,
    reminderType,
  });
}

const sendSessionExpiringSoonReminders = async () => {
  const now = new Date();
  const inFiveMinutes = new Date(now.getTime() + 5 * 60 * 1000);

  const sessions = await MentorSession.find({
    status: 'pending',
    expiresAt: { $gt: now, $lte: inFiveMinutes },
  });

  let sentCount = 0;

  for (const session of sessions) {
    const reminderType = 'session_expiring_soon';
    const entityType = 'mentor_session';
    const entityId = session._id;

    const sent = await alreadySent({
      userId: session.userId,
      entityType,
      entityId,
      reminderType,
    });

    if (sent) continue;

    await notificationService.createNotification({
      userId: session.userId,
      type: 'session_expiring_soon',
      title: 'Session request expiring soon',
      message: 'Your mentor session request is about to expire if it is not accepted soon.',
      data: {
        sessionId: session._id,
        expiresAt: session.expiresAt,
        status: session.status,
      },
    });

    await markSent({
      userId: session.userId,
      entityType,
      entityId,
      reminderType,
    });

    sentCount++;
  }

  return { sentCount };
};

const sendSessionStartingSoonReminders = async () => {
  const now = new Date();
  const inFifteenMinutes = new Date(now.getTime() + 15 * 60 * 1000);

  const sessions = await MentorSession.find({
    status: 'accepted',
    expiresAt: { $exists: true },
    acceptedAt: { $ne: null },
    startedAt: null,
    createdAt: { $lte: now },
    // MVP approximation since there is no explicit scheduledAt for sessions yet
    // use accepted sessions created recently and not started yet
  });

  let sentCount = 0;

  for (const session of sessions) {
    // only send if accepted recently enough to be relevant
    const acceptedAt = session.acceptedAt ? new Date(session.acceptedAt) : null;
    if (!acceptedAt) continue;

    const diff = acceptedAt.getTime() - now.getTime();
    if (diff > 15 * 60 * 1000) continue;
    if (acceptedAt > inFifteenMinutes) continue;

    const reminderType = 'session_starting_soon';
    const entityType = 'mentor_session';
    const entityId = session._id;

    for (const userId of [session.userId, session.mentorUserId]) {
      const sent = await alreadySent({
        userId,
        entityType,
        entityId,
        reminderType,
      });

      if (sent) continue;

      await notificationService.createNotification({
        userId,
        type: 'session_starting_soon',
        title: 'Session starting soon',
        message: 'Your mentor session is starting soon.',
        data: {
          sessionId: session._id,
          status: session.status,
          acceptedAt: session.acceptedAt,
          method: session.method,
        },
      });

      await markSent({
        userId,
        entityType,
        entityId,
        reminderType,
      });

      sentCount++;
    }
  }

  return { sentCount };
};

const sendEventStartingSoonReminders = async () => {
  const now = new Date();
  const inOneHour = new Date(now.getTime() + 60 * 60 * 1000);

  const events = await GroupEvent.find({
    status: 'published',
    scheduledAt: { $gt: now, $lte: inOneHour },
  });

  let attendeeSentCount = 0;
  let speakerSentCount = 0;

  for (const event of events) {
    // attendees
    const registrations = await EventRegistration.find({ eventId: event._id });

    for (const registration of registrations) {
      const reminderType = 'event_starting_soon';
      const entityType = 'group_event';
      const entityId = event._id;

      const sent = await alreadySent({
        userId: registration.userId,
        entityType,
        entityId,
        reminderType,
      });

      if (sent) continue;

      await notificationService.createNotification({
        userId: registration.userId,
        type: 'event_starting_soon',
        title: 'Event starting soon',
        message: `Your registered event "${event.title}" is starting soon.`,
        data: {
          eventId: event._id,
          title: event.title,
          scheduledAt: event.scheduledAt,
          meetingProvider: event.meetingProvider,
        },
      });

      await markSent({
        userId: registration.userId,
        entityType,
        entityId,
        reminderType,
      });

      attendeeSentCount++;
    }

    // speakers
    for (const speaker of event.speakers || []) {
      const reminderType = 'speaker_event_starting_soon';
      const entityType = 'group_event';
      const entityId = event._id;

      const sent = await alreadySent({
        userId: speaker.mentorUserId,
        entityType,
        entityId,
        reminderType,
      });

      if (sent) continue;

      await notificationService.createNotification({
        userId: speaker.mentorUserId,
        type: 'speaker_event_starting_soon',
        title: 'Your event is starting soon',
        message: `The event "${event.title}" where you are a speaker is starting soon.`,
        data: {
          eventId: event._id,
          title: event.title,
          scheduledAt: event.scheduledAt,
          roleLabel: speaker.roleLabel,
          meetingProvider: event.meetingProvider,
        },
      });

      await markSent({
        userId: speaker.mentorUserId,
        entityType,
        entityId,
        reminderType,
      });

      speakerSentCount++;
    }
  }

  return { attendeeSentCount, speakerSentCount };
};

const runReminderChecks = async () => {
  const sessionExpiring = await sendSessionExpiringSoonReminders();
  const sessionStarting = await sendSessionStartingSoonReminders();
  const eventStarting = await sendEventStartingSoonReminders();

  return {
    sessionExpiring,
    sessionStarting,
    eventStarting,
  };
};

module.exports = {
  sendSessionExpiringSoonReminders,
  sendSessionStartingSoonReminders,
  sendEventStartingSoonReminders,
  runReminderChecks,
};