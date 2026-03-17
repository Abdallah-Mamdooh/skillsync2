const User = require('../auth/user.model');

const sanitizeUser = (userDoc) => {
  const user = userDoc.toObject ? userDoc.toObject() : { ...userDoc };
  delete user.password;
  delete user.passwordResetToken;
  delete user.passwordResetExpires;
  return user;
};

const getProfile = async (userId) => {
  const user = await User.findById(userId).select('-password');

  if (!user) {
    throw new Error('User not found');
  }

  return {
    success: true,
    message: 'Profile fetched successfully',
    data: sanitizeUser(user),
  };
};

const updateProfile = async (userId, data) => {
  const user = await User.findById(userId).select('-password');

  if (!user) {
    throw new Error('User not found');
  }

  // common profile fields
  if (data.fullName !== undefined) user.fullName = data.fullName;
  if (data.phoneNumber !== undefined) user.phoneNumber = data.phoneNumber;
  if (data.profileImageUrl !== undefined) user.profileImageUrl = data.profileImageUrl;
  if (data.bio !== undefined) user.bio = data.bio;
  if (data.cvUrl !== undefined) user.cvUrl = data.cvUrl;

  if (data.skills !== undefined) {
    user.skills = Array.isArray(data.skills) ? data.skills : [];
  }

  if (data.selectedInterests !== undefined) {
    user.selectedInterests = Array.isArray(data.selectedInterests)
      ? data.selectedInterests.slice(0, 3)
      : [];
  }

  // mentor-only fields
  if (user.role === 'mentor') {
    if (!user.mentorProfile) {
      user.mentorProfile = {};
    }

    if (data.linkedinUrl !== undefined) {
      user.mentorProfile.linkedinUrl = data.linkedinUrl;
    }

    if (data.additionalInfo !== undefined) {
      user.mentorProfile.additionalInfo = data.additionalInfo;
    }
  }

  await user.save();

  return {
    success: true,
    message: 'Profile updated successfully',
    data: sanitizeUser(user),
  };
};

module.exports = {
  getProfile,
  updateProfile,
};