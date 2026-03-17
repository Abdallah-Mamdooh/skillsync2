const Complaint = require('./complaint.model');
const notificationService = require('../notification/notification.service');

function normalizeText(value) {
  return String(value || '').trim();
}

function normalizeAttachments(value) {
  if (!Array.isArray(value)) return [];

  return value.map((item) => ({
    url: String(item.url || '').trim(),
    fileName: String(item.fileName || '').trim(),
    mimeType: String(item.mimeType || '').trim(),
    size: Number(item.size || 0),
  }));
}

async function createComplaint(userId, payload = {}) {
  const entityType = normalizeText(payload.entityType);
  const category = normalizeText(payload.category);
  const title = normalizeText(payload.title);
  const description = normalizeText(payload.description);

  if (!entityType) {
    throw new Error('entityType is required');
  }

  if (!category) {
    throw new Error('category is required');
  }

  if (!title) {
    throw new Error('title is required');
  }

  if (!description) {
    throw new Error('description is required');
  }

  const complaint = await Complaint.create({
    userId,
    entityType,
    entityId: payload.entityId || null,
    category,
    title,
    description,
    attachments: normalizeAttachments(payload.attachments),
    status: 'open',
  });

  await notificationService.createNotification({
    userId,
    type: 'complaint_submitted',
    title: 'Complaint submitted',
    message: 'Your complaint was submitted successfully and is under review.',
    data: {
      complaintId: complaint._id,
      entityType: complaint.entityType,
      category: complaint.category,
      status: complaint.status,
    },
  });

  return complaint;
}

async function getMyComplaints(userId, query = {}) {
  const {
    status = '',
    entityType = '',
    page = 1,
    limit = 20,
  } = query;

  const filters = { userId };

  if (status) {
    filters.status = status;
  }

  if (entityType) {
    filters.entityType = entityType;
  }

  const skip = (Number(page) - 1) * Number(limit);

  const [items, total] = await Promise.all([
    Complaint.find(filters)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(Number(limit)),
    Complaint.countDocuments(filters),
  ]);

  return {
    items,
    pagination: {
      page: Number(page),
      limit: Number(limit),
      total,
      pages: Math.ceil(total / Number(limit)),
    },
  };
}

async function getComplaintById(currentUserId, complaintId, isAdmin = false) {
  const complaint = await Complaint.findById(complaintId).populate(
    'userId',
    'fullName email'
  );

  if (!complaint) {
    throw new Error('Complaint not found');
  }

  if (!isAdmin && String(complaint.userId._id) !== String(currentUserId)) {
    throw new Error('You are not allowed to view this complaint');
  }

  return complaint;
}

async function getAllComplaints(query = {}) {
  const {
    status = '',
    entityType = '',
    category = '',
    search = '',
    page = 1,
    limit = 20,
  } = query;

  const filters = {};

  if (status) filters.status = status;
  if (entityType) filters.entityType = entityType;
  if (category) filters.category = category;

  let complaints = await Complaint.find(filters)
    .populate('userId', 'fullName email')
    .sort({ createdAt: -1 });

  if (search) {
    const s = String(search).toLowerCase();
    complaints = complaints.filter((c) => {
      const title = String(c.title || '').toLowerCase();
      const description = String(c.description || '').toLowerCase();
      const fullName = String(c.userId?.fullName || '').toLowerCase();
      const email = String(c.userId?.email || '').toLowerCase();

      return (
        title.includes(s) ||
        description.includes(s) ||
        fullName.includes(s) ||
        email.includes(s)
      );
    });
  }

  const total = complaints.length;
  const start = (Number(page) - 1) * Number(limit);
  const end = start + Number(limit);

  return {
    items: complaints.slice(start, end),
    pagination: {
      page: Number(page),
      limit: Number(limit),
      total,
      pages: Math.ceil(total / Number(limit)),
    },
  };
}

async function updateComplaintStatus(complaintId, payload = {}) {
  const { status, adminNote = '' } = payload;

  const allowed = ['open', 'reviewed', 'resolved', 'dismissed'];
  if (!allowed.includes(status)) {
    throw new Error('Invalid complaint status');
  }

  const complaint = await Complaint.findById(complaintId);

  if (!complaint) {
    throw new Error('Complaint not found');
  }

  complaint.status = status;
  complaint.adminNote = normalizeText(adminNote);

  if (status === 'reviewed' && !complaint.reviewedAt) {
    complaint.reviewedAt = new Date();
  }

  if (['resolved', 'dismissed'].includes(status)) {
    complaint.resolvedAt = new Date();
    if (!complaint.reviewedAt) {
      complaint.reviewedAt = new Date();
    }
  }

  await complaint.save();

  await notificationService.createNotification({
    userId: complaint.userId,
    type: 'complaint_status_updated',
    title: 'Complaint status updated',
    message: `Your complaint status is now: ${complaint.status}.`,
    data: {
      complaintId: complaint._id,
      status: complaint.status,
      adminNote: complaint.adminNote,
      entityType: complaint.entityType,
    },
  });

  return complaint;
}

module.exports = {
  createComplaint,
  getMyComplaints,
  getComplaintById,
  getAllComplaints,
  updateComplaintStatus,
};