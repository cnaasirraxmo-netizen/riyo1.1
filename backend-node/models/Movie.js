const mongoose = require('mongoose');

const movieSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  posterUrl: { type: String, required: true },
  backdropUrl: { type: String },
  videoUrl: { type: String, required: true },
  duration: { type: String },
  year: { type: Number },
  genre: { type: [String] },
  rating: { type: Number, default: 0 },
  isTrending: { type: Boolean, default: false },
  isFeatured: { type: Boolean, default: false },
  contentType: { type: String, enum: ['free', 'premium', 'coming_soon'], default: 'free' },
  trailerUrl: { type: String },
  isPublished: { type: Boolean, default: true },
  notifyUsers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  contentRating: { type: String },
}, { timestamps: true });

// Performance Indexes
movieSchema.index({ genre: 1 });
movieSchema.index({ isTrending: 1 });
movieSchema.index({ isFeatured: 1 });
movieSchema.index({ contentType: 1 });
movieSchema.index({ isPublished: 1 });
movieSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Movie', movieSchema);
