const express = require('express');
const mongoose = require('mongoose');
const Movie = require('../models/Movie');
const Review = require('../models/Review');
const { protect, adminOnly } = require('../middleware/authMiddleware');
const router = express.Router();

// Bulk Actions (Move this above /:id to prevent conflict)
router.post('/bulk', protect, adminOnly, async (req, res) => {
  try {
    const { action, movieIds, data } = req.body;

    if (!Array.isArray(movieIds) || movieIds.length === 0) {
      return res.status(400).json({ message: 'No movie IDs provided' });
    }

    switch (action) {
      case 'delete':
        await Movie.deleteMany({ _id: { $in: movieIds } });
        return res.json({ message: `${movieIds.length} items deleted` });
      case 'publish':
        await Movie.updateMany({ _id: { $in: movieIds } }, { status: 'Public' });
        return res.json({ message: `${movieIds.length} items published` });
      case 'mark-premium':
        await Movie.updateMany({ _id: { $in: movieIds } }, { isPremium: true });
        return res.json({ message: `${movieIds.length} items marked as premium` });
      case 'add-to-collection':
        await Movie.updateMany({ _id: { $in: movieIds } }, { collectionName: data.collectionName });
        return res.json({ message: `${movieIds.length} items added to collection ${data.collectionName}` });
      default:
        return res.status(400).json({ message: 'Invalid bulk action' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

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
// Create a movie (Admin)
router.post('/', protect, adminOnly, async (req, res) => {
  try {
    const movie = await Movie.create(req.body);
    res.status(201).json(movie);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update a movie (Admin)
router.put('/:id', protect, adminOnly, async (req, res) => {
  try {
    const movie = await Movie.findById(req.params.id);
    if (!movie) return res.status(404).json({ message: 'Movie not found' });

    Object.assign(movie, req.body);
    const updatedMovie = await movie.save();
    res.json(updatedMovie);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Delete a movie (Admin)
router.delete('/:id', protect, adminOnly, async (req, res) => {
  try {
    const movie = await Movie.findById(req.params.id);
    if (!movie) return res.status(404).json({ message: 'Movie not found' });

    await movie.deleteOne();
    res.json({ message: 'Movie removed' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

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
