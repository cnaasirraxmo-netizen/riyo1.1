
const mongoose = require('mongoose');
const User = require('../models/User');
require('dotenv').config();

const setupAdmin = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB');

    // Remove existing admins (optional, but requested "Remove admin email and password")
    // WARNING: This deletes all admin accounts.
    const deleted = await User.deleteMany({
      role: { $in: ['admin', 'super-admin', 'content-admin', 'support-admin', 'analytics-admin', 'moderator'] }
    });
    console.log(`Removed ${deleted.deletedCount} existing admin accounts.`);

    // Create new super-admin
    const newAdmin = await User.create({
      name: 'RIYOBOX CEO',
      email: 'ceo@riyobox.app',
      username: 'riyobox_admin',
      password: 'NewAdminPassword123!', // User should change this immediately
      role: 'super-admin',
      permissions: {
        manage_movies: true,
        manage_users: true,
        manage_settings: true,
        manage_admins: true,
        view_analytics: true,
        financial_access: true
      }
    });

    console.log('New Super-Admin Created:');
    console.log(`Email: ${newAdmin.email}`);
    console.log(`Username: ${newAdmin.username}`);
    console.log('Password: NewAdminPassword123!');
    console.log('\nPlease change the password immediately after first login.');

    process.exit(0);
  } catch (error) {
    console.error('Setup failed:', error);
    process.exit(1);
  }
};

setupAdmin();
