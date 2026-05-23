const MentorProfile = require('./mentorProfile.model');
const MentorSession = require('./mentorSession.model');
const MentorAvailabilityException = require('./mentorAvailabilityException.model');

const FIXED_TIMEZONE = 'Africa/Cairo';
const STEP_MINUTES = 5;

function pad2(value) {
  return String(value).padStart(2, '0');
}

function parseTimeToMinutes(value) {
  const str = String(value || '').trim();
  const match = /^(\d{1,2}):(\d{2})$/.exec(str);

  if (!match) {
    throw new Error(`Invalid time format: ${value}`);
  }

  const hours = Number(match[1]);
  const minutes = Number(match[2]);

  if (
    !Number.isInteger(hours) ||
    !Number.isInteger(minutes) ||
    hours < 0 ||
    hours > 23 ||
    minutes < 0 ||
    minutes > 59
  ) {
    throw new Error(`Invalid time value: ${value}`);
  }

  return hours * 60 + minutes;
}

function formatMinutesToTime(totalMinutes) {
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  return `${pad2(hours)}:${pad2(minutes)}`;
}

function normalizeAvailabilityRanges(ranges) {
  if (!Array.isArray(ranges)) {
    return [];
  }

  return ranges
    .map((item) => ({
      dayOfWeek: Number(item.dayOfWeek),
      startTime: String(item.startTime || '').trim(),
      endTime: String(item.endTime || '').trim(),
      isActive: item.isActive !== false,
    }))
    .filter((item) => item.isActive)
    .map((item) => {
      const startMinutes = parseTimeToMinutes(item.startTime);
      const endMinutes = parseTimeToMinutes(item.endTime);

      if (endMinutes <= startMinutes) {
        throw new Error(
          `Availability range endTime must be after startTime for day ${item.dayOfWeek}`
        );
      }

      return {
        ...item,
        startMinutes,
        endMinutes,
      };
    })
    .sort((a, b) => {
      if (a.dayOfWeek !== b.dayOfWeek) return a.dayOfWeek - b.dayOfWeek;
      return a.startMinutes - b.startMinutes;
    });
}

function validateAvailabilityRanges(ranges) {
  const normalized = normalizeAvailabilityRanges(ranges);

  for (let i = 0; i < normalized.length; i += 1) {
    const current = normalized[i];
    const next = normalized[i + 1];

    if (
      next &&
      current.dayOfWeek === next.dayOfWeek &&
      current.endMinutes > next.startMinutes
    ) {
      throw new Error(
        `Availability ranges overlap on day ${current.dayOfWeek}`
      );
    }
  }

  return normalized.map((item) => ({
    dayOfWeek: item.dayOfWeek,
    startTime: item.startTime,
    endTime: item.endTime,
    isActive: item.isActive,
  }));
}

function getDayOfWeekFromDate(dateStr) {
  const date = new Date(`${dateStr}T00:00:00`);
  if (Number.isNaN(date.getTime())) {
    throw new Error('Invalid date. Expected YYYY-MM-DD');
  }
  return date.getDay();
}

function combineDateAndTime(dateStr, timeStr) {
  const date = new Date(`${dateStr}T${timeStr}:00`);
  if (Number.isNaN(date.getTime())) {
    throw new Error(`Invalid date/time combination: ${dateStr} ${timeStr}`);
  }
  return date;
}

function overlapExists(aStart, aEnd, bStart, bEnd) {
  return aStart < bEnd && aEnd > bStart;
}

async function getBookedIntervalsForMentor(mentorProfileId, scheduledDate) {
  const sessions = await MentorSession.find({
    mentorProfileId,
    scheduledDate,
    status: {
      $in: ['scheduled', 'started', 'active'],
    },
  }).select('scheduledStartTime scheduledEndTime status');

  return sessions.map((session) => ({
    startMinutes: parseTimeToMinutes(session.scheduledStartTime),
    endMinutes: parseTimeToMinutes(session.scheduledEndTime),
    status: session.status,
  }));
}

