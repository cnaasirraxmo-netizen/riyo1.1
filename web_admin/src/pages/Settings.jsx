import React, { useState, useEffect } from 'react';
import { Save, Loader2 } from 'lucide-react';
import { systemService } from '../services/api';

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

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-[#2271b1]" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-[#1d2327]">General Settings</h1>

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
