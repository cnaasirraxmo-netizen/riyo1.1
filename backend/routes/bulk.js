const express = require('express');
const Movie = require('../models/Movie');
const User = require('../models/User');
const { protect, adminOnly } = require('../middleware/authMiddleware');
const router = express.Router();

router.post('/import-movies', protect, adminOnly, async (req, res) => {
  try {
    const { movies } = req.body; // Array of movie objects
    if (!Array.isArray(movies)) return res.status(400).json({ message: 'Invalid format' });

    const results = await Movie.insertMany(movies);
    res.json({ message: `Successfully imported ${results.length} movies`, results });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.post('/export-users', protect, adminOnly, async (req, res) => {
  try {
    const users = await User.find().select('-password');
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
