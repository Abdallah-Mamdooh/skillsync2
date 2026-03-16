const path = require('path');

function buildFileUrl(req, filePath) {
  const baseUrl = `${req.protocol}://${req.get('host')}`;
  return `${baseUrl}/${filePath.replace(/\\/g, '/')}`;
}

exports.uploadProfileImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image uploaded',
      });
    }

    const filePath = path.join('uploads', 'profile-images', req.file.filename);

    return res.status(200).json({
      success: true,
      url: buildFileUrl(req, filePath),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.uploadCV = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No CV uploaded',
      });
    }

    const filePath = path.join('uploads', 'cvs', req.file.filename);

    return res.status(200).json({
      success: true,
      url: buildFileUrl(req, filePath),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.uploadDocument = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No document uploaded',
      });
    }

    const filePath = path.join('uploads', 'documents', req.file.filename);

    return res.status(200).json({
      success: true,
      url: buildFileUrl(req, filePath),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

exports.uploadEventCover = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image uploaded',
      });
    }

    const filePath = path.join('uploads', 'events', req.file.filename);

    return res.status(200).json({
      success: true,
      url: buildFileUrl(req, filePath),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};