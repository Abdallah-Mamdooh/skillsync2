const express = require('express');
const router = express.Router();

const authMiddleware = require('../../middlewares/auth.middleware');
const roleMiddleware = require('../../middlewares/role.middleware');
const validate = require('../../middlewares/validate.middleware');
const { complaintAttachmentUpload } = require('../../middlewares/upload.middleware');
const controller = require('./complaint.controller');

// user side
router.post(
  '/',
  authMiddleware,
  complaintAttachmentUpload.array('files', 5),
  validate(['entityType', 'category', 'title', 'description']),
  controller.createComplaint
);

router.get(
  '/me',
  authMiddleware,
  controller.getMyComplaints
);

router.get(
  '/me/:complaintId',
  authMiddleware,
  controller.getMyComplaintById
);

// admin side
router.get(
  '/admin',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getAllComplaints
);

router.get(
  '/admin/:complaintId',
  authMiddleware,
  roleMiddleware('admin'),
  controller.getComplaintByIdAdmin
);

router.patch(
  '/admin/:complaintId/status',
  authMiddleware,
  roleMiddleware('admin'),
  validate(['status']),
  controller.updateComplaintStatus
);

module.exports = router;