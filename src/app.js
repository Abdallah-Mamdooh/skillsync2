const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
const session = require('express-session');

const passport = require('./config/passport');
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
const uploadRoutes = require('./modules/upload/upload.routes');
const notificationRoutes = require('./modules/notification/notification.routes');
const reminderRoutes = require('./modules/notification/reminder.routes');
const adminRoutes = require('./modules/admin/admin.routes');
const dashboardRoutes = require('./modules/dashboard/dashboard.routes');
const complaintRoutes = require('./modules/complaint/complaint.routes');
const supportRoutes = require('./modules/support/support.routes');
const settingsRoutes = require('./modules/settings/settings.routes');
const cvAnalysisRoutes = require('./modules/cvAnalysis/cvAnalysis.routes');
const dashboardCompatRoutes = require('./modules/dashboardCompat/dashboardCompat.routes');
const payoutRoutes = require('./modules/payment/payout.routes');
const app = express();

// global middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// session + passport MUST be before routes
app.use(
  session({
    secret: process.env.SESSION_SECRET || 'googleauthsecret',
    resave: false,
    saveUninitialized: false,
  })
);

app.use(passport.initialize());
app.use(passport.session());

// static uploads
app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));

// feature routes
app.use('/api/uploads', uploadRoutes);
app.use('/api/assessment', assessmentRoutes);
app.use('/api/roadmap', roadmapRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/mentors', mentorRoutes);
app.use('/api/mentor-sessions', mentorSessionRoutes);
app.use('/api/session-feedback', sessionFeedbackRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/events', groupEventRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/reminders', reminderRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/complaints', complaintRoutes);
app.use('/api/support', supportRoutes);
app.use('/api/settings', settingsRoutes);
app.use('/api/cv-analysis', cvAnalysisRoutes);
app.use('/api', dashboardCompatRoutes);

// shared routes
app.use('/api', routes);

// error handling LAST
app.use(notFound);
app.use(errorHandler);

app.use('/api/payouts', payoutRoutes);

module.exports = app;