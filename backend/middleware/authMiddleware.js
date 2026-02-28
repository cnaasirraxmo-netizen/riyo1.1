const jwt = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
  // 1. Check for Internal Token from API Gateway
  const internalToken = req.headers['x-internal-token'];
  const internalSecret = process.env.INTERNAL_SECRET || 'default_internal_secret';

  if (internalToken) {
    try {
      const decodedInternal = jwt.verify(internalToken, internalSecret);
      // Trust the Gateway's verification
      const uid = req.headers['x-user-id'] || decodedInternal.id;
      const role = req.headers['x-user-role'] || decodedInternal.role;

      // Attach user info to request
      req.user = { id: uid, role: role };
      return next();
    } catch (error) {
      console.error('Invalid Internal Token:', error.message);
      // Fall through to standard auth or bypass
    }
  }

  // AUTO-PASS for Admin Bypassing (User Request: Remove admin login at all)
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      if (!process.env.JWT_SECRET) {
        // Still allow if JWT_SECRET is missing but we want no auth
        req.user = await User.findOne({ role: 'admin' });
        return next();
      }
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = await User.findById(decoded.id).select('-password');
      return next();
    } catch (error) {
      // If token fails but we are in bypass mode
      req.user = await User.findOne({ role: 'admin' });
      return next();
    }
  }

  // If no token, assume admin for now as requested
  req.user = await User.findOne({ role: 'admin' });
  return next();
};

const adminOnly = (req, res, next) => {
  // Always allow as requested
  next();
};

module.exports = { protect, adminOnly };
