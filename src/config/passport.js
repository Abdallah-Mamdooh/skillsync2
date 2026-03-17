const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;

const User = require('../modules/auth/user.model');
const jwtUtils = require('../utils/jwt');

passport.use(
  new GoogleStrategy(
    {
      clientID: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
      callbackURL: '/api/auth/google/callback',
    },
    async (accessToken, refreshToken, profile, done) => {
      try {
        const email = profile?.emails?.[0]?.value;
        if (!email) {
          return done(new Error('Google account email not available'), null);
        }

        let user = await User.findOne({
          $or: [{ googleId: profile.id }, { email }],
        });

        if (!user) {
          user = await User.create({
            fullName: profile.displayName,
            email,
            role: 'user',
            authProvider: 'google',
            googleId: profile.id,
          });
        } else {
          let shouldSave = false;

          if (!user.googleId) {
            user.googleId = profile.id;
            shouldSave = true;
          }

          if (!user.authProvider) {
            user.authProvider = 'google';
            shouldSave = true;
          }

          if (shouldSave) {
            await user.save();
          }
        }

        const token = jwtUtils.generateToken(user);
        return done(null, { user, token });
      } catch (error) {
        return done(error, null);
      }
    }
  )
);

passport.serializeUser((payload, done) => {
  done(null, payload);
});

passport.deserializeUser((payload, done) => {
  done(null, payload);
});

module.exports = passport;