const { admin } = require('../utils/firebase');
const User = require('../models/User');

const protect = async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];

      let decodedToken;
      // Check if we are in mock mode (no firebase apps initialized)
      if (admin.apps.length === 0) {
        // development mock
        decodedToken = { uid: 'mock-uid', email: 'user@example.com', name: 'Mock User' };
      } else {
        decodedToken = await admin.auth().verifyIdToken(token);
      }

      if (!decodedToken) {
        return res.status(401).json({ message: 'Not authorized, token invalid' });
      }

      // Sync user with MongoDB
      let user = await User.findOne({ firebaseUid: decodedToken.uid });
      if (!user) {
        user = await User.create({
          firebaseUid: decodedToken.uid,
          email: decodedToken.email,
          name: decodedToken.name || 'User',
          profiles: [{ name: decodedToken.name || 'Default', avatar: '' }]
        });
      }

      req.user = user;
      return next();
    } catch (error) {
      console.error('Auth Error:', error.message);
      return res.status(401).json({ message: 'Not authorized, token failed' });
    }
  }

  if (!token) {
    return res.status(401).json({ message: 'Not authorized, no token' });
  }
};

const adminOnly = (req, res, next) => {
  if (req.user && req.user.role === 'admin') {
    next();
  } else {
    return res.status(403).json({ message: 'Not authorized as an admin' });
  }
};

const premium = (req, res, next) => {
  if (req.user && (req.user.subscription.status === 'active' || req.user.role === 'admin')) {
    next();
  } else {
    return res.status(403).json({ message: 'Premium subscription required to access this content' });
  }
};

module.exports = { protect, adminOnly, premium };
