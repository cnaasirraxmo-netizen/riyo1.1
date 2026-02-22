const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema({
  admin: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  action: { type: String, required: true }, // e.g., 'DELETE_MOVIE', 'UPDATE_USER_ROLE'
  module: { type: String, required: true }, // e.g., 'Movies', 'Users', 'Settings'
  targetId: { type: mongoose.Schema.Types.ObjectId }, // ID of the object changed
  details: { type: String },
  ipAddress: { type: String },
  userAgent: { type: String },
}, { timestamps: true });

const AuditLog = mongoose.models.AuditLog || mongoose.model('AuditLog', auditLogSchema);

module.exports = AuditLog;
