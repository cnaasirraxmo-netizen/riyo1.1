const express = require('express');
const mongoose = require('mongoose');
const Movie = require('../models/Movie');
const { protect } = require('../middleware/authMiddleware');
const router = express.Router();

router.get('/', protect, async (req, res) => {
  try {
    const { genre, isTrending, isFeatured, contentType, search, page = 1, limit = 20 } = req.query;
    let query = { isPublished: true };
    if (genre) query.genre = genre;
    if (isTrending) query.isTrending = isTrending === 'true';
    if (isFeatured) query.isFeatured = isFeatured === 'true';
    if (contentType) query.contentType = contentType;
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const movies = await Movie.find(query)
      .sort('-createdAt')
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Movie.countDocuments(query);

    res.json({
      movies,
      page: parseInt(page),
      pages: Math.ceil(total / limit),
      total
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.get('/coming-soon', protect, async (req, res) => {
  try {
    const movies = await Movie.find({ contentType: 'coming_soon' }).sort('-createdAt');
    res.json(movies);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.get('/:id', protect, async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ message: 'Invalid movie ID' });
    }
    const movie = await Movie.findById(req.params.id);
    if (movie) {
      res.json(movie);
    } else {
      res.status(404).json({ message: 'Movie not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
