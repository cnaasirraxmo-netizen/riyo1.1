const admin = require('firebase-admin');

// Initialize Firebase Admin
// In a real environment, this would use a service account JSON file
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(), // Fallback for environments with ADC
    });
  } catch (error) {
    console.warn('Firebase Admin not initialized: Service account missing. Using MOCK mode for development.');
  }
}

const User = require('../models/User');

const protect = async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];

      let decodedToken;
      if (process.env.NODE_ENV === 'test' || !admin.apps.length) {
        // MOCK AUTH for testing/dev without Firebase credentials
        decodedToken = { uid: 'mock-uid', email: 'user@example.com' };
      } else {
        decodedToken = await admin.auth().verifyIdToken(token);
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
      console.error('Auth Error:', error);
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
