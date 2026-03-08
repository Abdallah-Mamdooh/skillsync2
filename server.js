const app = require('./src/app');
const http = require('http');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const User = require('./src/modules/auth/user.model');
const chatService = require('./src/modules/mentor/chat.service');
const connectDB = require('./src/config/db');
const passport = require('./src/config/passport');
const session = require('express-session');
connectDB();
const mentorRoutes = require('./src/modules/mentor/mentor.routes');
const PORT = process.env.PORT || 5000;
const mentorSessionRoutes = require('./src/modules/mentor/mentorSession.routes');
const paymentRoutes = require('./src/modules/payment/payment.routes');
const sessionFeedbackRoutes = require('./src/modules/mentor/sessionFeedback.routes');
const chatRoutes = require('./src/modules/mentor/chat.routes');
const groupEventRoutes = require('./src/modules/events/groupEvent.routes');


const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
  },
});

io.on('connection', (socket) => {
  socket.on('join_session_room', async ({ sessionId, token }) => {
    try {
      const user = await getUserFromSocket(socket, token);

      // validate access to this session
      await chatService.getChatMessages(sessionId, user._id);

      const room = `session_${sessionId}`;
      socket.join(room);

      socket.emit('joined_session_room', {
        sessionId,
        room,
      });
    } catch (err) {
      socket.emit('chat_error', { message: err.message });
    }
  });

  socket.on('send_session_message', async ({ sessionId, content, token }) => {
    try {
      const user = await getUserFromSocket(socket, token);

      const result = await chatService.createMessage({
        sessionId,
        senderId: user._id,
        content,
      });

      const room = `session_${sessionId}`;

      io.to(room).emit('receive_session_message', {
        sessionId,
        message: result.message,
      });

      if (result.sessionStartedNow) {
        io.to(room).emit('session_started', {
          sessionId,
          startedAt: result.session.startedAt,
          status: result.session.status,
        });
      }
    } catch (err) {
      socket.emit('chat_error', { message: err.message });
    }
  });
});

async function getUserFromSocket(socket, eventToken = null) {
  const authHeader = socket.handshake.headers?.authorization || '';
  const headerToken = authHeader.startsWith('Bearer ')
    ? authHeader.replace('Bearer ', '')
    : null;

  const token =
    eventToken ||
    socket.handshake.auth?.token ||
    headerToken;

  if (!token) {
    throw new Error('Socket auth token missing');
  }

  const decoded = jwt.verify(token, process.env.JWT_SECRET);
  const userId = decoded.id || decoded._id;

  const user = await User.findById(userId);
  if (!user) {
    throw new Error('Socket user not found');
  }

  return user;
}

app.use('/api/chat', chatRoutes);
app.use('/api/events', groupEventRoutes);
app.use('/api/session-feedback', sessionFeedbackRoutes);
app.use('/api/mentor-sessions', mentorSessionRoutes);
app.use('/api/payments', paymentRoutes);
app.use(passport.initialize());
app.use(passport.session());
server.listen(PORT, () => {
  console.log(`SkillSync API running on port ${PORT}`);
});

app.use('/api/mentors', mentorRoutes);
app.use(
  session({
    secret: 'googleauthsecret',
    resave: false,
    saveUninitialized: false
  })
);


