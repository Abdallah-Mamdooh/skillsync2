const express = require('express');
const router = express.Router();
const authMiddleware = require('../../middlewares/auth.middleware');
const profileController = require('./profile.controller');

router.get('/', authMiddleware, profileController.getProfile);
router.patch('/', authMiddleware, profileController.updateProfile);

module.exports = router;
