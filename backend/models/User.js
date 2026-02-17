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
  name: { type: String, required: true },

  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true
  },

  password: {
    type: String,
    required: true
  },

  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user'
  },

  profiles: [profileSchema],
  activeProfileId: { type: mongoose.Schema.Types.ObjectId },
  fcmTokens: [String],

  subscription: {
    plan: {
      type: String,
      enum: ['free', 'premium', 'pro'],
      default: 'free'
    },
    startDate: Date,
    endDate: Date,
    status: {
      type: String,
      enum: ['active', 'inactive', 'expired'],
      default: 'inactive'
    }
  }

}, { timestamps: true });


// 🔐 Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

// 🔐 Compare password on login
userSchema.methods.comparePassword = async function(password) {
  return await bcrypt.compare(password, this.password);
};

// 🔹 Ka hortag OverwriteModelError
module.exports = mongoose.models.User || mongoose.model('User', userSchema);
