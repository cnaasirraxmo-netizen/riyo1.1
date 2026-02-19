const jwt = require('jsonwebtoken');
const { admin } = require('../utils/firebase');
const User = require('../models/User');

const protect = async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];

    try {
      // 1. Try to verify as Firebase token first (if Firebase is initialized)
      if (admin && admin.apps.length > 0) {
        try {
          const decodedFirebase = await admin.auth().verifyIdToken(token);
          let user = await User.findOne({ firebaseUid: decodedFirebase.uid });

          if (!user) {
            // Check if user exists by email but not yet linked to Firebase
            user = await User.findOne({ email: decodedFirebase.email.toLowerCase() });
            if (user) {
              user.firebaseUid = decodedFirebase.uid;
              await user.save();
            } else {
              // Auto-create user from Firebase data
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
          // If it's a "token expired" or other auth error, we might still want to try JWT
          // but usually, if it starts with a certain header or looks like a JWT, we know.
        }
      }

      // 2. Try to verify as our custom JWT
      const decodedJwt = jwt.verify(token, process.env.JWT_SECRET);
      req.user = await User.findById(decodedJwt.id).select('-password');

      if (!req.user) {
        return res.status(401).json({ message: 'User not found associated with this token' });
      }

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
  const adminRoles = ['admin', 'super-admin', 'content-admin', 'support-admin', 'analytics-admin', 'moderator'];
  if (req.user && adminRoles.includes(req.user.role)) {
    return next();
  } else {
    return res.status(403).json({ message: 'Not authorized as an admin' });
  }
};

const hasPermission = (permission) => {
  return (req, res, next) => {
    if (req.user && (req.user.role === 'super-admin' || req.user.role === 'admin' || (req.user.permissions && req.user.permissions[permission]))) {
      return next();
    } else {
      return res.status(403).json({ message: `Access denied. Missing permission: ${permission}` });
    }
  };
};

const premium = (req, res, next) => {
  if (req.user && (req.user.subscription.status === 'active' || req.user.role === 'admin')) {
    return next();
  } else {
    return res.status(403).json({ message: 'Premium subscription required' });
  }
};

module.exports = { protect, adminOnly, hasPermission, premium };
