const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const controller = require('./dashboard.controller');

router.get('/user', authMiddleware, roleMiddleware('user'), controller.getUserDashboard);
router.get('/mentor', authMiddleware, roleMiddleware('mentor'), controller.getMentorDashboard);

module.exports = router;