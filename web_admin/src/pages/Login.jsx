import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../utils/api';

const Login = ({ onLogin }) => {
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [twoFACode, setTwoFACode] = useState('');
  const [show2FA, setShow2FA] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  // Auto-Redirect to Dashboard if token and role exist
  useEffect(() => {
    const token = localStorage.getItem('token');
    const role = localStorage.getItem('role');
    if (token && role === 'admin') {
      // If token exists and role is admin, go to dashboard
      navigate('/dashboard');
    }
  }, [navigate]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      // Send request to the backend with identifier (email/username) and password
      const response = await api.post('/auth/login', {
        identifier,
        password,
        rememberMe,
        '2faCode': twoFACode
      });

      if (response.data.require2FA) {
        setShow2FA(true);
        setLoading(false);
        return;
      }

      if (response.data.role !== 'admin') {
        setError('Unauthorized: Only admins can access this panel.');
        setLoading(false);
        return;
      }

      const { token, role } = response.data;
      localStorage.setItem('token', token);
      localStorage.setItem('role', role);

      if (onLogin) onLogin(token, role);
      // Redirect user to the dashboard after successful login
      navigate('/dashboard');
    } catch (err) {
      setError(err.response?.data?.message || 'Login failed. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#141414] px-4">
      <div className="max-w-md w-full bg-[#1C1C1C] p-8 rounded-lg shadow-xl border border-white/5">
        <div className="text-center mb-10">
          <h1 className="text-4xl font-black text-purple-500 tracking-tighter">RIYO</h1>
          <p className="text-gray-400 mt-2">Admin Control Center</p>
        </div>

        {error && (
          <div className="bg-red-500/10 border border-red-500/50 text-red-500 p-3 rounded mb-6 text-sm text-center">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          {!show2FA ? (
            <>
              <div>
                <label className="block text-sm font-medium text-gray-400 mb-2">Username or Email</label>
                <input
                  type="text"
                  required
                  className="w-full bg-[#262626] border border-white/10 rounded px-4 py-3 focus:outline-none focus:border-purple-500 transition-colors text-white"
                  placeholder="sahan or admin@example.com"
                  value={identifier}
                  onChange={(e) => setIdentifier(e.target.value)}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-400 mb-2">Password</label>
                <input
                  type="password"
                  required
                  className="w-full bg-[#262626] border border-white/10 rounded px-4 py-3 focus:outline-none focus:border-purple-500 transition-colors text-white"
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                />
              </div>
            </>
          ) : (
            <div>
              <label className="block text-sm font-medium text-purple-500 mb-2">2FA Authentication Code</label>
              <input
                type="text"
                required
                autoFocus
                className="w-full bg-[#262626] border border-purple-500/50 rounded px-4 py-3 focus:outline-none focus:border-purple-500 transition-colors text-white text-center text-2xl tracking-[1em]"
                placeholder="000000"
                maxLength="6"
                value={twoFACode}
                onChange={(e) => setTwoFACode(e.target.value)}
              />
              <p className="text-xs text-gray-500 mt-2 text-center">Enter the code from your Authenticator app</p>
            </div>
          )}

          <div className="flex items-center justify-between">
            <label className="flex items-center space-x-2 cursor-pointer group">
              <input
                type="checkbox"
                className="w-4 h-4 rounded border-white/10 bg-[#262626] text-purple-600 focus:ring-purple-500 focus:ring-offset-0"
                checked={rememberMe}
                onChange={(e) => setRememberMe(e.target.checked)}
              />
              <span className="text-sm text-gray-400 group-hover:text-gray-300 transition-colors">Remember me</span>
            </label>
            <button
              type="button"
              onClick={() => navigate('/forgot-password')}
              className="text-sm text-purple-500 hover:text-purple-400 transition-colors"
            >
              Forgot password?
            </button>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-purple-600 hover:bg-purple-700 text-white font-bold py-3 rounded transition-all transform active:scale-[0.98] disabled:opacity-50"
          >
            {loading ? 'VERIFYING...' : (show2FA ? 'VERIFY CODE' : 'SIGN IN')}
          </button>

          {show2FA && (
            <button
              type="button"
              onClick={() => setShow2FA(false)}
              className="w-full text-sm text-gray-500 hover:text-white transition-colors"
            >
              Back to Login
            </button>
          )}
        </form>

        <p className="mt-8 text-center text-xs text-gray-500">
          Secure access only. Unauthorized attempts are logged.
        </p>
      </div>
    </div>
  );
};

export default Login;
