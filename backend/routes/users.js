const express = require('express');
const User = require('../models/User');
const { protect } = require('../middleware/authMiddleware');
const router = express.Router();

// Get user profile including watchlist and history
router.get('/profile', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id)
      .populate('watchlist')
      .populate('watchHistory.movie');
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update profile
router.put('/profile', protect, async (req, res) => {
  try {
    const { name, bio, profilePicture, preferences } = req.body;
    const user = await User.findById(req.user._id);

    if (name) user.name = name;
    if (bio) user.bio = bio;
    if (profilePicture) user.profilePicture = profilePicture;
    if (preferences) user.preferences = { ...user.preferences, ...preferences };

    await user.save();
    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update watch history / progress
router.post('/history', protect, async (req, res) => {
  try {
    const { movieId, progress, duration } = req.body;
    const user = await User.findById(req.user._id);

    const historyIndex = user.watchHistory.findIndex(h => h.movie.toString() === movieId);

    if (historyIndex > -1) {
      user.watchHistory[historyIndex].progress = progress;
      user.watchHistory[historyIndex].duration = duration;
      user.watchHistory[historyIndex].lastWatched = Date.now();
    } else {
      user.watchHistory.push({ movie: movieId, progress, duration });
    }

    // Keep history manageable - e.g., last 50 items
    if (user.watchHistory.length > 50) {
      user.watchHistory.shift();
    }

    await user.save();
    res.json({ message: 'History updated' });
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
    let isAdded = false;
    if (index > -1) {
      user.watchlist.splice(index, 1);
      isAdded = false;
    } else {
      user.watchlist.push(movieId);
      isAdded = true;
    }
    await user.save();
    res.json({ message: isAdded ? 'Added to watchlist' : 'Removed from watchlist', isAdded });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Delete account (GDPR)
router.delete('/account', protect, async (req, res) => {
  try {
    await User.findByIdAndDelete(req.user._id);
    res.json({ message: 'Account deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
