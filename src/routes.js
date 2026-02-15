const express = require('express');
const { ApiResponse } = require('./utils/ApiResponse');

const authRoutes = require('./modules/auth/auth.routes');

const router = express.Router();

router.get('/health', (req, res) => {
  return res.status(200).json(
    new ApiResponse(true, 'SkillSync API is running', {
      timestamp: new Date()
    })
  );
});

router.use('/auth', authRoutes);

module.exports = router;
