const jwt = require('jsonwebtoken');
const User = require('../models/User');
const admin = require('firebase-admin');

const generateToken = (id, rememberMe) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: rememberMe ? '30d' : '1h'
  });
};

const login = async (req, res) => {
  const { identifier, password, rememberMe } = req.body; // identifier can be email or username

  try {
    const user = await User.findOne({
      $or: [{ email: identifier }, { username: identifier }]
    });

    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    if (user.isLocked()) {
      return res.status(423).json({
        message: `Account locked. Try again after ${user.lockUntil.toLocaleTimeString()}`
      });
    }

    const isMatch = await user.comparePassword(password);

    if (!isMatch) {
      user.loginAttempts += 1;
      if (user.loginAttempts >= 5) {
        user.lockUntil = Date.now() + 15 * 60 * 1000; // 15 min lock
        user.loginAttempts = 0;
      }
      await user.save();
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Reset attempts on success
    user.loginAttempts = 0;
    user.lockUntil = undefined;
    user.lastLogin = Date.now();
    await user.save();

    res.json({
      _id: user._id,
      username: user.username,
      email: user.email,
      role: user.role,
      token: generateToken(user._id, rememberMe)
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const requestPasswordReset = async (req, res) => {
  const { email } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User with this email does not exist' });
    }

    const link = await admin.auth().generatePasswordResetLink(email);
    // Link would normally be sent via email, for this task we assume
    // the frontend handles the Firebase sendPasswordResetEmail call
    // or we use the link here.
    res.json({ message: 'Password reset link generated', link });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { login, requestPasswordReset };
