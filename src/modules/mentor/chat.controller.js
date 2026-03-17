const path = require('path');
const asyncHandler = require('../../middlewares/async.middleware');
const chatService = require('./chat.service');

function buildFileUrl(req, filePath) {
  const baseUrl = `${req.protocol}://${req.get('host')}`;
  return `${baseUrl}/${filePath.replace(/\\/g, '/')}`;
}

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
  let fileUrl = '';

  if (req.file) {
    const filePath = path.join('uploads', 'chat-attachments', req.file.filename);
    fileUrl = buildFileUrl(req, filePath);
  }

  const data = await chatService.createMessage({
    sessionId: req.params.sessionId,
    senderId: req.user._id,
    content: req.body.content,
    file: req.file || null,
    fileUrl,
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