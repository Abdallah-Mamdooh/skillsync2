const bcrypt = require('bcryptjs');
const crypto = require('crypto');

const User = require('./user.model');
const jwtUtils = require('../../utils/jwt');
const sendEmail = require('../../utils/sendEmail');

const normalizeEmail = (email) => {
  return String(email || '').trim().toLowerCase();
};

const normalizePhoneNumber = (phoneNumber) => {
  return String(phoneNumber || '').trim().replace(/\s+/g, '');
};

const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
  return emailRegex.test(email);
};

const isValidEgyptianPhoneNumber = (phoneNumber) => {
  // Accepts:
  // 01012345678
  // 01112345678
  // 01212345678
  // 01512345678
  // +201012345678
  // 00201012345678
  const phoneRegex = /^(01[0125][0-9]{8}|\+201[0125][0-9]{8}|00201[0125][0-9]{8})$/;
  return phoneRegex.test(phoneNumber);
};

const isStrongPassword = (password) => {
  // Minimum 8 chars, at least one letter and one number
  const passwordRegex = /^(?=.*[A-Za-z])(?=.*\d).{8,}$/;
  return passwordRegex.test(password);
};

const isValidFullName = (fullName) => {
  const name = String(fullName || '').trim();

  // Allows Arabic and English letters, spaces, apostrophe, dash.
  // Must be at least 2 characters.
  const nameRegex = /^[A-Za-z\u0600-\u06FF\s'-]{2,}$/;

  return nameRegex.test(name);
};

const isValidLinkedInUrl = (url) => {
  const value = String(url || '').trim();

  return /^https?:\/\/(www\.)?linkedin\.com\/.+/i.test(value);
};

const validateSignupData = ({
  fullName,
  email,
  phoneNumber,
  password,
  role,
  cvUrl,
  linkedinUrl,
}) => {
  if (!fullName || !email || !password || !role) {
    throw new Error('Full name, email, password, and account type are required');
  }

  if (!['user', 'mentor'].includes(role)) {
    throw new Error('Invalid account type. Only user and mentor registration are allowed');
  }

  if (!isValidFullName(fullName)) {
    throw new Error('Full name must contain only letters and spaces');
  }

  if (!isValidEmail(email)) {
    throw new Error('Please enter a valid email address');
  }

  if (!phoneNumber) {
    throw new Error('Phone number is required');
  }

  if (!isValidEgyptianPhoneNumber(phoneNumber)) {
    throw new Error('Please enter a valid Egyptian phone number');
  }

  if (!isStrongPassword(password)) {
    throw new Error('Password must be at least 8 characters and contain at least one letter and one number');
  }

  if (role === 'mentor') {
    if (!cvUrl) {
      throw new Error('Mentors must provide a CV');
    }

    if (!linkedinUrl) {
      throw new Error('Mentors must provide a LinkedIn profile');
    }

    if (!isValidLinkedInUrl(linkedinUrl)) {
      throw new Error('Please enter a valid LinkedIn profile URL');
    }
  }
};

const signup = async (data) => {
  const {
    fullName,
    phoneNumber,
    password,
    role,
    cvUrl,
    linkedinUrl,
    additionalInfo,
  } = data;

  const email = normalizeEmail(data.email);
  const normalizedPhoneNumber = normalizePhoneNumber(phoneNumber);

  validateSignupData({
    fullName,
    email,
    phoneNumber: normalizedPhoneNumber,
    password,
    role,
    cvUrl,
    linkedinUrl,
  });

  const existingUser = await User.findOne({
    $or: [
      { email },
      { phoneNumber: normalizedPhoneNumber },
    ],
  });

  if (existingUser) {
    throw new Error('Email or phone number already in use');
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  const user = await User.create({
    fullName: fullName.trim(),
    email,
    phoneNumber: normalizedPhoneNumber,
    password: hashedPassword,
    role,
    authProvider: 'local',
    cvUrl: role === 'mentor' ? cvUrl : (cvUrl || ''),
    mentorProfile: role === 'mentor'
      ? {
          linkedinUrl: linkedinUrl.trim(),
          additionalInfo,
        }
      : undefined,
  });

  const userObject = user.toObject();
  delete userObject.password;

  return {
    success: true,
    message: 'Signup successful',
    data: userObject,
  };
};

const login = async (data) => {
  const email = normalizeEmail(data.email);
  const { password } = data;

  if (!email || !password) {
    throw new Error('Email and password are required');
  }

  if (!isValidEmail(email)) {
    throw new Error('Please enter a valid email address');
  }

  const user = await User.findOne({ email }).select('+password');

  if (!user) {
    throw new Error('Invalid email or password');
  }

  if (!user.password) {
    throw new Error('This account uses Google login. Please continue with Google.');
  }

  const isMatch = await bcrypt.compare(password, user.password);

  if (!isMatch) {
    throw new Error('Invalid email or password');
  }

  const token = jwtUtils.generateToken(user);

  const userObject = user.toObject();
  delete userObject.password;

  return {
    success: true,
    message: 'Login successful',
    data: {
      token,
      user: userObject,
    },
  };
};

const googleLogin = async (emailInput) => {
  const email = normalizeEmail(emailInput);

  if (!email) {
    throw new Error('Email is required');
  }

  if (!isValidEmail(email)) {
    throw new Error('Please enter a valid email address');
  }

  const user = await User.findOne({ email });

  if (!user) {
    throw new Error('Account not found. Please sign up first.');
  }

  const token = jwtUtils.generateToken(user);

  return {
    success: true,
    message: 'Google login successful',
    data: {
      token,
      user,
    },
  };
};

const forgotPassword = async (emailInput) => {
  const email = normalizeEmail(emailInput);

  if (!email) {
    throw new Error('Email is required');
  }

  if (!isValidEmail(email)) {
    throw new Error('Please enter a valid email address');
  }

  const user = await User.findOne({ email });

  if (!user) {
    throw new Error('No user found with this email');
  }

  const resetToken = crypto.randomBytes(32).toString('hex');

  const hashedToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');

  user.passwordResetToken = hashedToken;
  user.passwordResetExpires = Date.now() + 10 * 60 * 1000;

  await user.save();

  const resetBaseUrl =
    process.env.PASSWORD_RESET_BASE_URL ||
    process.env.BACKEND_PUBLIC_URL ||
    'http://localhost:5000';

  const resetUrl = `${resetBaseUrl.replace(/\/$/, '')}/reset-password/${resetToken}`;

  await sendEmail(
    user.email,
    'Password Reset',
    `
    ### Password Reset

    Click below to reset your password:

    ${resetUrl}

    This link will expire in 10 minutes.
    `
  );

  return {
    success: true,
    message: 'Reset link sent to email',
  };
};

const resetPassword = async (token, newPassword) => {
  if (!newPassword) {
    throw new Error('New password is required');
  }

  if (!isStrongPassword(newPassword)) {
    throw new Error('Password must be at least 8 characters and contain at least one letter and one number');
  }

  const hashedToken = crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');

  const user = await User.findOne({
    passwordResetToken: hashedToken,
    passwordResetExpires: { $gt: Date.now() },
  }).select('+password');

  if (!user) {
    throw new Error('Invalid or expired token');
  }

  const hashedPassword = await bcrypt.hash(newPassword, 10);

  user.password = hashedPassword;
  user.authProvider = 'local';
  user.passwordResetToken = undefined;
  user.passwordResetExpires = undefined;

  await user.save();

  return {
    success: true,
    message: 'Password reset successful',
  };
};

const changePassword = async (userId, oldPassword, newPassword) => {
  if (!oldPassword || !newPassword) {
    throw new Error('Old password and new password are required');
  }

  if (!isStrongPassword(newPassword)) {
    throw new Error('Password must be at least 8 characters and contain at least one letter and one number');
  }

  const user = await User.findById(userId).select('+password');

  if (!user) {
    throw new Error('User not found');
  }

  if (!user.password) {
    throw new Error('This account uses Google login and has no local password yet.');
  }

  const isMatch = await bcrypt.compare(oldPassword, user.password);

  if (!isMatch) {
    throw new Error('Old password incorrect');
  }

  user.password = await bcrypt.hash(newPassword, 10);

  await user.save();

  return {
    success: true,
    message: 'Password changed successfully',
  };
};

module.exports = {
  signup,
  login,
  forgotPassword,
  resetPassword,
  changePassword,
  googleLogin,
};