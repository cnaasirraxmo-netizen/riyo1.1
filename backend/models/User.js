const mongoose = require('mongoose');

const profileSchema = new mongoose.Schema({
  name: { type: String, required: true },
  avatar: { type: String, default: '' },
  isKids: { type: Boolean, default: false },
  watchlist: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Movie' }],
  watchHistory: [{
    movie: { type: mongoose.Schema.Types.ObjectId, ref: 'Movie' },
    progress: { type: Number, default: 0 },
    duration: { type: Number, default: 0 },
    lastWatched: { type: Date, default: Date.now }
  }],
});

const userSchema = new mongoose.Schema({
  firebaseUid: { type: String, required: true, unique: true },
  email: { type: String, required: true, unique: true, lowercase: true },
  name: { type: String },
  role: { type: String, enum: ['user', 'admin'], default: 'user' },
  profiles: [profileSchema],
  activeProfileId: { type: mongoose.Schema.Types.ObjectId },
  fcmTokens: [String],
  subscription: {
    plan: { type: String, enum: ['free', 'premium', 'pro'], default: 'free' },
    startDate: Date,
    endDate: Date,
    status: { type: String, enum: ['active', 'inactive', 'expired'], default: 'inactive' }
  }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
