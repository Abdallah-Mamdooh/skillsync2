const updateProfile = async (userId, data) => {
  const user = await User.findById(userId);

  if (!user) {
    throw new Error('User not found');
  }

  // Allowed updates for everyone
  if (data.fullName !== undefined) {
    user.fullName = data.fullName;
  }

  if (data.phoneNumber !== undefined) {
    user.phoneNumber = data.phoneNumber;
  }

  if (data.skills !== undefined) {
    user.skills = data.skills;
  }

  if (data.cvUrl !== undefined) {
    user.cvUrl = data.cvUrl;
  }

  // Mentor-specific updates
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

  const updatedUser = user.toObject();
  delete updatedUser.password;

  return {
    success: true,
    message: 'Profile updated successfully',
    data: updatedUser
  };
};
