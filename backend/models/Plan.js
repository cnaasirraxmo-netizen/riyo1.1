const mongoose = require('mongoose');

const planSchema = new mongoose.Schema({
  name: { type: String, required: true, unique: true }, // Free, Basic, Premium, Family
  price: { type: Number, required: true },
  interval: { type: String, enum: ['monthly', 'yearly'], default: 'monthly' },
  devicesAllowed: { type: Number, default: 1 },
  downloadLimit: { type: Number, default: 0 }, // 0 = unlimited
  has4K: { type: Boolean, default: false },
  hasAds: { type: Boolean, default: true },
  regionalPricing: [{
    country: { type: String },
    currency: { type: String },
    price: { type: Number }
  }],
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

const Plan = mongoose.models.Plan || mongoose.model('Plan', planSchema);

module.exports = Plan;
