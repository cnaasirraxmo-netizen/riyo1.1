const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  amount: { type: Number, required: true },
  currency: { type: String, default: 'USD' },
  status: { type: String, enum: ['Pending', 'Completed', 'Failed', 'Refunded'], default: 'Pending' },
  paymentMethod: { type: String }, // e.g., 'EVC Plus', 'Stripe', 'Sahay'
  type: { type: String, enum: ['Subscription', 'Rent', 'Purchase'], required: true },
  referenceId: { type: String }, // External payment ref
  metadata: { type: Object },
  refundReason: { type: String },
  region: { type: String }, // Country of transaction
}, { timestamps: true });

const Transaction = mongoose.models.Transaction || mongoose.model('Transaction', transactionSchema);

module.exports = Transaction;
