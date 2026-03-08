const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const controller = require('./chat.controller');

router.get('/:sessionId/messages', authMiddleware, controller.getChatMessages);
router.post('/:sessionId/messages', authMiddleware, controller.sendChatMessage);

module.exports = router;