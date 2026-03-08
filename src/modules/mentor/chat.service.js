const ChatMessage = require('./chatMessage.model');
const MentorSession = require('./mentorSession.model');

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
    senderRole: isMentor ? 'mentor' : 'user',
  };
};

const getChatMessages = async (sessionId, currentUserId) => {
  await getSessionForParticipant(sessionId, currentUserId);

  return ChatMessage.find({ sessionId }).sort({ createdAt: 1 });
};

const createMessage = async ({ sessionId, senderId, content }) => {
  if (!content || !String(content).trim()) {
    throw new Error('Message content is required');
  }

  const { session, senderRole } = await getSessionForParticipant(sessionId, senderId);

  if (session.method !== 'chat') {
    throw new Error('This session is not a chat session');
  }

  if (!['accepted', 'active'].includes(session.status)) {
    throw new Error('Chat is only available for accepted or active sessions');
  }

  // auto-start session on first message
  if (session.status === 'accepted' && !session.startedAt) {
    session.status = 'active';
    session.startedAt = new Date();
    await session.save();
  }

  const message = await ChatMessage.create({
    sessionId,
    senderId,
    senderRole,
    messageType: 'text',
    content: String(content).trim(),
  });

  return {
    sessionStartedNow: session.status === 'active' && !!session.startedAt,
    session,
    message,
  };
};

module.exports = {
  getChatMessages,
  createMessage,
};