const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { admin } = require('../utils/firebase');
const { generateAccessToken, generateRefreshToken } = require('../utils/auth');
const router = express.Router();

const generateToken = (id) => {
  if (!process.env.JWT_SECRET) {
    throw new Error('JWT_SECRET is missing from environment variables');
  }
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

// Register with Email/Password
router.post('/register', async (req, res) => {
  const { name, email, password } = req.body;
  try {
    const userExists = await User.findOne({ email: email.toLowerCase() });
    if (userExists) {
      return res.status(400).json({ message: 'User with this email already exists' });
    }

    const user = await User.create({
      name,
      email: email.toLowerCase(),
      password,
      role: 'user',
      profiles: [{ name: name || 'Primary' }] // Create a default profile
    });

    res.status(201).json({
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      token: generateToken(user._id)
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: 'Error registering user' });
  }
});

// Login with Email/Password (Regular User)
router.post('/login', async (req, res) => {
  const { email, username, password } = req.body;
  const loginIdentifier = email || username;
  try {
    const user = await User.findOne({
      $or: [
        { email: loginIdentifier?.toLowerCase() },
        { username: loginIdentifier }
      ]
    });
    if (user && (await user.comparePassword(password))) {
      res.json({
        _id: user._id,
        name: user.name,
        email: user.email,
        username: user.username,
        role: user.role,
        token: generateAccessToken(user._id)
      });
    } else {
      res.status(401).json({ message: 'Invalid email or password' });
    }
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Error logging in' });
  }
});

// Admin Login with advanced security
router.post('/admin/login', async (req, res) => {
  const { email, username, password, rememberMe } = req.body;
  const loginIdentifier = email || username;
  const MAX_ATTEMPTS = 5;
  const LOCK_TIME = 2 * 60 * 60 * 1000; // 2 hours

  try {
    const user = await User.findOne({
      $or: [
        { email: loginIdentifier?.toLowerCase() },
        { username: loginIdentifier }
      ]
    });

    if (!user || !['admin', 'super-admin', 'content-admin', 'support-admin', 'analytics-admin', 'moderator'].includes(user.role)) {
      return res.status(401).json({ message: 'Access denied. Admin credentials required.' });
    }

    // Check if account is locked
    if (user.isLocked) {
      return res.status(403).json({ message: 'Account is temporarily locked due to too many failed attempts. Try again later.' });
    }

    if (await user.comparePassword(password)) {
      // Success: Reset failed attempts
      user.loginAttempts = 0;
      user.lockUntil = undefined;

      const accessToken = generateAccessToken(user._id);
      const refreshToken = generateRefreshToken(user._id, rememberMe);

      user.refreshToken = refreshToken;
      await user.save();

      res.json({
        _id: user._id,
        name: user.name,
        email: user.email,
        username: user.username,
        role: user.role,
        permissions: user.permissions,
        token: accessToken,
        refreshToken: refreshToken
      });
    } else {
      // Failed: Increment attempts
      user.loginAttempts += 1;
      if (user.loginAttempts >= MAX_ATTEMPTS) {
        user.lockUntil = Date.now() + LOCK_TIME;
      }
      await user.save();

      const attemptsLeft = MAX_ATTEMPTS - user.loginAttempts;
      res.status(401).json({
        message: 'Invalid password',
        attemptsLeft: attemptsLeft > 0 ? attemptsLeft : 0
      });
    }
  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({ message: 'Error logging in' });
  }
});

// Refresh Token Route
router.post('/refresh-token', async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) return res.status(401).json({ message: 'Refresh token required' });

  try {
    const decoded = jwt.verify(refreshToken, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id);

    if (!user || user.refreshToken !== refreshToken) {
      return res.status(401).json({ message: 'Invalid refresh token' });
    }

    const newAccessToken = generateAccessToken(user._id);
    res.json({ token: newAccessToken });
  } catch (error) {
    res.status(401).json({ message: 'Invalid or expired refresh token' });
  }
});

// Firebase Auth Login/Register (Sync)
router.post('/firebase', async (req, res) => {
  const { idToken } = req.body;
  if (!idToken) return res.status(400).json({ message: 'idToken is required' });

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const { uid, email, name, picture } = decodedToken;

    let user = await User.findOne({
      $or: [{ firebaseUid: uid }, { email: email.toLowerCase() }]
    });

    if (!user) {
      // Create new user from Firebase data
      user = await User.create({
        firebaseUid: uid,
        email: email.toLowerCase(),
        name: name || email.split('@')[0],
        role: 'user',
        profiles: [{ name: name || 'Primary', avatar: picture || '' }]
      });
    } else if (!user.firebaseUid) {
      // Link existing email account with Firebase
      user.firebaseUid = uid;
      await user.save();
    }

    res.json({
      _id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      token: generateToken(user._id)
    });
  } catch (error) {
    console.error('Firebase sync error:', error);
    res.status(401).json({ message: 'Invalid Firebase token' });
  }
});

module.exports = router;
