import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { ArrowLeft, Mail, Loader2, CheckCircle } from 'lucide-react';
import api from '../utils/api';

const ForgotPassword = () => {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      await api.post('/auth/forgot-password', { email });
      setSuccess(true);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to send reset code. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  if (success) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#141414] px-4">
        <div className="max-w-md w-full bg-[#1C1C1C] p-8 rounded-lg shadow-xl border border-white/5 text-center">
          <div className="flex justify-center mb-6">
            <CheckCircle size={64} className="text-green-500" />
          </div>
          <h2 className="text-2xl font-bold text-white mb-4">Check your email</h2>
          <p className="text-gray-400 mb-8">
            We've sent a password reset code to <span className="text-white font-medium">{email}</span>.
            Please check your inbox and follow the instructions.
          </p>
          <Link
            to="/reset-password"
            state={{ email }}
            className="block w-full bg-purple-600 hover:bg-purple-700 text-white font-bold py-3 rounded transition-all mb-4"
          >
            ENTER RESET CODE
          </Link>
          <button
            onClick={() => setSuccess(false)}
            className="text-gray-500 hover:text-white transition-colors text-sm"
          >
            Didn't receive code? Try again
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#141414] px-4">
      <div className="max-w-md w-full bg-[#1C1C1C] p-8 rounded-lg shadow-xl border border-white/5">
        <button
          onClick={() => navigate('/login')}
          className="flex items-center text-gray-500 hover:text-white mb-8 transition-colors text-sm group"
        >
          <ArrowLeft size={16} className="mr-2 group-hover:-translate-x-1 transition-transform" />
          Back to Login
        </button>

        <div className="mb-10 text-center">
          <h1 className="text-3xl font-bold text-white mb-2">Reset Password</h1>
          <p className="text-gray-400 text-sm">
            Enter your email address and we'll send you a 6-digit code to reset your password.
          </p>
        </div>

        {error && (
          <div className="bg-red-500/10 border border-red-500/50 text-red-500 p-3 rounded mb-6 text-sm text-center">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-400 mb-2">Email Address</label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500" size={18} />
              <input
                type="email"
                required
                className="w-full bg-[#262626] border border-white/10 rounded pl-10 pr-4 py-3 focus:outline-none focus:border-purple-500 transition-colors text-white"
                placeholder="admin@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-purple-600 hover:bg-purple-700 text-white font-bold py-3 rounded transition-all transform active:scale-[0.98] disabled:opacity-50 flex items-center justify-center gap-2"
          >
            {loading ? (
              <>
                <Loader2 size={18} className="animate-spin" />
                SENDING CODE...
              </>
            ) : (
              'SEND RESET CODE'
            )}
          </button>
        </form>
      </div>
    </div>
  );
};

export default ForgotPassword;
