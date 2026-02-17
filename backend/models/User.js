const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true, lowercase: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['user', 'admin'], default: 'user' },
  profilePicture: { type: String, default: '' },
  bio: { type: String, default: '' },
  watchlist: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Movie' }],
  watchHistory: [{
    movie: { type: mongoose.Schema.Types.ObjectId, ref: 'Movie' },
    progress: { type: Number, default: 0 }, // in seconds
    duration: { type: Number, default: 0 },
    lastWatched: { type: Date, default: Date.now }
  }],
  preferences: {
    language: { type: String, default: 'en' },
    quality: { type: String, default: 'auto' },
    notifications: { type: Boolean, default: true }
  },
  isVerified: { type: Boolean, default: false },
  subscription: {
    plan: { type: String, enum: ['free', 'premium', 'pro'], default: 'free' },
    startDate: Date,
    endDate: Date,
    status: { type: String, enum: ['active', 'inactive', 'expired'], default: 'inactive' }
  }
}, { timestamps: true });

userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

userSchema.methods.comparePassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
