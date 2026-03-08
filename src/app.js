const express = require('express');
const cors = require('cors');
const morgan = require('morgan');

const routes = require('./routes');
const notFound = require('./middlewares/notFound.middleware');
const errorHandler = require('./middlewares/error.middleware');

const profileRoutes = require('./modules/profile/profile.routes');
const assessmentRoutes = require('./modules/assessment/assessment.routes');
const roadmapRoutes = require('./modules/roadmap/roadmap.routes');
const mentorRoutes = require('./modules/mentor/mentor.routes');
const mentorSessionRoutes = require('./modules/mentor/mentorSession.routes');
const sessionFeedbackRoutes = require('./modules/mentor/sessionFeedback.routes');
const paymentRoutes = require('./modules/payment/payment.routes');
const chatRoutes = require('./modules/mentor/chat.routes');
const groupEventRoutes = require('./modules/events/groupEvent.routes');

const app = express();

// global middleware first
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// feature routes
app.use('/api/assessment', assessmentRoutes);
app.use('/api/roadmap', roadmapRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/mentors', mentorRoutes);
app.use('/api/mentor-sessions', mentorSessionRoutes);
app.use('/api/session-feedback', sessionFeedbackRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/events', groupEventRoutes);

// existing shared routes
app.use('/api', routes);

// error handling last
app.use(notFound);
app.use(errorHandler);

module.exports = app;