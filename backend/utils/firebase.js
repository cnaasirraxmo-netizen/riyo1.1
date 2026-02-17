const admin = require('firebase-admin');

const initializeFirebase = () => {
  if (admin.apps.length > 0) return admin;

  const serviceAccountJSON = process.env.FIREBASE_SERVICE_ACCOUNT;

  if (!serviceAccountJSON) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('Firebase Admin MUST be configured in production.');
    }
    console.log('ℹ️ Using Firebase Mock mode for development.');
    return admin;
  }

  try {
    const serviceAccount = JSON.parse(serviceAccountJSON);

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

    console.log('✅ Firebase Admin initialized using environment variable.');
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin:', error.message);
    throw error;
  }

  return admin;
};

module.exports = { initializeFirebase, admin };
