const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const controller = require('./support.controller');

// public / authenticated app usage
router.get('/whatsapp', controller.getWhatsappSupportConfig);

router.post(
  '/whatsapp/message-preview',
  authMiddleware,
  controller.buildWhatsappMessagePreview
);

// admin management
router.get(
  '/admin/whatsapp',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getWhatsappSupportConfigAdmin
);

router.patch(
  '/admin/whatsapp',
  authMiddleware,
  roleMiddleware('admin'),
  controller.updateWhatsappSupportConfig
);

module.exports = router;