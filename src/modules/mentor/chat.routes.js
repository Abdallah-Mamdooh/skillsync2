const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const { chatAttachmentUpload } = require('../../middlewares/upload.middleware');
const controller = require('./chat.controller');

router.get('/:sessionId/messages', authMiddleware, controller.getChatMessages);

router.post(
  '/:sessionId/messages',
  authMiddleware,
  chatAttachmentUpload.single('file'),
  controller.sendChatMessage
);

module.exports = router;