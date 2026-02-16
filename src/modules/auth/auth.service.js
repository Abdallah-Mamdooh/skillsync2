const bcrypt = require('bcryptjs');
const User = require('./user.model');
const crypto = require('crypto');
const jwtUtils = require('../../utils/jwt');
const sendEmail = require('../../utils/sendEmail');

const signup = async (data) => {
  const {
    fullName,
    email,
    phoneNumber,
    password,
    role,
    cvUrl,
    linkedinUrl,
    additionalInfo
  } = data;

  const existingUser = await User.findOne({
    $or: [{ email }, { phoneNumber }]
  });

  if (existingUser) {
    throw new Error('Email or phone number already in use');
  }

  if (role === 'mentor') {
    if (!cvUrl || !linkedinUrl) {
      throw new Error('Mentors must provide CV and LinkedIn profile');
    }
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  const user = await User.create({
    fullName,
    email,
    phoneNumber,
    password: hashedPassword,
    role,
    mentorProfile:
      role === 'mentor'
        ? {
            cvUrl,
            linkedinUrl,
            additionalInfo
          }
        : undefined
  });

  const userObject = user.toObject();
  delete userObject.password;

  return {
    success: true,
    message: 'Signup successful',
    data: userObject
  };
};

const login = async (data) => {
  const { email, password } = data;

  const user = await User.findOne({ email }).select('+password');

  if (!user) {
    throw new Error('Invalid email or password');
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
      user: userObject
    }
  };
};

const googleLogin = async (email) => {
  if (!email) {
    throw new Error("Email is required");
  }

  // Find user by email
  const user = await User.findOne({ email });

  if (!user) {
    throw new Error("Account not found. Please sign up first.");
  }

  // Generate token
  const token = jwtUtils.generateToken(user);

  return {
    success: true,
    message: "Google login successful",
    data: {
      token,
      user
    }
  };
};


const forgotPassword = async (email) => {
  if (!email) {
    throw new Error('Email is required');
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

  const resetUrl = `http://localhost:3000/reset-password/${resetToken}`;

  await sendEmail(
    user.email,
    'Password Reset',
    `
      <h3>Password Reset</h3>
      <p>Click below to reset your password:</p>
      <a href="${resetUrl}">${resetUrl}</a>
    `
  );

  return {
    success: true,
    message: 'Reset link sent to email'
  };
};

const resetPassword = async (token, newPassword) => {
  const hashedToken = crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');

  const user = await User.findOne({
    passwordResetToken: hashedToken,
    passwordResetExpires: { $gt: Date.now() }
  });

  if (!user) {
    throw new Error('Invalid or expired token');
  }

  const hashedPassword = await bcrypt.hash(newPassword, 10);

  user.password = hashedPassword;
  user.passwordResetToken = undefined;
  user.passwordResetExpires = undefined;

  await user.save();

  return {
    success: true,
    message: 'Password reset successful'
  };
};

const changePassword = async (userId, oldPassword, newPassword) => {
  const user = await User.findById(userId).select('+password');

  if (!user) {
    throw new Error('User not found');
  }

  const isMatch = await bcrypt.compare(oldPassword, user.password);

  if (!isMatch) {
    throw new Error('Old password incorrect');
  }

  user.password = await bcrypt.hash(newPassword, 10);
  await user.save();

  return {
    success: true,
    message: 'Password changed successfully'
  };
};

module.exports = {
  signup,
  login,
  forgotPassword,
  resetPassword,
  changePassword,
  googleLogin  

};
