const UserSettings = require('./userSettings.model');
const AppSettings = require('./appSettings.model');

async function getOrCreateUserSettings(userId) {
  let settings = await UserSettings.findOne({ userId });

  if (!settings) {
    settings = await UserSettings.create({ userId });
  }

  return settings;
}

async function getOrCreateAppSettings() {
  let settings = await AppSettings.findOne();

  if (!settings) {
    settings = await AppSettings.create({});
  }

  return settings;
}

function ensureBoolean(value, fieldName) {
  if (typeof value !== 'boolean') {
    throw new Error(`${fieldName} must be a boolean`);
  }
  return value;
}

function ensureNumber(value, fieldName) {
  const num = Number(value);
  if (!Number.isFinite(num)) {
    throw new Error(`${fieldName} must be a valid number`);
  }
  return num;
}

async function getMySettings(userId) {
  return getOrCreateUserSettings(userId);
}

async function updateMySettings(userId, payload = {}) {
  const settings = await getOrCreateUserSettings(userId);

  if (payload.language !== undefined) {
    const language = String(payload.language || '').trim();
    if (!['en', 'ar'].includes(language)) {
      throw new Error('language must be either en or ar');
    }
    settings.language = language;
  }

  if (payload.notifications !== undefined) {
    if (payload.notifications.pushEnabled !== undefined) {
      settings.notifications.pushEnabled = ensureBoolean(
        payload.notifications.pushEnabled,
        'notifications.pushEnabled'
      );
    }

    if (payload.notifications.emailEnabled !== undefined) {
      settings.notifications.emailEnabled = ensureBoolean(
        payload.notifications.emailEnabled,
        'notifications.emailEnabled'
      );
    }

    if (payload.notifications.inAppEnabled !== undefined) {
      settings.notifications.inAppEnabled = ensureBoolean(
        payload.notifications.inAppEnabled,
        'notifications.inAppEnabled'
      );
    }
  }

  if (payload.privacy !== undefined) {
    if (payload.privacy.profileVisible !== undefined) {
      settings.privacy.profileVisible = ensureBoolean(
        payload.privacy.profileVisible,
        'privacy.profileVisible'
      );
    }

    if (payload.privacy.showSkills !== undefined) {
      settings.privacy.showSkills = ensureBoolean(
        payload.privacy.showSkills,
        'privacy.showSkills'
      );
    }

    if (payload.privacy.showRoadmapProgress !== undefined) {
      settings.privacy.showRoadmapProgress = ensureBoolean(
        payload.privacy.showRoadmapProgress,
        'privacy.showRoadmapProgress'
      );
    }
  }

  if (payload.appearance !== undefined) {
    if (payload.appearance.theme !== undefined) {
      const theme = String(payload.appearance.theme || '').trim();
      if (!['light', 'dark', 'system'].includes(theme)) {
        throw new Error('appearance.theme must be light, dark, or system');
      }
      settings.appearance.theme = theme;
    }
  }

  if (payload.support !== undefined) {
    if (payload.support.showWhatsappShortcut !== undefined) {
      settings.support.showWhatsappShortcut = ensureBoolean(
        payload.support.showWhatsappShortcut,
        'support.showWhatsappShortcut'
      );
    }
  }

  await settings.save();
  return settings;
}

async function getAppSettings() {
  return getOrCreateAppSettings();
}

async function updateAppSettings(payload = {}) {
  const settings = await getOrCreateAppSettings();

  if (payload.support !== undefined) {
    if (payload.support.whatsappEnabled !== undefined) {
      settings.support.whatsappEnabled = ensureBoolean(
        payload.support.whatsappEnabled,
        'support.whatsappEnabled'
      );
    }

    if (payload.support.supportEmail !== undefined) {
      settings.support.supportEmail = String(
        payload.support.supportEmail || ''
      ).trim();
    }
  }

  if (payload.payments !== undefined) {
    if (payload.payments.walletEnabled !== undefined) {
      settings.payments.walletEnabled = ensureBoolean(
        payload.payments.walletEnabled,
        'payments.walletEnabled'
      );
    }

    if (payload.payments.fawryEnabled !== undefined) {
      settings.payments.fawryEnabled = ensureBoolean(
        payload.payments.fawryEnabled,
        'payments.fawryEnabled'
      );
    }

    if (payload.payments.platformFeePercent !== undefined) {
      const value = ensureNumber(
        payload.payments.platformFeePercent,
        'payments.platformFeePercent'
      );

      if (value < 0) {
        throw new Error('payments.platformFeePercent must be >= 0');
      }

      settings.payments.platformFeePercent = value;
    }
  }

  if (payload.mentorSessions !== undefined) {
    if (payload.mentorSessions.enabled !== undefined) {
      settings.mentorSessions.enabled = ensureBoolean(
        payload.mentorSessions.enabled,
        'mentorSessions.enabled'
      );
    }

    if (payload.mentorSessions.minDurationMinutes !== undefined) {
      const value = ensureNumber(
        payload.mentorSessions.minDurationMinutes,
        'mentorSessions.minDurationMinutes'
      );

      if (value < 1) {
        throw new Error('mentorSessions.minDurationMinutes must be >= 1');
      }

      settings.mentorSessions.minDurationMinutes = value;
    }

    if (payload.mentorSessions.maxDurationMinutes !== undefined) {
      const value = ensureNumber(
        payload.mentorSessions.maxDurationMinutes,
        'mentorSessions.maxDurationMinutes'
      );

      if (value < 1) {
        throw new Error('mentorSessions.maxDurationMinutes must be >= 1');
      }

      settings.mentorSessions.maxDurationMinutes = value;
    }

    if (payload.mentorSessions.userJoinGraceMinutes !== undefined) {
      const value = ensureNumber(
        payload.mentorSessions.userJoinGraceMinutes,
        'mentorSessions.userJoinGraceMinutes'
      );

      if (value < 1) {
        throw new Error('mentorSessions.userJoinGraceMinutes must be >= 1');
      }

      settings.mentorSessions.userJoinGraceMinutes = value;
    }

    if (
      settings.mentorSessions.minDurationMinutes >
      settings.mentorSessions.maxDurationMinutes
    ) {
      throw new Error(
        'mentorSessions.minDurationMinutes cannot be greater than mentorSessions.maxDurationMinutes'
      );
    }
  }

  if (payload.events !== undefined) {
    if (payload.events.enabled !== undefined) {
      settings.events.enabled = ensureBoolean(
        payload.events.enabled,
        'events.enabled'
      );
    }
  }

  if (payload.complaints !== undefined) {
    if (payload.complaints.enabled !== undefined) {
      settings.complaints.enabled = ensureBoolean(
        payload.complaints.enabled,
        'complaints.enabled'
      );
    }
  }

  await settings.save();
  return settings;
}

module.exports = {
  getMySettings,
  updateMySettings,
  getAppSettings,
  updateAppSettings,
};