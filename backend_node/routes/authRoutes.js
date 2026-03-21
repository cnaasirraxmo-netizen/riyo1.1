const express = require('express');
const router = express.Router();
const { login, requestPasswordReset } = require('../controllers/authController');

router.post('/login', login);
router.post('/request-reset', requestPasswordReset);

module.exports = router;
