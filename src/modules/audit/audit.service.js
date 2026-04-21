const AuditLog = require('./auditLog.model');

async function createAuditLog({
  action,
  entityType,
  entityId = null,
  message,
  performedByUserId = null,
  performedByEmail = '',
  metadata = null,
}) {
  return AuditLog.create({
    action: String(action || '').trim(),
    entityType: String(entityType || '').trim(),
    entityId: entityId || null,
    message: String(message || '').trim(),
    performedByUserId: performedByUserId || null,
    performedByEmail: String(performedByEmail || '').trim(),
    metadata,
  });
}

async function getRecentAuditLogs(limit = 20) {
  const safeLimit = Math.max(1, Math.min(Number(limit) || 20, 100));

  return AuditLog.find()
    .sort({ createdAt: -1 })
    .limit(safeLimit)
    .populate('performedByUserId', 'fullName email role');
}

module.exports = {
  createAuditLog,
  getRecentAuditLogs,
};