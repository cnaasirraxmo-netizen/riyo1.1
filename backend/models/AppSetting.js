const mongoose = require('mongoose');

const appSettingSchema = new mongoose.Schema({
  key: { type: String, required: true, unique: true },
  value: { type: mongoose.Schema.Types.Mixed, required: true },
  group: { type: String, default: 'General' }, // General, Streaming, Storage, Branding, Email, Security
  description: { type: String }
}, { timestamps: true });

const AppSetting = mongoose.models.AppSetting || mongoose.model('AppSetting', appSettingSchema);

module.exports = AppSetting;
