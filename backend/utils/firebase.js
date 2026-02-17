const admin = require('firebase-admin');
const path = require('path');

const initializeFirebase = () => {
  if (admin.apps.length > 0) return admin;

  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

  if (serviceAccountPath) {
    try {
      const resolvedPath = path.isAbsolute(serviceAccountPath)
        ? serviceAccountPath
        : path.join(__dirname, '..', serviceAccountPath);

      admin.initializeApp({
        credential: admin.credential.cert(require(resolvedPath)),
      });
      console.log('✅ Firebase Admin initialized using service account.');
    } catch (error) {
      console.error('❌ Failed to initialize Firebase Admin with service account:', error.message);
      _initializeMock();
    }
  } else {
    console.warn('⚠️ FIREBASE_SERVICE_ACCOUNT_PATH not set.');
    _initializeMock();
  }

  return admin;
};

const _initializeMock = () => {
  if (process.env.NODE_ENV === 'production') {
    throw new Error('Firebase Admin MUST be configured in production.');
  }
  console.log('ℹ️ Using Firebase Mock mode for development.');
};

module.exports = { initializeFirebase, admin };
