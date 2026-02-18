import React, { useState } from 'react';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { auth } from '../utils/firebase';
import api from '../utils/api';
import { Shield, Lock, Mail, AlertCircle, ChevronRight, Activity } from 'lucide-react';

const Login = ({ onLogin }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const token = await userCredential.user.getIdToken();

      const response = await api.get('/users/account', {
        headers: { Authorization: `Bearer ${token}` }
      });

      if (response.data.role !== 'admin') {
        await auth.signOut();
        setError('UNAUTHORIZED: Administrative privileges required for this node.');
        setLoading(false);
        return;
      }

      onLogin(token, response.data.role);
    } catch (err) {
      console.error(err);
      setError('AUTHENTICATION FAILED: Invalid credentials or network disruption.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-[#0F0F0F] px-6 relative overflow-hidden">
      {/* Decorative Elements */}
      <div className="absolute top-0 left-0 w-full h-full opacity-20 pointer-events-none">
        <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-purple-600 rounded-full blur-[120px]"></div>
        <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-indigo-600 rounded-full blur-[120px]"></div>
      </div>

      <div className="max-w-xl w-full space-y-8 relative z-10">
        <div className="text-center space-y-4">
          <div className="inline-flex items-center justify-center w-20 h-20 rounded-[28px] bg-gradient-to-br from-purple-600 to-indigo-600 shadow-2xl shadow-purple-600/20 mb-4 transform rotate-12">
            <Shield size={40} className="text-white transform -rotate-12" />
          </div>
          <h1 className="text-6xl font-black text-white tracking-tighter leading-none italic">
            RIYO<span className="text-purple-600">BOX</span>
          </h1>
          <p className="text-gray-500 font-black uppercase tracking-[0.4em] text-xs">Administrative Protocol Alpha</p>
        </div>

        <div className="bg-[#1C1C1C] p-12 rounded-[48px] border border-white/5 shadow-2xl backdrop-blur-xl relative group">
          <div className="absolute inset-0 bg-white/5 opacity-0 group-hover:opacity-100 transition-opacity rounded-[48px] pointer-events-none"></div>

          {error && (
            <div className="bg-red-500/10 border border-red-500/20 text-red-500 p-6 rounded-3xl mb-8 flex items-center gap-4 animate-in slide-in-from-top-2 duration-300">
              <AlertCircle size={20} />
              <span className="text-xs font-black uppercase tracking-widest leading-tight">{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-8">
            <div className="space-y-2">
              <label className="text-[10px] font-black text-gray-500 uppercase tracking-[0.2em] ml-2">Identity Token (Email)</label>
              <div className="relative group/input">
                <Mail className="absolute left-6 top-1/2 -translate-y-1/2 text-gray-600 group-focus-within/input:text-purple-500 transition-colors" size={20} />
                <input
                  type="email"
                  required
                  className="w-full bg-black/40 border border-white/5 rounded-3xl pl-16 pr-8 py-5 text-white focus:outline-none focus:border-purple-500 transition-all font-medium placeholder:text-gray-700"
                  placeholder="admin@riyobox.sys"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-[10px] font-black text-gray-500 uppercase tracking-[0.2em] ml-2">Access Key (Password)</label>
              <div className="relative group/input">
                <Lock className="absolute left-6 top-1/2 -translate-y-1/2 text-gray-600 group-focus-within/input:text-purple-500 transition-colors" size={20} />
                <input
                  type="password"
                  required
                  className="w-full bg-black/40 border border-white/5 rounded-3xl pl-16 pr-8 py-5 text-white focus:outline-none focus:border-purple-500 transition-all font-medium placeholder:text-gray-700"
                  placeholder="••••••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-white hover:bg-gray-100 text-black font-black py-6 rounded-3xl transition-all transform active:scale-[0.98] disabled:opacity-50 shadow-xl flex items-center justify-center gap-3 uppercase tracking-[0.2em] text-xs"
            >
              {loading ? (
                <Activity size={20} className="animate-spin text-purple-600" />
              ) : (
                <>
                  Establish Connection
                  <ChevronRight size={18} />
                </>
              )}
            </button>
          </form>
        </div>

        <div className="flex items-center justify-between px-8 text-gray-600">
           <div className="flex items-center gap-2">
              <div className="w-1.5 h-1.5 bg-green-500 rounded-full animate-pulse"></div>
              <span className="text-[9px] font-black uppercase tracking-widest">Encrypted Session</span>
           </div>
           <span className="text-[9px] font-black uppercase tracking-widest opacity-40">System Build v1.0.4-PRO</span>
        </div>
      </div>
    </div>
  );
};

export default Login;
