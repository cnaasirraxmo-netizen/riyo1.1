const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  movie: { type: mongoose.Schema.Types.ObjectId, ref: 'Movie', required: true },
  rating: { type: Number, required: true, min: 1, max: 5 },
  comment: { type: String, required: true },
  isApproved: { type: Boolean, default: true }, // Auto-approve for now
}, { timestamps: true });

// Prevent multiple reviews from same user for same movie
reviewSchema.index({ user: 1, movie: 1 }, { unique: true });

module.exports = mongoose.model('Review', reviewSchema);
