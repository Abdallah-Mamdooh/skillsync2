const bcrypt = require('bcryptjs');
const crypto = require('crypto');

const User = require('./user.model');
const jwtUtils = require('../../utils/jwt');
const sendEmail = require('../../utils/sendEmail');
const { encryptText } = require('../../utils/encryption');

const signup = async (data, file) => {
  const {
    fullName,
    email,
    phoneNumber,
    password,
    role,
    linkedinUrl,
    additionalInfo,
    proposedHourlyRate,
    payoutAccountInfo,
  } = data;

  if (!fullName || !email || !password || !role) {
    throw new Error('fullName, email, password, and role are required');
  }

  if (role !== 'admin' && !phoneNumber) {
    throw new Error('Phone number is required');
  }

  const cvUrl = file ? `/uploads/cvs/${file.filename}` : '';

  if (role === 'mentor' && !file) {
    throw new Error('Mentors must upload a CV');
  }

  const orConditions = [{ email }];

  if (phoneNumber) {
    orConditions.push({ phoneNumber });
  }

  const existingUser = await User.findOne({ $or: orConditions });

  if (existingUser) {
    throw new Error('Email or phone number already in use');
  }

  if (role === 'mentor') {
    if (!linkedinUrl) {
      throw new Error('Mentors must provide LinkedIn profile');
    }

    if (
      proposedHourlyRate === undefined ||
      proposedHourlyRate === null ||
      Number(proposedHourlyRate) <= 0
    ) {
      throw new Error('Mentors must provide a valid proposed hourly rate');
    }

    if (!payoutAccountInfo || !payoutAccountInfo.trim()) {
      throw new Error('Mentors must provide payout account information');
    }
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  const user = await User.create({
    fullName,
    email,
    phoneNumber,
    password: hashedPassword,
    role,
    authProvider: 'local',
    cvUrl,
    mentorProfile:
      role === 'mentor'
        ? {
            linkedinUrl,
            additionalInfo,
            proposedHourlyRate: Number(proposedHourlyRate),
            payoutAccountInfo: encryptText(payoutAccountInfo),
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
  const { email, password } = data;

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
    data: { token, user: userObject },
  };
};

const googleLogin = async (email) => {
  if (!email) {
    throw new Error('Email is required');
  }

  const user = await User.findOne({ email });

  if (!user) {
    throw new Error('Account not found. Please sign up first.');
  }

  const token = jwtUtils.generateToken(user);

  return {
    success: true,
    message: 'Google login successful',
    data: { token, user },
  };
};

const forgotPassword = async (email) => {
  if (!email) {
    throw new Error('Email is required');
  }

  const user = await User.findOne({ email });

  if (!user) {
    return {
      success: true,
      message: 'If this email exists, a reset link has been sent.',
    };
  }

  const resetToken = crypto.randomBytes(32).toString('hex');

  const hashedToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');

  user.passwordResetToken = hashedToken;
  user.passwordResetExpires = Date.now() + 10 * 60 * 1000;

  await user.save();

  const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
  const resetUrl = `${frontendUrl}/reset-password/${resetToken}`;

  await sendEmail(
    user.email,
    'SkillSync Password Reset',
    `
Hello ${user.fullName || ''},

You requested to reset your SkillSync password.

Click the link below to set a new password:
${resetUrl}

This link will expire in 10 minutes.

If you did not request this, please ignore this email.
    `
  );

  return {
    success: true,
    message: 'If this email exists, a reset link has been sent.',
  };
};

const resetPassword = async (token, newPassword) => {
  if (!token) {
    throw new Error('Reset token is required');
  }

  if (!newPassword || newPassword.length < 8) {
    throw new Error('Password must be at least 8 characters');
  }

  const hashedToken = crypto.createHash('sha256').update(token).digest('hex');

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