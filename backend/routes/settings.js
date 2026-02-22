const express = require('express');
const AppSetting = require('../models/AppSetting');
const { protect, adminOnly } = require('../middleware/authMiddleware');
const router = express.Router();

router.get('/', async (req, res) => {
  try {
    const settings = await AppSetting.find();
    const config = {};
    settings.forEach(s => config[s.key] = s.value);
    res.json(config);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.post('/', protect, adminOnly, async (req, res) => {
  try {
    const { key, value, group, description } = req.body;
    const setting = await AppSetting.findOneAndUpdate(
      { key },
      { value, group, description },
      { upsert: true, new: true }
    );
    res.json(setting);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
