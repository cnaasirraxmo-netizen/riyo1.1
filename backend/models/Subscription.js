const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  plan: { type: String, enum: ['free', 'premium', 'pro'], default: 'free' },
  status: { type: String, enum: ['active', 'inactive', 'expired'], default: 'inactive' },
  amount: { type: Number, required: true },
  currency: { type: String, default: 'USD' },
  paymentId: { type: String }, // Transaction ID from Stripe/EVC Plus
  startDate: { type: Date, default: Date.now },
  endDate: { type: Date, required: true },
}, { timestamps: true });

const Subscription = mongoose.models.Subscription || mongoose.model('Subscription', subscriptionSchema);

module.exports = Subscription;
