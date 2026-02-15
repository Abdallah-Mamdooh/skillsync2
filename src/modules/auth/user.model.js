const mongoose = require('mongoose');


const userSchema = new mongoose.Schema(
 
  {
    fullName: {
      type: String,
      required: true,
      trim: true
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true
    },

    phoneNumber: {
      type: String,
      required: true,
      unique: true,
      trim: true
    },

    password: {
      passwordResetToken: String,
      passwordResetExpires: Date,
      type: String,
      required: true,
      select: false
    },
    passwordResetToken: {
  type: String
},
passwordResetExpires: {
  type: Date
},


    role: {
      type: String,
      enum: ['user', 'mentor'],
      required: true
    },

    /* Mentor-only fields */
    mentorProfile: {
      cvUrl: {
        type: String
      },
      linkedinUrl: {
        type: String
      },
      additionalInfo: {
        type: String
      },
      isVerified: {
        type: Boolean,
        default: false
      }
    },

    isActive: {
      type: Boolean,
      default: true
    }
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model('User', userSchema);
