const mongoose = require('mongoose');

const messageTemplateSchema = new mongoose.Schema(
  {
    category: {
      type: String,
      enum: [
        'general',
        'payment_issue',
        'technical_issue',
        'account_issue',
        'mentor_issue',
        'event_issue',
        'complaint_followup',
      ],
      required: true,
    },
    template: {
      type: String,
      required: true,
      trim: true,
      maxlength: 1000,
    },
  },
  { _id: false }
);

const supportConfigSchema = new mongoose.Schema(
  {
    whatsappEnabled: {
      type: Boolean,
      default: true,
    },

    whatsappNumber: {
      type: String,
      trim: true,
      default: '',
    },

    displayLabel: {
      type: String,
      trim: true,
      default: 'WhatsApp Support',
    },

    defaultCountryCode: {
      type: String,
      trim: true,
      default: '20',
    },

    messageTemplates: {
      type: [messageTemplateSchema],
      default: [
        {
          category: 'general',
          template:
            'Hello SkillSync Support, I need help with a general issue.',
        },
        {
          category: 'payment_issue',
          template:
            'Hello SkillSync Support, I need help with a payment issue.',
        },
        {
          category: 'technical_issue',
          template:
            'Hello SkillSync Support, I am facing a technical issue in the app.',
        },
        {
          category: 'account_issue',
          template:
            'Hello SkillSync Support, I need help with my account.',
        },
        {
          category: 'mentor_issue',
          template:
            'Hello SkillSync Support, I need help regarding a mentor/session issue.',
        },
        {
          category: 'event_issue',
          template:
            'Hello SkillSync Support, I need help regarding an event issue.',
        },
        {
          category: 'complaint_followup',
          template:
            'Hello SkillSync Support, I want to follow up on my complaint.',
        },
      ],
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('SupportConfig', supportConfigSchema);