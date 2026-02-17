import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { signInWithEmailAndPassword, signInWithPopup } from 'firebase/auth';
import { auth, googleProvider } from '../utils/firebase';
import api from '../utils/api';

const Login = ({ onLogin }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async (idToken) => {
    try {
      const response = await api.get('/users/account', {
        headers: { Authorization: `Bearer ${idToken}` }
      });
      onLogin(idToken, response.data);
    } catch (err) {
      setError('Failed to sync with backend. Please try again.');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const token = await userCredential.user.getIdToken();
      await handleLogin(token);
    } catch (err) {
      setError('Login failed. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleLogin = async () => {
    setError('');
    try {
      const result = await signInWithPopup(auth, googleProvider);
      const token = await result.user.getIdToken();
      await handleLogin(token);
    } catch (err) {
      setError('Google Login failed.');
    }
  };

  return (
    <div className="relative min-h-screen w-full flex items-center justify-center bg-black">
      <div className="absolute inset-0 z-0">
        <img
          src="https://picsum.photos/seed/riyobox/1920/1080"
          className="w-full h-full object-cover opacity-50 grayscale"
          alt="background"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black via-black/40 to-black"></div>
      </div>

      <div className="relative z-10 w-full max-w-md p-10 bg-black/75 rounded-lg border border-white/5 backdrop-blur-sm">
        <h1 className="text-3xl font-black text-purple-600 mb-8 tracking-tighter">RIYOBOX</h1>
        <h2 className="text-2xl font-bold mb-8">Sign In</h2>

        {error && <div className="bg-red-500/20 border border-red-500/50 text-red-500 p-3 rounded mb-6 text-sm">{error}</div>}

        <form onSubmit={handleSubmit} className="space-y-6">
          <input
            type="email"
            placeholder="Email"
            required
            className="w-full bg-[#333] border-none rounded px-4 py-3 focus:ring-2 focus:ring-purple-600 outline-none transition-all"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
          <input
            type="password"
            placeholder="Password"
            required
            className="w-full bg-[#333] border-none rounded px-4 py-3 focus:ring-2 focus:ring-purple-600 outline-none transition-all"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-purple-600 hover:bg-purple-700 py-3 rounded font-bold transition-colors disabled:opacity-50"
          >
            {loading ? 'Signing in...' : 'Sign In'}
          </button>
        </form>

        <div className="my-6 flex items-center">
           <div className="flex-1 border-t border-white/10"></div>
           <span className="px-4 text-xs text-gray-500">OR</span>
           <div className="flex-1 border-t border-white/10"></div>
        </div>

        <button
           onClick={handleGoogleLogin}
           className="w-full bg-white text-black py-3 rounded font-bold flex items-center justify-center space-x-2 hover:bg-gray-200 transition-colors"
        >
          <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png" className="h-5" alt="Google" />
          <span>Continue with Google</span>
        </button>

        <div className="mt-8 flex items-center justify-between text-xs text-gray-400 font-medium">
          <div className="flex items-center">
            <input type="checkbox" className="mr-2 rounded bg-gray-500 border-none" />
            <span>Remember me</span>
          </div>
          <span className="hover:underline cursor-pointer">Need help?</span>
        </div>

        <p className="mt-12 text-gray-500">
          New to RIYOBOX? <Link to="/signup" className="text-white font-bold hover:underline">Sign up now.</Link>
        </p>
      </div>
    </div>
  );
};

export default Login;
