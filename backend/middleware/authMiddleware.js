const jwt = require('jsonwebtoken');
const { admin } = require('../utils/firebase');
const User = require('../models/User');

const protect = async (req, res, next) => {
  let token;

  // 1. Get token from headers
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];

    try {
      // 2. Verify Firebase token if admin initialized
      if (admin && admin.apps.length > 0) {
        try {
          const decodedFirebase = await admin.auth().verifyIdToken(token);

          if (!decodedFirebase || !decodedFirebase.uid) {
            return res.status(401).json({ message: 'Invalid Firebase token' });
          }

          // Find user by firebaseUid
          let user = await User.findOne({ firebaseUid: decodedFirebase.uid });

          // If no user by UID, check by email
          if (!user) {
            user = await User.findOne({ email: decodedFirebase.email.toLowerCase() });

            if (user) {
              // Link Firebase UID to existing user
              user.firebaseUid = decodedFirebase.uid;
              await user.save();
            } else {
              // Create new user from Firebase data
              user = await User.create({
                firebaseUid: decodedFirebase.uid,
                email: decodedFirebase.email.toLowerCase(),
                name: decodedFirebase.name || decodedFirebase.email.split('@')[0],
                profiles: [{ name: decodedFirebase.name || 'Primary' }]
              });
            }
          }

          req.user = user;
          return next();
        } catch (firebaseErr) {
          console.warn('Firebase verification failed:', firebaseErr.message);
          // Continue to try JWT if Firebase token verification fails
        }
      }

      // 3. Verify custom JWT token
      const decodedJwt = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decodedJwt.id).select('-password');

      if (!user) {
        return res.status(401).json({ message: 'User not found associated with this token' });
      }

      req.user = user;
      return next();

    } catch (error) {
      console.error('Auth Error:', error.message);
      return res.status(401).json({ message: 'Not authorized, token failed' });
    }
  } else {
    return res.status(401).json({ message: 'Not authorized, no token' });
  }
};

// Admin only middleware
const adminOnly = (req, res, next) => {
  if (req.user && req.user.role === 'admin') {
    return next();
  } else {
    return res.status(403).json({ message: 'Not authorized as an admin' });
  }
};

// Premium subscription middleware
const premium = (req, res, next) => {
  if (req.user && (req.user.subscription?.status === 'active' || req.user.role === 'admin')) {
    return next();
  } else {
    return res.status(403).json({ message: 'Premium subscription required' });
  }
};

module.exports = { protect, adminOnly, premium };
