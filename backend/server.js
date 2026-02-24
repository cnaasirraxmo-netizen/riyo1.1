const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const User = require('./models/User');
const Category = require('./models/Category');
const HomeSection = require('./models/HomeSection');

dotenv.config();

// Validate Environment Variables
const requiredEnvVars = [
  'MONGO_URI',
  'JWT_SECRET',
  'R2_ACCESS_KEY_ID',
  'R2_SECRET_ACCESS_KEY',
  'R2_BUCKET_NAME'
];

const validateEnv = () => {
  const missing = requiredEnvVars.filter(v => !process.env[v]);
  if (missing.length > 0) {
    console.warn('⚠️ WARNING: Missing required environment variables:', missing.join(', '));
    console.warn('Please ensure you have a .env file or environment variables set for:');
    missing.forEach(v => console.warn(`   - ${v}`));
    console.warn('Backend features like Auth or R2 Storage will NOT work properly without these.');
  } else {
    console.log('✅ All environment variables are configured.');
  }
};

validateEnv();
const app = express();
app.use(express.json());

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
app.use('/config', require('./routes/config'));

app.get('/', (req, res) => {
  const r2Configured = !!(process.env.R2_ACCESS_KEY_ID && process.env.R2_SECRET_ACCESS_KEY && process.env.R2_BUCKET_NAME);

  res.json({
    message: 'Riyo API is running...',
    status: 'Operational',
    database: mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected',
    storage: r2Configured ? 'R2 Configured' : 'R2 Missing Configuration',
    timestamp: new Date().toISOString()
  });
});

const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/riyo';

const seedLayoutConfig = async () => {
  try {
    const categoryCount = await Category.countDocuments();
    if (categoryCount === 0) {
      console.log('Seeding default categories...');
      await Category.insertMany([
        { name: 'All', order: 1 },
        { name: 'Movies', order: 2 },
        { name: 'TV Shows', order: 3 },
        { name: 'Anime', order: 4 },
        { name: 'Kids', order: 5 },
        { name: 'My List', order: 6 },
      ]);
    }

    const sectionCount = await HomeSection.countDocuments();
    if (sectionCount === 0) {
      console.log('Seeding default home sections...');
      await HomeSection.insertMany([
        { title: 'Trending Now', type: 'trending', order: 1 },
        { title: 'Popular on RIYO', type: 'top_rated', order: 2 },
        { title: 'New Releases', type: 'new_releases', order: 3 },
      ]);
    }
  } catch (error) {
    console.error('❌ Error seeding layout config:', error.message);
  }
};

const createDefaultAdmin = async () => {
  try {
    const adminEmail = 'admin@example.com';
    const adminExists = await User.findOne({ email: adminEmail });

    if (!adminExists) {
      console.log('Creating default admin account...');
      const admin = await User.create({
        name: 'Super Admin',
        email: adminEmail,
        password: 'admin123',
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
    await seedLayoutConfig();
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
  })
  .catch((err) => {
    console.error('MongoDB connection error:', err.message);
    process.exit(1);
  });
