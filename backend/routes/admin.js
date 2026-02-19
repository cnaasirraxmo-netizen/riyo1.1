const express = require('express');
const Movie = require('../models/Movie');
const User = require('../models/User');
const Review = require('../models/Review');
const Subscription = require('../models/Subscription');
const { protect, adminOnly, hasPermission } = require('../middleware/authMiddleware');
const { sendPushNotification } = require('../utils/notifications');
const router = express.Router();

// Get overall stats
router.get('/stats', protect, hasPermission('view_analytics'), async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalMovies = await Movie.countDocuments();
    const totalReviews = await Review.countDocuments();
    const activeSubscriptions = await User.countDocuments({ 'subscription.status': 'active' });

    const revenueStats = await Subscription.aggregate([
      { $match: { status: 'active' } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);

    res.json({
      totalUsers,
      totalMovies,
      totalReviews,
      activeSubscriptions,
      revenue: revenueStats.length > 0 ? revenueStats[0].total : 0
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
