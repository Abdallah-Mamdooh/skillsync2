const app = require('./src/app');
const connectDB = require('./src/config/db');
const passport = require('./src/config/passport');
const session = require('express-session');
connectDB();

const PORT = process.env.PORT || 5000;

app.use(passport.initialize());
app.use(passport.session());
app.listen(PORT, () => {
  console.log(`SkillSync API running on port ${PORT}`);
});


app.use(
  session({
    secret: 'googleauthsecret',
    resave: false,
    saveUninitialized: false
  })
);


