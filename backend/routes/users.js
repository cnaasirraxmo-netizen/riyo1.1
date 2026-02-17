const express = require('express');
const User = require('../models/User');
const { protect } = require('../middleware/authMiddleware');
const router = express.Router();

// Get user account (all profiles)
router.get('/account', protect, async (req, res) => {
  res.json(req.user);
});

// Add a new profile
router.post('/profiles', protect, async (req, res) => {
  try {
    const { name, avatar, isKids } = req.body;
    if (req.user.profiles.length >= 5) {
      return res.status(400).json({ message: 'Maximum 5 profiles allowed' });
    }

    req.user.profiles.push({ name, avatar, isKids });
    await req.user.save();
    res.status(201).json(req.user.profiles[req.user.profiles.length - 1]);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Set active profile
router.put('/profiles/active', protect, async (req, res) => {
  try {
    const { profileId } = req.body;
    const profile = req.user.profiles.id(profileId);
    if (!profile) return res.status(404).json({ message: 'Profile not found' });

    req.user.activeProfileId = profileId;
    await req.user.save();
    res.json({ message: 'Active profile updated', profile });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get active profile data (watchlist, history)
router.get('/profile', protect, async (req, res) => {
  try {
    const profileId = req.user.activeProfileId || req.user.profiles[0]._id;

    // Use findOne to allow population of subdocument arrays
    const user = await User.findById(req.user._id)
      .populate('profiles.watchlist')
      .populate('profiles.watchHistory.movie');

    const profile = user.profiles.id(profileId);
    res.json(profile);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Toggle movie in watchlist for ACTIVE profile
router.post('/watchlist/:movieId', protect, async (req, res) => {
  try {
    const profileId = req.user.activeProfileId || req.user.profiles[0]._id;
    const profile = req.user.profiles.id(profileId);
    const movieId = req.params.movieId;

    const index = profile.watchlist.indexOf(movieId);
    let isAdded = false;
    if (index > -1) {
      profile.watchlist.splice(index, 1);
      isAdded = false;
    } else {
      profile.watchlist.push(movieId);
      isAdded = true;
    }
    await req.user.save();
    res.json({ message: isAdded ? 'Added to watchlist' : 'Removed from watchlist', isAdded });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update watch history for ACTIVE profile
router.post('/history', protect, async (req, res) => {
  try {
    const { movieId, progress, duration } = req.body;
    const profileId = req.user.activeProfileId || req.user.profiles[0]._id;
    const profile = req.user.profiles.id(profileId);

    const historyIndex = profile.watchHistory.findIndex(h => h.movie.toString() === movieId);

    if (historyIndex > -1) {
      profile.watchHistory[historyIndex].progress = progress;
      profile.watchHistory[historyIndex].duration = duration;
      profile.watchHistory[historyIndex].lastWatched = Date.now();
    } else {
      profile.watchHistory.push({ movie: movieId, progress, duration });
    }

    if (profile.watchHistory.length > 50) profile.watchHistory.shift();

    await req.user.save();
    res.json({ message: 'History updated' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Register FCM token
router.post('/fcm-token', protect, async (req, res) => {
  try {
    const { token } = req.body;
    if (!req.user.fcmTokens.includes(token)) {
      req.user.fcmTokens.push(token);
      await req.user.save();
    }
    res.json({ message: 'Token registered' });
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
