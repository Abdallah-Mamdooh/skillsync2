const ReminderLog = require('./reminderLog.model');
const notificationService = require('./notification.service');

const MentorSession = require('../mentor/mentorSession.model');
const GroupEvent = require('../events/groupEvent.model');
const EventRegistration = require('../events/eventRegistration.model');
const sendEmail = require('../../utils/sendEmail');

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

  const windows = [
    {
      reminderType: 'session_24h_before',
      label: '24 hours',
      from: new Date(now.getTime() + 24 * 60 * 60 * 1000),
      to: new Date(now.getTime() + 24 * 60 * 60 * 1000 + 5 * 60 * 1000),
    },
    {
      reminderType: 'session_1h_before',
      label: '1 hour',
      from: new Date(now.getTime() + 60 * 60 * 1000),
      to: new Date(now.getTime() + 60 * 60 * 1000 + 5 * 60 * 1000),
    },
    {
      reminderType: 'session_15m_before',
      label: '15 minutes',
      from: new Date(now.getTime() + 15 * 60 * 1000),
      to: new Date(now.getTime() + 15 * 60 * 1000 + 5 * 60 * 1000),
    },
  ];

  let sentCount = 0;

  for (const window of windows) {
    const sessions = await MentorSession.find({
      status: 'scheduled',
      startAt: {
        $gte: window.from,
        $lte: window.to,
      },
    })
      .populate('userId', 'fullName email')
      .populate('mentorUserId', 'fullName email');

    for (const session of sessions) {
      const entityType = 'mentor_session';
      const entityId = session._id;

      const recipients = [
        {
          userId: session.userId?._id,
          email: session.userId?.email,
          name: session.userId?.fullName || 'Student',
          role: 'user',
        },
        {
          userId: session.mentorUserId?._id,
          email: session.mentorUserId?.email,
          name: session.mentorUserId?.fullName || 'Mentor',
          role: 'mentor',
        },
      ];

      for (const recipient of recipients) {
        if (!recipient.userId) continue;

        const sent = await alreadySent({
          userId: recipient.userId,
          entityType,
          entityId,
          reminderType: window.reminderType,
        });

        if (sent) continue;

        await notificationService.createNotification({
          userId: recipient.userId,
          type: window.reminderType,
          title: 'Session reminder',
          message: `Your mentor session starts in ${window.label}.`,
          data: {
            sessionId: session._id,
            scheduledDate: session.scheduledDate,
            scheduledStartTime: session.scheduledStartTime,
            scheduledEndTime: session.scheduledEndTime,
            method: session.method,
          },
        });

        if (recipient.email) {
          await sendEmail(
            recipient.email,
            'SkillSync Session Reminder',
            `
              <h2>SkillSync Session Reminder</h2>
              <p>Hello ${recipient.name},</p>
              <p>Your mentor session starts in <strong>${window.label}</strong>.</p>
              <p><strong>Date:</strong> ${session.scheduledDate}</p>
              <p><strong>Time:</strong> ${session.scheduledStartTime} - ${session.scheduledEndTime}</p>
              <p>Please open SkillSync and be ready before the session starts.</p>
            `
          );
        }

        await markSent({
          userId: recipient.userId,
          entityType,
          entityId,
          reminderType: window.reminderType,
        });

        sentCount++;
      }
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