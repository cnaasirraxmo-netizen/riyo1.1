const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { admin } = require('../utils/firebase');
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

// Login with Email/Password
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email: email.toLowerCase() });
    if (user && (await user.comparePassword(password))) {
      res.json({
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        token: generateToken(user._id)
      });
    } else {
      res.status(401).json({ message: 'Invalid email or password' });
    }
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Error logging in' });
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
