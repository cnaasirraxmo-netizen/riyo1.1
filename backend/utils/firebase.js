const admin = require('firebase-admin');

const initializeFirebase = () => {
  if (admin.apps.length) return admin;

  if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error('Firebase Admin not configured.');
    }
    console.log('ℹ️ Running without Firebase (dev mode).');
    return admin;
  }

  const serviceAccount = JSON.parse(
    process.env.FIREBASE_SERVICE_ACCOUNT
  );

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  console.log('✅ Firebase Admin initialized.');

  return admin;
};

module.exports = { initializeFirebase, admin };