async function getExceptionIntervalsForMentor(mentorProfileId, scheduledDate) {
  const dayStart = combineDateAndTime(scheduledDate, '00:00');
  const dayEnd = combineDateAndTime(scheduledDate, '23:59');

  const exceptions = await MentorAvailabilityException.find({
    mentorProfileId,
    isActive: true,
    unavailableFrom: { $lt: dayEnd },
    unavailableTo: { $gt: dayStart },
  });

  return exceptions.map((exception) => {
    const from = new Date(exception.unavailableFrom);
    const to = new Date(exception.unavailableTo);

    const effectiveStart = from < dayStart ? dayStart : from;
    const effectiveEnd = to > dayEnd ? dayEnd : to;

    const startMinutes =
      effectiveStart.getHours() * 60 + effectiveStart.getMinutes();

    const endMinutes =
      effectiveEnd.getHours() * 60 + effectiveEnd.getMinutes();

    return {
      startMinutes,
      endMinutes,
      reason: exception.reason || '',
    };
  });
}

async function getAvailableSlots(mentorProfileId, date, durationMinutes) {
  const duration = Number(durationMinutes);

  if (
    !Number.isInteger(duration) ||
    duration < 15 ||
    duration > 60 ||
    duration % 5 !== 0
  ) {
    throw new Error(
      'durationMinutes must be between 15 and 60 in 5-minute increments'
    );
  }
   const requestedDate = new Date(`${date}T00:00:00`);
const today = new Date();
today.setHours(0, 0, 0, 0);

const maxDate = new Date(today);
maxDate.setDate(today.getDate() + 7);

if (Number.isNaN(requestedDate.getTime())) {
  throw new Error('Invalid date. Expected YYYY-MM-DD');
}

if (requestedDate < today) {
  throw new Error('Cannot book a past date');
}

if (requestedDate > maxDate) {
  throw new Error('Cannot book more than 7 days ahead');
}
     

  const mentorProfile = await MentorProfile.findById(mentorProfileId);

  if (!mentorProfile) {
    throw new Error('Mentor profile not found');
  }

  if (!mentorProfile.isVerified) {
    throw new Error('Mentor is not verified');
  }

  

  const dayOfWeek = getDayOfWeekFromDate(date);

  const availability = normalizeAvailabilityRanges(
    mentorProfile.availability || []
  );

  const dayRanges = availability.filter(
    (item) => item.dayOfWeek === dayOfWeek
  );

  if (dayRanges.length === 0) {
    return {
      mentorProfileId,
      date,
      durationMinutes: duration,
      timezone: mentorProfile.timezone || FIXED_TIMEZONE,
      slots: [],
    };
  }

  const bookedIntervals = await getBookedIntervalsForMentor(
    mentorProfileId,
    date
  );

  const exceptionIntervals = await getExceptionIntervalsForMentor(
    mentorProfileId,
    date
  );

  const slots = [];

  for (const range of dayRanges) {
    for (
      let candidateStart = range.startMinutes;
      candidateStart + duration <= range.endMinutes;
      candidateStart += STEP_MINUTES
    ) {
      const candidateEnd = candidateStart + duration;

      const conflictsWithBooking = bookedIntervals.some((booking) =>
        overlapExists(
          candidateStart,
          candidateEnd,
          booking.startMinutes,
          booking.endMinutes
        )
      );

      const conflictsWithException = exceptionIntervals.some((exception) =>
        overlapExists(
          candidateStart,
          candidateEnd,
          exception.startMinutes,
          exception.endMinutes
        )
      );

      if (!conflictsWithBooking && !conflictsWithException) {
        slots.push({
          startTime: formatMinutesToTime(candidateStart),
          endTime: formatMinutesToTime(candidateEnd),
        });
      }
    }
  }

  return {
    mentorProfileId,
    date,
    durationMinutes: duration,
    timezone: mentorProfile.timezone || FIXED_TIMEZONE,
    slots,
  };
}


async function validateBookingSlot({
  mentorProfileId,
  scheduledDate,
  scheduledStartTime,
  durationMinutes,
}) {
  const availabilityResult = await getAvailableSlots(
    mentorProfileId,
    scheduledDate,
    durationMinutes
  );

  const matching = availabilityResult.slots.find(
    (slot) => slot.startTime === scheduledStartTime
  );

  if (!matching) {
    throw new Error(
      'Selected booking slot is no longer available. Please choose another time.'
    );
  }

  return {
    scheduledDate,
    scheduledStartTime,
    scheduledEndTime: matching.endTime,
    timezone: availabilityResult.timezone,
  };
}

module.exports = {
  FIXED_TIMEZONE,
  STEP_MINUTES,
  parseTimeToMinutes,
  formatMinutesToTime,
  validateAvailabilityRanges,
  getAvailableSlots,
  validateBookingSlot,
  combineDateAndTime,
  getExceptionIntervalsForMentor,
};