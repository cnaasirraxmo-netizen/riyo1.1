
import React, { useState, useEffect } from 'react';
import { User, Mail, Lock, Shield, Save, CheckCircle } from 'lucide-react';
import api from '../utils/api';

const AdminProfile = () => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    username: '',
    password: '',
    confirmPassword: ''
  });
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const res = await api.get('/admin/stats'); // We don't have a direct "get self" but auth returns it
        // Usually self is kept in localStorage/context. Let's assume we can update from what we have.
        const storedUser = JSON.parse(localStorage.getItem('adminUser') || '{}');
        setFormData(prev => ({
          ...prev,
          name: storedUser.name || '',
          email: storedUser.email || '',
          username: storedUser.username || ''
        }));
      } catch (err) {
        console.error(err);
      }
    };
    fetchProfile();
  }, []);

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage(null);
    setError(null);

    if (formData.password && formData.password !== formData.confirmPassword) {
      setError("Passwords don't match");
      setLoading(false);
      return;
    }

    try {
      const updateData = {
        name: formData.name,
        email: formData.email,
        username: formData.username
      };
      if (formData.password) updateData.password = formData.password;

      const res = await api.put('/admin/profile', updateData);
      setMessage('Profile updated successfully!');

      // Update local storage
      localStorage.setItem('adminUser', JSON.stringify(res.data));
    } catch (err) {
      setError(err.response?.data?.message || 'Update failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-8 max-w-2xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-black text-white uppercase tracking-tight">Admin Headquarters</h1>
        <p className="text-gray-400 mt-1">Manage your administrative credentials and security.</p>
      </div>

      <div className="bg-[#1f2937] rounded-3xl border border-white/5 overflow-hidden shadow-2xl">
        <div className="bg-gradient-to-r from-[#0ea5e9] to-purple-600 p-8">
          <div className="flex items-center space-x-4">
             <div className="w-20 h-20 bg-white/20 backdrop-blur-xl rounded-2xl flex items-center justify-center text-white border border-white/30">
                <Shield size={40} />
             </div>
             <div>
                <h2 className="text-2xl font-black text-white uppercase">{formData.name || 'Admin'}</h2>
                <p className="text-white/70 font-bold text-sm tracking-widest">{formData.username ? `@${formData.username}` : 'System Administrator'}</p>
             </div>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="p-8 space-y-6">
          {message && (
            <div className="bg-emerald-500/10 border border-emerald-500/20 text-emerald-500 p-4 rounded-xl flex items-center">
              <CheckCircle size={18} className="mr-2" /> {message}
            </div>
          )}
          {error && (
            <div className="bg-rose-500/10 border border-rose-500/20 text-rose-500 p-4 rounded-xl">
              {error}
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest mb-2">Display Name</label>
              <div className="relative">
                <User className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500" size={18} />
                <input
                  type="text"
                  name="name"
                  value={formData.name}
                  onChange={handleChange}
                  className="w-full bg-[#111827] border border-white/10 rounded-xl pl-12 pr-4 py-3 text-white focus:outline-none focus:border-[#0ea5e9] transition-all"
                />
              </div>
            </div>
            <div>
              <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest mb-2">Username</label>
              <div className="relative">
                <span className="absolute left-4 top-1/2 -translate-y-1/2 text-[#0ea5e9] font-black">@</span>
                <input
                  type="text"
                  name="username"
                  value={formData.username}
                  onChange={handleChange}
                  className="w-full bg-[#111827] border border-white/10 rounded-xl pl-12 pr-4 py-3 text-white focus:outline-none focus:border-[#0ea5e9] transition-all"
                />
              </div>
            </div>
          </div>

          <div>
            <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest mb-2">Admin Email</label>
            <div className="relative">
              <Mail className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500" size={18} />
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                className="w-full bg-[#111827] border border-white/10 rounded-xl pl-12 pr-4 py-3 text-white focus:outline-none focus:border-[#0ea5e9] transition-all"
              />
            </div>
          </div>

          <div className="pt-4 border-t border-white/5">
            <h3 className="text-xs font-black text-white uppercase tracking-widest mb-4">Security Reset</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest mb-2">New Password</label>
                <div className="relative">
                  <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500" size={18} />
                  <input
                    type="password"
                    name="password"
                    value={formData.password}
                    onChange={handleChange}
                    placeholder="Leave blank to keep current"
                    className="w-full bg-[#111827] border border-white/10 rounded-xl pl-12 pr-4 py-3 text-white focus:outline-none focus:border-[#0ea5e9] transition-all text-sm"
                  />
                </div>
              </div>
              <div>
                <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest mb-2">Confirm New Password</label>
                <div className="relative">
                  <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500" size={18} />
                  <input
                    type="password"
                    name="confirmPassword"
                    value={formData.confirmPassword}
                    onChange={handleChange}
                    className="w-full bg-[#111827] border border-white/10 rounded-xl pl-12 pr-4 py-3 text-white focus:outline-none focus:border-[#0ea5e9] transition-all text-sm"
                  />
                </div>
              </div>
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-[#0ea5e9] hover:bg-[#0284c7] text-white font-black py-4 rounded-2xl transition-all shadow-lg shadow-[#0ea5e9]/20 flex items-center justify-center space-x-2 disabled:opacity-50"
          >
            {loading ? <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div> : <><Save size={20} /> <span>SAVE CHANGES</span></>}
          </button>
        </form>
      </div>
    </div>
  );
};

export default AdminProfile;
