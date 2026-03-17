const multer = require('multer');
const path = require('path');
const fs = require('fs');

function ensureDir(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

function createUploader(folderName, allowedMimeTypes = []) {
  const uploadPath = path.join(process.cwd(), 'uploads', folderName);
  ensureDir(uploadPath);

  const storage = multer.diskStorage({
    destination: (req, file, cb) => {
      cb(null, uploadPath);
    },
    filename: (req, file, cb) => {
      const ext = path.extname(file.originalname);
      const baseName = path
        .basename(file.originalname, ext)
        .replace(/[^a-zA-Z0-9-_]/g, '_');

      cb(null, `${Date.now()}-${baseName}${ext}`);
    },
  });

  const fileFilter = (req, file, cb) => {
    if (
      allowedMimeTypes.length > 0 &&
      !allowedMimeTypes.includes(file.mimetype)
    ) {
      return cb(new Error('Invalid file type'), false);
    }
    cb(null, true);
  };

  return multer({
    storage,
    fileFilter,
    limits: {
      fileSize: 10 * 1024 * 1024, // 10 MB
    },
  });
}

const imageUpload = createUploader('profile-images', [
  'image/jpeg',
  'image/png',
  'image/webp',
]);

const cvUpload = createUploader('cvs', [
  'application/pdf',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
]);

const documentUpload = createUploader('documents', [
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/webp',
]);

const eventCoverUpload = createUploader('events', [
  'image/jpeg',
  'image/png',
  'image/webp',
]);

const chatAttachmentUpload = createUploader('chat-attachments', [
  'image/jpeg',
  'image/png',
  'image/webp',
  'application/pdf',
  'text/plain',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
]);

module.exports = {
  imageUpload,
  cvUpload,
  documentUpload,
  eventCoverUpload,
  chatAttachmentUpload,
};