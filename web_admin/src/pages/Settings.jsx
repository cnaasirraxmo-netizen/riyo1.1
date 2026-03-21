import React, { useState, useEffect } from 'react';
import { Save, Loader2, User, Mail, Lock, ShieldCheck, QrCode } from 'lucide-react';
import { systemService } from '../services/api';
import api from '../utils/api';

const Settings = () => {
  const [config, setConfig] = useState({
    downloadsEnabled: true,
    castingEnabled: true,
    sportsEnabled: true,
    kidsEnabled: true,
    notificationsOn: true,
    trailerAutoplay: true,
    commentsEnabled: true
  });
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [message, setMessage] = useState(null);

  const [adminProfile, setAdminProfile] = useState({
    username: '',
    email: '',
    password: '',
    oldPassword: ''
  });
  const [profileSaving, setProfileSaving] = useState(false);
  const [profileMessage, setProfileMessage] = useState(null);

  const [twoFAStep, setTwoFAStep] = useState('initial'); // initial, setup, active
  const [twoFAData, setTwoFAData] = useState({ secret: '', url: '' });
  const [twoFACode, setTwoFACode] = useState('');
  const [twoFAMessage, setTwoFAMessage] = useState(null);

  useEffect(() => {
    fetchConfig();
  }, []);

  const fetchConfig = async () => {
    try {
      const data = await systemService.getConfig();
      setConfig(data);
    } catch (err) {
      console.error('Error fetching config:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleToggle = (key) => {
    setConfig(prev => ({ ...prev, [key]: !prev[key] }));
  };

  const handleSave = async () => {
    setIsSaving(true);
    setMessage(null);
    try {
      await systemService.updateConfig(config);
      setMessage({ type: 'success', text: 'Settings saved successfully!' });
    } catch (err) {
      console.error('Error saving config:', err);
      setMessage({ type: 'error', text: 'Failed to save settings.' });
    } finally {
      setIsSaving(false);
    }
  };

  const handleProfileSave = async (e) => {
    e.preventDefault();
    setProfileSaving(true);
    setProfileMessage(null);
    try {
      await api.put('/admin/profile', adminProfile);
      setProfileMessage({ type: 'success', text: 'Profile updated successfully!' });
      setAdminProfile(prev => ({ ...prev, password: '', oldPassword: '' }));
    } catch (err) {
      setProfileMessage({ type: 'error', text: err.response?.data?.message || 'Failed to update profile.' });
    } finally {
      setProfileSaving(false);
    }
  };

  const init2FA = async () => {
    try {
      const response = await api.get('/admin/2fa/setup');
      setTwoFAData(response.data);
      setTwoFAStep('setup');
    } catch (err) {
      setTwoFAMessage({ type: 'error', text: 'Failed to initialize 2FA.' });
    }
  };

  const verify2FA = async () => {
    try {
      await api.post('/admin/2fa/verify', { secret: twoFAData.secret, code: twoFACode });
      setTwoFAMessage({ type: 'success', text: '2FA enabled successfully!' });
      setTwoFAStep('active');
    } catch (err) {
      setTwoFAMessage({ type: 'error', text: 'Invalid verification code.' });
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-[#2271b1]" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-[#1d2327]">Settings</h1>

      <div className="admin-card max-w-4xl">
        <h2 className="text-lg font-bold mb-6 flex items-center gap-2 border-b pb-4 text-[#1d2327]">
          <User className="text-[#2271b1]" size={20} />
          Admin Profile Settings
        </h2>

        {profileMessage && (
          <div className={`p-4 mb-6 rounded-md ${profileMessage.type === 'success' ? 'bg-green-50 text-green-800' : 'bg-red-50 text-red-800'} border`}>
            {profileMessage.text}
          </div>
        )}

        <form onSubmit={handleProfileSave} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-xs font-bold mb-1 uppercase text-gray-500">Username</label>
              <div className="relative">
                <User className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
                <input
                  type="text"
                  className="input-field w-full pl-10"
                  placeholder="New Username"
                  value={adminProfile.username}
                  onChange={(e) => setAdminProfile({ ...adminProfile, username: e.target.value })}
                />
              </div>
            </div>
            <div>
              <label className="block text-xs font-bold mb-1 uppercase text-gray-500">Email Address</label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
                <input
                  type="email"
                  className="input-field w-full pl-10"
                  placeholder="New Email"
                  value={adminProfile.email}
                  onChange={(e) => setAdminProfile({ ...adminProfile, email: e.target.value })}
                />
              </div>
            </div>
            <div>
              <label className="block text-xs font-bold mb-1 uppercase text-gray-500">New Password</label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
                <input
                  type="password"
                  className="input-field w-full pl-10"
                  placeholder="••••••••"
                  value={adminProfile.password}
                  onChange={(e) => setAdminProfile({ ...adminProfile, password: e.target.value })}
                />
              </div>
              <p className="text-[10px] text-gray-500 mt-1">Leave blank to keep current password</p>
            </div>
            <div>
              <label className="block text-xs font-bold mb-1 uppercase text-gray-500">Verify Old Password *</label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
                <input
                  type="password"
                  required
                  className="input-field w-full pl-10 border-orange-200 focus:border-orange-500"
                  placeholder="Confirm Current Password"
                  value={adminProfile.oldPassword}
                  onChange={(e) => setAdminProfile({ ...adminProfile, oldPassword: e.target.value })}
                />
              </div>
              <p className="text-[10px] text-orange-600 mt-1 font-medium">Required for any profile changes</p>
            </div>
          </div>

          <div className="pt-2">
            <button
              type="submit"
              disabled={profileSaving}
              className="btn-primary"
            >
              {profileSaving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save size={18} />}
              {profileSaving ? 'Updating Profile...' : 'Update Admin Profile'}
            </button>
          </div>
        </form>

        <div className="mt-12 pt-8 border-t border-gray-100">
          <h3 className="text-md font-bold mb-4 flex items-center gap-2 text-[#1d2327]">
            <ShieldCheck className="text-green-600" size={18} />
            Two-Factor Authentication (2FA)
          </h3>

          {twoFAMessage && (
            <div className={`p-3 mb-4 text-sm rounded ${twoFAMessage.type === 'success' ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'}`}>
              {twoFAMessage.text}
            </div>
          )}

          {twoFAStep === 'initial' && (
            <div>
              <p className="text-sm text-gray-500 mb-4">Add an extra layer of security to your account by enabling Google Authenticator.</p>
              <button onClick={init2FA} className="flex items-center gap-2 px-4 py-2 bg-gray-900 text-white rounded hover:bg-black transition-colors text-sm font-medium">
                <QrCode size={16} />
                Setup 2FA
              </button>
            </div>
          )}

          {twoFAStep === 'setup' && (
            <div className="bg-gray-50 p-6 rounded-lg border border-gray-200">
              <p className="text-sm font-bold mb-4 text-[#1d2327]">1. Scan this QR Code with your Authenticator app:</p>
              <div className="bg-white p-4 w-fit rounded-lg shadow-sm mb-6 border border-gray-100 mx-auto">
                <img
                  src={`https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(twoFAData.url)}`}
                  alt="2FA QR Code"
                  className="w-[180px] h-[180px]"
                />
              </div>
              <p className="text-sm font-bold mb-2 text-[#1d2327]">2. Enter the 6-digit verification code:</p>
              <div className="flex gap-4">
                <input
                  type="text"
                  className="input-field max-w-[200px] text-center text-xl tracking-widest"
                  placeholder="000000"
                  maxLength="6"
                  value={twoFACode}
                  onChange={(e) => setTwoFACode(e.target.value)}
                />
                <button onClick={verify2FA} className="btn-primary">Verify & Enable</button>
              </div>
            </div>
          )}

          {twoFAStep === 'active' && (
            <div className="flex items-center gap-3 text-green-600 bg-green-50 p-4 rounded-lg border border-green-100">
              <ShieldCheck size={20} />
              <span className="font-bold text-sm">Two-Factor Authentication is active</span>
            </div>
          )}
        </div>
      </div>

      <h2 className="text-xl font-bold text-[#1d2327] mt-10">System Visibility Controls</h2>

      {message && (
        <div className={`p-4 rounded-md ${message.type === 'success' ? 'bg-green-50 text-green-800' : 'bg-red-50 text-red-800'} border`}>
          {message.text}
        </div>
      )}

      <div className="admin-card max-w-4xl">
        <div className="space-y-8">
          <section>
            <h2 className="text-md font-bold mb-4 border-b pb-2">App Visibility Control</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {[
                { label: 'Enable Downloads', key: 'downloadsEnabled' },
                { label: 'Enable TV Casting', key: 'castingEnabled' },
                { label: 'Enable Sports Section', key: 'sportsEnabled' },
                { label: 'Enable Kids Mode', key: 'kidsEnabled' },
                { label: 'Push Notifications', key: 'notificationsOn' },
                { label: 'Trailer Autoplay', key: 'trailerAutoplay' },
                { label: 'Comments & Reviews', key: 'commentsEnabled' }
              ].map(item => (
                <div key={item.key} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg border border-gray-100">
                  <div>
                    <p className="font-bold text-sm text-[#1d2327]">{item.label}</p>
                    <p className="text-xs text-gray-500">Toggle {item.label.toLowerCase()} in the app</p>
                  </div>
                  <button
                    onClick={() => handleToggle(item.key)}
                    className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none ${config[item.key] ? 'bg-[#2271b1]' : 'bg-gray-200'}`}
                  >
                    <span
                      className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${config[item.key] ? 'translate-x-6' : 'translate-x-1'}`}
                    />
                  </button>
                </div>
              ))}
            </div>
          </section>

          <section>
            <h2 className="text-md font-bold mb-4 border-b pb-2">Global Metadata</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold mb-1 uppercase text-gray-500">Site Title</label>
                <input type="text" defaultValue="RIYO Platform" className="input-field w-full text-sm" />
              </div>
              <div>
                <label className="block text-xs font-bold mb-1 uppercase text-gray-500">Tagline</label>
                <input type="text" defaultValue="Your ultimate streaming experience" className="input-field w-full text-sm" />
              </div>
            </div>
          </section>

          <div className="pt-4">
            <button
              onClick={handleSave}
              disabled={isSaving}
              className="btn-primary"
            >
              {isSaving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save size={18} />}
              {isSaving ? 'Saving...' : 'Save All Changes'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Settings;
