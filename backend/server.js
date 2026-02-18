const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const dotenv = require('dotenv');
const { initializeFirebase } = require('./utils/firebase');
const User = require('./models/User');

dotenv.config();
initializeFirebase();

// Validate Environment Variables
const requiredEnvVars = [
  'MONGO_URI',
  'JWT_SECRET',
  'R2_ACCESS_KEY_ID',
  'R2_SECRET_ACCESS_KEY',
  'R2_BUCKET_NAME',
  'FOOTBALL_API_KEY'
];

const validateEnv = () => {
  const missing = requiredEnvVars.filter(v => !process.env[v]);
  if (missing.length > 0) {
    console.warn('⚠️ WARNING: Missing recommended environment variables:', missing.join(', '));
    console.warn('Backend features like Auth or R2 Storage might not work properly.');
  } else {
    console.log('✅ All environment variables are configured.');
  }
};

validateEnv();
const app = express();
app.use(express.json());

// Rate Limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again after 15 minutes'
});
app.use('/auth/', limiter); // Apply limiter only to auth routes

// Enable CORS for all origins
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use('/auth', require('./routes/auth'));
app.use('/admin', require('./routes/admin'));
app.use('/movies', require('./routes/movies'));
app.use('/users', require('./routes/users'));
app.use('/upload', require('./routes/upload'));
app.use('/sports', require('./routes/sports'));

app.get('/', (req, res) => {
  const r2Configured = !!(process.env.R2_ACCESS_KEY_ID && process.env.R2_SECRET_ACCESS_KEY && process.env.R2_BUCKET_NAME);
  const { admin } = require('./utils/firebase');
  const firebaseStatus = admin.apps.length > 0 ? 'Initialized' : 'Mock Mode (Dev Only)';

  res.json({
    message: 'Riyobox API is running...',
    status: 'Operational',
    database: mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected',
    storage: r2Configured ? 'R2 Configured' : 'R2 Missing Configuration',
    firebase: firebaseStatus,
    timestamp: new Date().toISOString()
  });
});

const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/riyobox';

const createDefaultAdmin = async () => {
  try {
    const adminEmail = 'admin@exampl.com';
    const adminExists = await User.findOne({ email: adminEmail });

    if (!adminExists) {
      console.log('Creating default admin account...');
      const admin = await User.create({
        name: 'Super Admin',
        email: adminEmail,
        password: 'admin12',
        role: 'admin'
      });
      console.log('✅ Default admin created successfully:', admin.email);
    } else {
      console.log('ℹ️ Admin account already exists:', adminExists.email);
    }
  } catch (error) {
    console.error('❌ Error creating default admin:', error.message);
    if (error.code === 11000) {
      console.error('Email already exists (Race condition handled)');
    }
  }
};

mongoose.connect(MONGO_URI)
  .then(async () => {
    console.log('MongoDB connected');
    await createDefaultAdmin();
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
  })
  .catch((err) => {
    console.error('MongoDB connection error:', err.message);
    process.exit(1);
  });
