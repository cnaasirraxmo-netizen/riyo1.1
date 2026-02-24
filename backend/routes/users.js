const express = require('express');
const User = require('../models/User');
const { protect } = require('../middleware/authMiddleware');
const router = express.Router();

// Get user profile including watchlist
router.get('/profile', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate('watchlist');
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Toggle movie in watchlist
router.post('/watchlist/:movieId', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    const movieId = req.params.movieId;

    const index = user.watchlist.indexOf(movieId);
    if (index > -1) {
      user.watchlist.splice(index, 1);
      await user.save();
      res.json({ message: 'Removed from watchlist', isAdded: false });
    } else {
      user.watchlist.push(movieId);
      await user.save();
      res.json({ message: 'Added to watchlist', isAdded: true });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Toggle Notify Me for a movie
router.post('/notify-me/:movieId', protect, async (req, res) => {
  try {
    const Movie = require('../models/Movie');
    const movie = await Movie.findById(req.params.movieId);
    if (!movie) return res.status(404).json({ message: 'Movie not found' });

    const userId = req.user._id;
    const index = movie.notifyUsers.indexOf(userId);

    if (index > -1) {
      movie.notifyUsers.splice(index, 1);
      await movie.save();
      res.json({ message: 'Notifications disabled', isNotified: false });
    } else {
      movie.notifyUsers.push(userId);
      await movie.save();
      res.json({ message: 'Notifications enabled', isNotified: true });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
