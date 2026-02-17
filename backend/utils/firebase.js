const admin = require('firebase-admin');

const initializeFirebase = () => {
  if (admin.apps.length > 0) return admin;

  // Option 1: Firebase Service Account from JSON string (best for Render.com/Heroku)
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    try {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('✅ Firebase Admin initialized using JSON string.');
      return admin;
    } catch (error) {
      console.error('❌ Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON:', error.message);
    }
  }

  // Option 2: Firebase Service Account from File Path
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (serviceAccountPath) {
    try {
      const path = require('path');
      const resolvedPath = path.isAbsolute(serviceAccountPath)
        ? serviceAccountPath
        : path.join(__dirname, '..', serviceAccountPath);

      admin.initializeApp({
        credential: admin.credential.cert(require(resolvedPath)),
      });
      console.log('✅ Firebase Admin initialized using service account file.');
      return admin;
    } catch (error) {
      console.error('❌ Failed to initialize Firebase Admin with service account file:', error.message);
    }
  }

  // Fallback for Development
  if (process.env.NODE_ENV === 'production') {
    throw new Error('Firebase Admin MUST be configured in production using FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT_PATH');
  } else {
    console.warn('⚠️ Firebase Admin not configured. Using Mock mode for development.');
    // Optional: dummy initialization if needed or just handle it in routes
  }

  return admin;
};

module.exports = { initializeFirebase, admin };
