const express = require('express');
const router = express.Router();

const uploadController = require('./upload.controller');
const {
  imageUpload,
  cvUpload,
  documentUpload,
  eventCoverUpload,
} = require('../../middlewares/upload.middleware');

router.post(
  '/profile-image',
  imageUpload.single('file'),
  uploadController.uploadProfileImage
);

router.post(
  '/cv',
  cvUpload.single('file'),
  uploadController.uploadCV
);

router.post(
  '/document',
  documentUpload.single('file'),
  uploadController.uploadDocument
);

router.post(
  '/event-cover',
  eventCoverUpload.single('file'),
  uploadController.uploadEventCover
);

module.exports = router;