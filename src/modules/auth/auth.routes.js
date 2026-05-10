const express = require('express');
const authController = require('./auth.controller');
const router = express.Router();
const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const { cvUpload } = require('../../middlewares/upload.middleware');

router.post('/signup', cvUpload.single('cv'), authController.signup);
router.post('/login', authController.login);
router.post('/google-login', authController.googleLogin);
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password/:token', authController.resetPassword);

router.get('/me', authMiddleware, (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Authenticated user',
    data: req.user
  });
});

// Mentor-only test
router.get(
  '/mentor-only',
  authMiddleware,
  roleMiddleware('mentor'),
  (req, res) => {
    res.status(200).json({
      success: true,
      message: 'Mentor access granted'
    });
  }
);

// User-only test
router.get(
  '/user-only',
  authMiddleware,
  roleMiddleware('user'),
  (req, res) => {
    res.status(200).json({
      success: true,
      message: 'User access granted'
    });
  }
);

router.post(
  '/change-password',
  authMiddleware,
  authController.changePassword
);
const passport = require('passport');

// Start Google login
router.get(
  '/google',
  passport.authenticate('google', { scope: ['profile', 'email'] })
);

// Google callback
router.get(
  '/google/callback',
  passport.authenticate('google', { session: false }),
  (req, res) => {
    res.json({
      success: true,
      token: req.user.token,
      user: req.user.user
    });
  }
);


module.exports = router;
