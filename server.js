require('dotenv').config();

const http = require('http');
const session = require('express-session');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');

const app = require('./src/app');
const connectDB = require('./src/config/db');
const passport = require('./src/config/passport');
const User = require('./src/modules/auth/user.model');
const chatService = require('./src/modules/mentor/chat.service');
const reminderRoutes = require('./src/modules/notification/reminder.routes');
const { startReminderCron } = require('./src/modules/notification/reminder.cron');
const adminRoutes = require('./src/modules/admin/admin.routes');
const dashboardRoutes = require('./src/modules/dashboard/dashboard.routes');
connectDB();

const PORT = process.env.PORT || 5000;
app.use('/api/admin', adminRoutes);
app.use('/api/dashboard', dashboardRoutes);
// session + passport middleware
app.use(
  session({
    secret: process.env.SESSION_SECRET || 'googleauthsecret',
    resave: false,
    saveUninitialized: false,
  })
);
app.use(passport.initialize());
app.use(passport.session());
app.use('/api/reminders', reminderRoutes);
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
  },
});

async function getUserFromSocket(socket, eventToken = null) {
  const authHeader = socket.handshake.headers?.authorization || '';
  const headerToken = authHeader.startsWith('Bearer ')
    ? authHeader.replace('Bearer ', '')
    : null;

  const token = eventToken || socket.handshake.auth?.token || headerToken;

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

io.on('connection', (socket) => {
  socket.on('join_session_room', async ({ sessionId, token }) => {
    try {
      const user = await getUserFromSocket(socket, token);

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
startReminderCron();

server.listen(PORT, () => {
  console.log(`SkillSync API running on port ${PORT}`);
});