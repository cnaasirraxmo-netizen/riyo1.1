const express = require('express');
const Movie = require('../models/Movie');
const User = require('../models/User');
const Review = require('../models/Review');
const Subscription = require('../models/Subscription');
const { protect, adminOnly, hasPermission } = require('../middleware/authMiddleware');
const { sendPushNotification } = require('../utils/notifications');
const router = express.Router();

// Update admin profile (Self)
router.put('/profile', protect, adminOnly, async (req, res) => {
  try {
    const { username, email, password, name } = req.body;
    const user = await User.findById(req.user._id);

    if (username) user.username = username;
    if (email) user.email = email.toLowerCase();
    if (name) user.name = name;
    if (password) user.password = password; // Hashing is handled by pre-save hook

    await user.save();

    res.json({
      _id: user._id,
      name: user.name,
      email: user.email,
      username: user.username,
      role: user.role,
      message: 'Profile updated successfully'
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ message: 'Username or Email already in use' });
    }
    res.status(500).json({ message: error.message });
  }
});

// Admin User Actions
router.post('/users/:id/action', protect, hasPermission('manage_users'), async (req, res) => {
  try {
    const { action, data } = req.body;
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    switch (action) {
      case 'suspend':
        user.status = 'Suspended';
        break;
      case 'activate':
        user.status = 'Active';
        break;
      case 'upgrade':
        user.subscription.status = 'active';
        user.subscription.planName = 'premium';
        user.subscription.endDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
        break;
      case 'adjust-balance':
        user.balance += Number(data.amount);
        break;
      case 'reset-password':
        user.password = 'RIYOBOX' + Math.floor(1000 + Math.random() * 9000); // Temporary password
        await user.save();
        return res.json({ message: 'Password reset to: ' + user.password });
      default:
        return res.status(400).json({ message: 'Invalid action' });
    }

    await user.save();
    res.json({ message: 'Action performed successfully', user });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Advanced Dashboard Stats
router.get('/stats', protect, hasPermission('view_analytics'), async (req, res) => {
  try {
    const totalUsers = await User.countDocuments({ status: { $ne: 'Deleted' } });
    const activeNow = 120; // Simulated real-time users
    const premiumUsers = await User.countDocuments({ 'subscription.status': 'active' });
    const totalMovies = await Movie.countDocuments({ isTvShow: false });
    const totalTvShows = await Movie.countDocuments({ isTvShow: true });
    const totalDownloads = 15430; // Simulated
    const storageUsage = "1.2 TB"; // Simulated

    const monthlyRevenue = await Subscription.aggregate([
      { $match: { status: 'active', createdAt: { $gte: new Date(new Date().setDate(1)) } } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);

    const renewalRate = "85%";
    const appUptime = "99.9%";
    const apiResponseTime = "45ms";
    const cdnHitRate = "94%";

    res.json({
      totalUsers,
      activeNow,
      premiumUsers,
      totalMovies,
      totalTvShows,
      totalDownloads,
      storageUsage,
      monthlyRevenue: monthlyRevenue.length > 0 ? monthlyRevenue[0].total : 0,
      renewalRate,
      appUptime,
      apiResponseTime,
      cdnHitRate
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.put('/users/:id/permissions', protect, adminOnly, async (req, res) => {
  try {
    const { permissions } = req.body;
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.permissions = permissions;
    await user.save();
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// User management
router.get('/users', protect, hasPermission('manage_users'), async (req, res) => {
  try {
    const users = await User.find().select('-password');
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.put('/users/:id/role', protect, hasPermission('manage_admins'), async (req, res) => {
  try {
    const { role } = req.body;
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.role = role;
    await user.save();
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Admin Movies with Notification flag
router.get('/movies', protect, adminOnly, async (req, res) => {
  try {
    const movies = await Movie.find().sort({ createdAt: -1 });
    res.json(movies);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.post('/movies', protect, hasPermission('manage_movies'), async (req, res) => {
  try {
    const { title, notify, ...rest } = req.body;
    const movie = await Movie.create({ title, ...rest });

    if (notify) {
      await sendPushNotification(
        'New Movie Added! 🎬',
        `"${title}" is now available to stream on RIYOBOX.`,
        { movieId: movie._id.toString() }
      );
    }

    res.status(201).json(movie);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.delete('/movies/:id', protect, hasPermission('manage_movies'), async (req, res) => {
  try {
    await Movie.findByIdAndDelete(req.params.id);
    res.json({ message: 'Movie deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Manual Push Notification
router.post('/notify', protect, hasPermission('manage_settings'), async (req, res) => {
  try {
    const { title, body, data } = req.body;
    await sendPushNotification(title, body, data);
    res.json({ message: 'Notification broadcasted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
