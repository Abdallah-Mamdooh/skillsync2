const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const controller = require('./reminder.controller');

// MVP manual trigger
router.post('/run', authMiddleware, controller.runReminderChecks);

module.exports = router;