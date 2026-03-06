const express = require('express');
const Movie = require('../models/Movie');
const User = require('../models/User');
const { protect, adminOnly } = require('../middleware/authMiddleware');
const router = express.Router();

router.post('/movies', protect, adminOnly, async (req, res) => {
  const {
    title, description, posterUrl, backdropUrl,
    videoUrl, trailerUrl, duration, year, genre,
    isTrending, isFeatured, contentType, contentRating
  } = req.body;

  try {
    const movie = new Movie({
      title, description, posterUrl, backdropUrl,
      videoUrl, trailerUrl, duration, year, genre,
      isTrending, isFeatured, contentType, contentRating,
      isPublished: contentType !== 'coming_soon'
    });
    const createdMovie = await movie.save();
    res.status(201).json(createdMovie);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.get('/movies', protect, adminOnly, async (req, res) => {
  try {
    const { page = 1, limit = 20, search } = req.query;
    let query = {};
    if (search) {
      query.title = { $regex: search, $options: 'i' };
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

// Publish Coming Soon movie
router.put('/movies/:id/publish', protect, adminOnly, async (req, res) => {
  try {
    const movie = await Movie.findById(req.params.id).populate('notifyUsers');
    if (!movie) return res.status(404).json({ message: 'Movie not found' });

    const { videoUrl, contentType } = req.body;
    movie.videoUrl = videoUrl || movie.videoUrl;
    movie.contentType = contentType || 'free';
    movie.isPublished = true;

    await movie.save();

    // Create notifications for interested users
    const Notification = require('../models/Notification');
    const notifications = movie.notifyUsers.map(user => ({
      user: user._id,
      title: 'Movie Released!',
      message: `${movie.title} is now available to watch!`,
      movie: movie._id
    }));

    if (notifications.length > 0) {
      await Notification.insertMany(notifications);
    }

    console.log(`Created notifications for ${movie.notifyUsers.length} users about publication of ${movie.title}`);

    res.json({ message: 'Movie published successfully', movie });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.delete('/movies/:id', protect, adminOnly, async (req, res) => {
  try {
    const movie = await Movie.findById(req.params.id);
    if (movie) {
      await movie.deleteOne();
      res.json({ message: 'Movie removed' });
    } else {
      res.status(404).json({ message: 'Movie not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.get('/users', protect, adminOnly, async (req, res) => {
  try {
    const users = await User.find({}).select('-password');
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
