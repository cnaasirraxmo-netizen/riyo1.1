const express = require('express');
const router = express.Router();
const { updateProfile, getProfile } = require('../controllers/adminController');
const { protect, adminOnly } = require('../middleware/authMiddleware');

router.use(protect);
router.use(adminOnly);

router.get('/profile', getProfile);
router.put('/profile', updateProfile);

module.exports = router;
