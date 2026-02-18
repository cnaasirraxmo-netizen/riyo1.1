import { initializeApp } from "firebase/app";
import { getAuth, GoogleAuthProvider } from "firebase/auth";
import { getMessaging, getToken, onMessage } from "firebase/messaging";

const firebaseConfig = {
  // These should be populated from environment variables
  apiKey: "AIzaSyCMDafOlxq2pDDAR_NmKUn-LBpUNmc8Uho",
  authDomain: "riobox-73d08.firebaseapp.com",
  projectId: "riobox-73d08",
  storageBucket: "riobox-73d08.firebasestorage.app",
  messagingSenderId: "243412248404",
  appId: "1:243412248404:web:69f26829cf8cc6137f4ac1"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const googleProvider = new GoogleAuthProvider();
export const messaging = getMessaging(app);

export const requestForToken = () => {
  return getToken(messaging, { vapidKey: 'YOUR_VAPID_KEY' })
    .then((currentToken) => {
      if (currentToken) {
        console.log('current token for client: ', currentToken);
        return currentToken;
      } else {
        console.log('No registration token available. Request permission to generate one.');
      }
    })
    .catch((err) => {
      console.log('An error occurred while retrieving token. ', err);
    });
};

export const onMessageListener = () =>
  new Promise((resolve) => {
    onMessage(messaging, (payload) => {
      console.log("payload", payload);
      resolve(payload);
    });
  });

export default app;
