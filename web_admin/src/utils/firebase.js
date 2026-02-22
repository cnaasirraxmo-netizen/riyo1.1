import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyCMDafOlxq2pDDAR_NmKUn-LBpUNmc8Uho",
  authDomain: "riobox-73d08.firebaseapp.com",
  projectId: "riobox-73d08",
  storageBucket: "riobox-73d08.firebasestorage.app",
  messagingSenderId: "243412248404",
  appId: "1:243412248404:web:69f26829cf8cc6137f4ac1"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
