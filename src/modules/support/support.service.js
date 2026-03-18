const SupportConfig = require('./supportConfig.model');

const ALLOWED_CATEGORIES = [
  'general',
  'payment_issue',
  'technical_issue',
  'account_issue',
  'mentor_issue',
  'event_issue',
  'complaint_followup',
];

function normalizeText(value) {
  return String(value || '').trim();
}

function normalizePhoneNumber(value) {
  return String(value || '').replace(/[^\d]/g, '').trim();
}

function normalizeTemplates(templates = []) {
  if (!Array.isArray(templates)) {
    throw new Error('messageTemplates must be an array');
  }

  return templates.map((item) => {
    const category = normalizeText(item.category);
    const template = normalizeText(item.template);

    if (!ALLOWED_CATEGORIES.includes(category)) {
      throw new Error(`Invalid template category: ${category}`);
    }

    if (!template) {
      throw new Error(`Template text is required for category: ${category}`);
    }

    return { category, template };
  });
}

async function getOrCreateSupportConfig() {
  let config = await SupportConfig.findOne();

  if (!config) {
    config = await SupportConfig.create({});
  }

  return config;
}

function buildWhatsappUrl(number, message) {
  const encodedMessage = encodeURIComponent(message || '');
  return `https://wa.me/${number}?text=${encodedMessage}`;
}

function fillTemplate(template, variables = {}) {
  let result = String(template || '');

  for (const [key, value] of Object.entries(variables)) {
    const safeValue = normalizeText(value);
    result = result.replace(new RegExp(`\\{${key}\\}`, 'g'), safeValue);
  }

  return result;
}

async function getWhatsappSupportConfig() {
  const config = await getOrCreateSupportConfig();

  return {
    whatsappEnabled: config.whatsappEnabled,
    whatsappNumber: config.whatsappNumber,
    displayLabel: config.displayLabel,
    defaultCountryCode: config.defaultCountryCode,
    categories: config.messageTemplates.map((item) => item.category),
  };
}

async function getWhatsappSupportConfigAdmin() {
  return getOrCreateSupportConfig();
}

async function updateWhatsappSupportConfig(payload = {}) {
  const config = await getOrCreateSupportConfig();

  if (payload.whatsappEnabled !== undefined) {
    if (typeof payload.whatsappEnabled !== 'boolean') {
      throw new Error('whatsappEnabled must be a boolean');
    }
    config.whatsappEnabled = payload.whatsappEnabled;
  }

  if (payload.whatsappNumber !== undefined) {
    const normalized = normalizePhoneNumber(payload.whatsappNumber);

    if (!normalized) {
      throw new Error('whatsappNumber cannot be empty');
    }

    config.whatsappNumber = normalized;
  }

  if (payload.displayLabel !== undefined) {
    config.displayLabel = normalizeText(payload.displayLabel);
  }

  if (payload.defaultCountryCode !== undefined) {
    config.defaultCountryCode = normalizePhoneNumber(payload.defaultCountryCode);
  }

  if (payload.messageTemplates !== undefined) {
    config.messageTemplates = normalizeTemplates(payload.messageTemplates);
  }

  await config.save();
  return config;
}

async function buildWhatsappMessagePreview(payload = {}) {
  const config = await getOrCreateSupportConfig();

  if (!config.whatsappEnabled) {
    throw new Error('WhatsApp support is currently disabled');
  }

  if (!config.whatsappNumber) {
    throw new Error('WhatsApp support number is not configured');
  }

  const category = normalizeText(payload.category || 'general');
  const templateObj =
    config.messageTemplates.find((item) => item.category === category) ||
    config.messageTemplates.find((item) => item.category === 'general');

  const template = templateObj?.template || 'Hello SkillSync Support, I need help.';
  const message = fillTemplate(template, {
    userName: payload.userName,
    complaintId: payload.complaintId,
    sessionId: payload.sessionId,
    eventId: payload.eventId,
    paymentId: payload.paymentId,
    note: payload.note,
  });

  return {
    whatsappEnabled: config.whatsappEnabled,
    whatsappNumber: config.whatsappNumber,
    displayLabel: config.displayLabel,
    category,
    message,
    url: buildWhatsappUrl(config.whatsappNumber, message),
  };
}

module.exports = {
  ALLOWED_CATEGORIES,
  getWhatsappSupportConfig,
  getWhatsappSupportConfigAdmin,
  updateWhatsappSupportConfig,
  buildWhatsappMessagePreview,
};