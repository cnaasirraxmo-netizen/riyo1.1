const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const User = require('./models/User');

dotenv.config();

const app = express();

// Security Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate Limiting
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per window
  message: 'Too many login attempts from this IP, please try again after 15 minutes'
});

// Routes
app.use('/api/auth', loginLimiter, require('./routes/authRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));

// Default Admin Initialization
const initAdmin = async () => {
  try {
    const adminExists = await User.findOne({ role: 'admin' });
    if (!adminExists) {
      const admin = new User({
        username: 'sahan',
        password: 'sahan00',
        email: 'aabahatechnologyada@gmail.com',
        role: 'admin'
      });
      await admin.save();
      console.log('Default admin created successfully');
    }
  } catch (error) {
    console.error('Admin initialization error:', error);
  }
};

const PORT = process.env.PORT || 5000;

mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('MongoDB connected');
    initAdmin();
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
  })
  .catch(err => console.error('MongoDB connection error:', err));
