const asyncHandler = require('../../middlewares/async.middleware');
const chatService = require('./chat.service');

const getChatMessages = asyncHandler(async (req, res) => {
  const data = await chatService.getChatMessages(
    req.params.sessionId,
    req.user._id
  );

  res.status(200).json({
    success: true,
    data,
  });
});

const sendChatMessage = asyncHandler(async (req, res) => {
  const data = await chatService.createMessage({
    sessionId: req.params.sessionId,
    senderId: req.user._id,
    content: req.body.content,
  });

  res.status(201).json({
    success: true,
    data,
  });
});

module.exports = {
  getChatMessages,
  sendChatMessage,
};