const app = require('./src/app');
const connectDB = require('./src/config/db');
const passport = require('./src/config/passport');
const session = require('express-session');
connectDB();
const mentorRoutes = require('./src/modules/mentor/mentor.routes');
const PORT = process.env.PORT || 5000;
const mentorSessionRoutes = require('./src/modules/mentor/mentorSession.routes');
const paymentRoutes = require('./src/modules/payment/payment.routes');
const sessionFeedbackRoutes = require('./src/modules/mentor/sessionFeedback.routes');




app.use('/api/session-feedback', sessionFeedbackRoutes);
app.use('/api/mentor-sessions', mentorSessionRoutes);
app.use('/api/payments', paymentRoutes);
app.use(passport.initialize());
app.use(passport.session());
app.listen(PORT, () => {
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


