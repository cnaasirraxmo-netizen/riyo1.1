const express = require('express');
const Category = require('../models/Category');
const HomeSection = require('../models/HomeSection');
const router = express.Router();

// --- Categories (Header Filters) ---

router.get('/categories', async (req, res) => {
  try {
    const categories = await Category.find().sort('order');
    res.json(categories);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/categories', async (req, res) => {
  const { name, order } = req.body;
  try {
    const category = new Category({ name, order });
    const saved = await category.save();
    res.status(201).json(saved);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

router.put('/categories/:id', async (req, res) => {
  try {
    const updated = await Category.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(updated);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

router.delete('/categories/:id', async (req, res) => {
  try {
    await Category.findByIdAndDelete(req.params.id);
    res.json({ message: 'Category deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/categories/reorder', async (req, res) => {
  const { items } = req.body;
  try {
    for (const item of items) {
      await Category.findByIdAndUpdate(item.id, { order: item.order });
    }
    res.json({ message: 'Categories reordered' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// --- Home Sections ---

router.get('/home-sections', async (req, res) => {
  try {
    const sections = await HomeSection.find().sort('order');
    res.json(sections);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/home-sections', async (req, res) => {
  const { title, type, genre, order } = req.body;
  try {
    const section = new HomeSection({ title, type, genre, order });
    const saved = await section.save();
    res.status(201).json(saved);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

router.put('/home-sections/:id', async (req, res) => {
  try {
    const updated = await HomeSection.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(updated);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

router.delete('/home-sections/:id', async (req, res) => {
  try {
    await HomeSection.findByIdAndDelete(req.params.id);
    res.json({ message: 'Home section deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/home-sections/reorder', async (req, res) => {
  const { items } = req.body;
  try {
    for (const item of items) {
      await HomeSection.findByIdAndUpdate(item.id, { order: item.order });
    }
    res.json({ message: 'Sections reordered' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
