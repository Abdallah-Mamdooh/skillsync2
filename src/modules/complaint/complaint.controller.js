const path = require('path');
const asyncHandler = require('../../middlewares/async.middleware');
const complaintService = require('./complaint.service');

function buildFileUrl(req, filePath) {
  const baseUrl = `${req.protocol}://${req.get('host')}`;
  return `${baseUrl}/${filePath.replace(/\\/g, '/')}`;
}

const createComplaint = asyncHandler(async (req, res) => {
  let attachments = [];

  if (Array.isArray(req.files) && req.files.length > 0) {
    attachments = req.files.map((file) => {
      const filePath = path.join('uploads', 'complaints', file.filename);

      return {
        url: buildFileUrl(req, filePath),
        fileName: file.originalname,
        mimeType: file.mimetype,
        size: file.size || 0,
      };
    });
  }

  const data = await complaintService.createComplaint(req.user._id, {
    ...req.body,
    attachments,
  });

  res.status(201).json({
    success: true,
    data,
  });
});

const getMyComplaints = asyncHandler(async (req, res) => {
  const data = await complaintService.getMyComplaints(req.user._id, req.query);
  res.status(200).json({ success: true, data });
});

const getMyComplaintById = asyncHandler(async (req, res) => {
  const data = await complaintService.getComplaintById(
    req.user._id,
    req.params.complaintId,
    false
  );
  res.status(200).json({ success: true, data });
});

const getAllComplaints = asyncHandler(async (req, res) => {
  const data = await complaintService.getAllComplaints(req.query);
  res.status(200).json({ success: true, data });
});

const getComplaintByIdAdmin = asyncHandler(async (req, res) => {
  const data = await complaintService.getComplaintById(
    req.user._id,
    req.params.complaintId,
    true
  );
  res.status(200).json({ success: true, data });
});

const updateComplaintStatus = asyncHandler(async (req, res) => {
  const data = await complaintService.updateComplaintStatus(
    req.params.complaintId,
    req.body
  );
  res.status(200).json({ success: true, data });
});

module.exports = {
  createComplaint,
  getMyComplaints,
  getMyComplaintById,
  getAllComplaints,
  getComplaintByIdAdmin,
  updateComplaintStatus,
};