const express = require('express');
const Movie = require('../models/Movie');
const User = require('../models/User');
const Review = require('../models/Review');
const Subscription = require('../models/Subscription');
const { protect, admin } = require('../middleware/authMiddleware');
const router = express.Router();

// Get overall stats
router.get('/stats', protect, admin, async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalMovies = await Movie.countDocuments();
    const totalReviews = await Review.countDocuments();
    const activeSubscriptions = await User.countDocuments({ 'subscription.status': 'active' });

    // Revenue stats (mock)
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

// User management
router.get('/users', protect, admin, async (req, res) => {
  try {
    const users = await User.find().select('-password');
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.put('/users/:id/role', protect, admin, async (req, res) => {
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

module.exports = router;
