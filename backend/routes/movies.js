const express = require('express');
const mongoose = require('mongoose');
const Movie = require('../models/Movie');
const Review = require('../models/Review');
const { protect } = require('../middleware/authMiddleware');
const router = express.Router();

router.get('/', protect, async (req, res) => {
  try {
    const { genre, year, rating, search, isTrending, sort } = req.query;
    let query = {};

    if (genre) query.genre = genre;
    if (year) query.year = parseInt(year);
    if (rating) query.rating = { $gte: parseFloat(rating) };
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }
    if (isTrending) query.isTrending = isTrending === 'true';

    let sortOption = { createdAt: -1 }; // Default: Newest
    if (sort === 'rating') sortOption = { rating: -1 };
    if (sort === 'oldest') sortOption = { createdAt: 1 };
    if (sort === 'title') sortOption = { title: 1 };

    const movies = await Movie.find(query).sort(sortOption);
    res.json(movies);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Get trending movies (real-time trending logic placeholder)
router.get('/trending', protect, async (req, res) => {
  try {
    // For now, return movies marked as trending, sorted by views (to be implemented) or rating
    const movies = await Movie.find({ isTrending: true }).sort({ rating: -1 }).limit(10);
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
      const reviews = await Review.find({ movie: movie._id, isApproved: true }).populate('user', 'name profilePicture');

      const movieData = movie.toObject();
      // Hide videoUrl for premium content if user is not premium
      if (movieData.isPremium && (!req.user || (req.user.subscription.status !== 'active' && req.user.role !== 'admin'))) {
        movieData.videoUrl = '';
        movieData.isLocked = true;
      }

      res.json({ ...movieData, reviews });
    } else {
      res.status(404).json({ message: 'Movie not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Add a review
router.post('/:id/reviews', protect, async (req, res) => {
  try {
    const { rating, comment } = req.body;
    const movieId = req.params.id;

    if (!mongoose.Types.ObjectId.isValid(movieId)) {
      return res.status(400).json({ message: 'Invalid movie ID' });
    }

    const movie = await Movie.findById(movieId);
    if (!movie) return res.status(404).json({ message: 'Movie not found' });

    const alreadyReviewed = await Review.findOne({ user: req.user._id, movie: movieId });
    if (alreadyReviewed) return res.status(400).json({ message: 'Movie already reviewed' });

    const review = await Review.create({
      user: req.user._id,
      movie: movieId,
      rating: Number(rating),
      comment
    });

    // Update movie average rating
    const reviews = await Review.find({ movie: movieId });
    const avgRating = reviews.reduce((acc, item) => item.rating + acc, 0) / reviews.length;
    movie.rating = avgRating;
    await movie.save();

    res.status(201).json(review);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
