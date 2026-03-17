const ChatMessage = require('./chatMessage.model');
const MentorSession = require('./mentorSession.model');
const notificationService = require('../notification/notification.service');

function buildAttachmentPayload(file, fileUrl) {
  if (!file) return null;

  return {
    url: fileUrl,
    fileName: file.originalname,
    mimeType: file.mimetype,
    size: file.size || 0,
  };
}

function inferMessageType({ content, attachment }) {
  if (!attachment) {
    return 'text';
  }

  if (String(attachment.mimeType || '').startsWith('image/')) {
    return 'image';
  }

  return 'file';
}

const getSessionForParticipant = async (sessionId, currentUserId) => {
  const session = await MentorSession.findById(sessionId);

  if (!session) {
    throw new Error('Session not found');
  }

  const isUser = String(session.userId) === String(currentUserId);
  const isMentor = String(session.mentorUserId) === String(currentUserId);

  if (!isUser && !isMentor) {
    throw new Error('You are not allowed to access this chat');
  }

  return {
    session,
    isUser,
    isMentor,
    senderRole: isMentor ? 'mentor' : 'user',
  };
};

const getChatMessages = async (sessionId, currentUserId) => {
  await getSessionForParticipant(sessionId, currentUserId);
  return ChatMessage.find({ sessionId }).sort({ createdAt: 1 });
};

const createMessage = async ({
  sessionId,
  senderId,
  content,
  file = null,
  fileUrl = '',
}) => {
  const cleanContent = String(content || '').trim();
  const attachment = buildAttachmentPayload(file, fileUrl);

  if (!cleanContent && !attachment) {
    throw new Error('Message content or attachment is required');
  }

  const { session, isUser, isMentor, senderRole } =
    await getSessionForParticipant(sessionId, senderId);

  if (session.method !== 'chat') {
    throw new Error('This session is not a chat session');
  }

  if (!['started', 'active'].includes(session.status)) {
    throw new Error('Chat is only available for started or active sessions');
  }

  if (
    session.noShowDeadline &&
    !session.userJoinedAt &&
    new Date() > new Date(session.noShowDeadline) &&
    isUser
  ) {
    throw new Error('The join window has expired');
  }

  let sessionBecameActiveNow = false;
  let userJoinedNow = false;

  // If mentor sends the first message after session start, keep status "started"
  // If user sends first message/join action, mark the user as joined and session active
  if (isUser && !session.userJoinedAt) {
    session.userJoinedAt = new Date();
    session.status = 'active';
    userJoinedNow = true;
    sessionBecameActiveNow = true;
    await session.save();
  }

  const messageType = inferMessageType({
    content: cleanContent,
    attachment,
  });

  const message = await ChatMessage.create({
    sessionId,
    senderId,
    senderRole,
    messageType,
    content: cleanContent,
    attachment,
  });

  const recipientUserId = isMentor ? session.userId : session.mentorUserId;

  await notificationService.createNotification({
    userId: recipientUserId,
    type: 'chat_message_received',
    title: 'New chat message',
    message:
      messageType === 'text'
        ? 'You received a new message in your mentor session.'
        : 'You received a new attachment in your mentor session.',
    data: {
      sessionId: session._id,
      messageId: message._id,
      messageType,
    },
  });

  if (userJoinedNow) {
    await notificationService.createNotification({
      userId: session.mentorUserId,
      type: 'user_joined_session',
      title: 'User joined session',
      message: 'The user joined the session and sent the first message.',
      data: {
        sessionId: session._id,
        userJoinedAt: session.userJoinedAt,
      },
    });
  }

  return {
    sessionBecameActiveNow,
    userJoinedNow,
    session,
    message,
  };
};

module.exports = {
  getChatMessages,
  createMessage,
};