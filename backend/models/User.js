const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

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
  firebaseUid: {
    type: String,
    unique: true,
    sparse: true // This allows multiple users to have 'null' firebaseUid while still enforcing uniqueness for non-null values
  },
  email: { type: String, required: true, unique: true, lowercase: true },
  username: { type: String, unique: true, sparse: true },
  password: { type: String },
  name: { type: String },
  phone: { type: String },
  role: {
    type: String,
    enum: ['user', 'admin', 'super-admin', 'content-admin', 'support-admin', 'analytics-admin', 'moderator'],
    default: 'user'
  },
  status: { type: String, enum: ['Active', 'Suspended', 'Deleted'], default: 'Active' },
  permissions: {
    manage_movies: { type: Boolean, default: false },
    manage_users: { type: Boolean, default: false },
    manage_settings: { type: Boolean, default: false },
    manage_admins: { type: Boolean, default: false },
    view_analytics: { type: Boolean, default: false },
    financial_access: { type: Boolean, default: false }
  },
  loginAttempts: { type: Number, required: true, default: 0 },
  lockUntil: { type: Number },
  refreshToken: { type: String },
  twoFactorSecret: { type: String },
  twoFactorEnabled: { type: Boolean, default: false },
  profiles: [profileSchema],
  activeProfileId: { type: mongoose.Schema.Types.ObjectId },
  fcmTokens: [String],
  subscription: {
    planId: { type: mongoose.Schema.Types.ObjectId, ref: 'Plan' },
    planName: { type: String, default: 'free' },
    startDate: Date,
    endDate: Date,
    status: { type: String, enum: ['active', 'inactive', 'expired'], default: 'inactive' }
  },
  devices: [{
    deviceId: String,
    deviceName: String,
    deviceType: String, // Mobile, Web, TV
    lastLogin: { type: Date, default: Date.now }
  }],
  balance: { type: Number, default: 0 },
  totalWatchTime: { type: Number, default: 0 }, // in minutes
}, { timestamps: true });

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password') || !this.password) {
    return next();
  }
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (err) {
    next(err);
  }
});

// Method to compare passwords
userSchema.methods.comparePassword = async function(candidatePassword) {
  if (!this.password) return false;
  return bcrypt.compare(candidatePassword, this.password);
};

userSchema.virtual('isLocked').get(function() {
  return !!(this.lockUntil && this.lockUntil > Date.now());
});

// Prevent OverwriteModelError
const User = mongoose.models.User || mongoose.model('User', userSchema);

module.exports = User;
