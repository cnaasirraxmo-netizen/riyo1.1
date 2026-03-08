import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import { Settings, Save, RefreshCw, Smartphone, Cast, Bell, Play, MessageSquare } from 'lucide-react';

const SystemSettings = () => {
  const [config, setConfig] = useState({
    downloadsEnabled: true,
    castingEnabled: true,
    notificationsOn: true,
    trailerAutoplay: true,
    commentsEnabled: true
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const fetchConfig = async () => {
      try {
        const res = await api.get('/system-config');
        setConfig(res.data);
      } catch (err) {
        console.error('Failed to fetch config', err);
      } finally {
        setLoading(false);
      }
    };
    fetchConfig();
  }, []);

  const handleToggle = (key) => {
    setConfig(prev => ({ ...prev, [key]: !prev[key] }));
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await api.put('/admin/system-config', config);
      alert('System configuration updated successfully!');
    } catch (err) {
      alert('Failed to update configuration');
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <div className="p-10 text-center text-gray-500 flex items-center justify-center gap-2"><RefreshCw className="animate-spin" /> Loading system config...</div>;

  return (
    <div className="space-y-10 pb-20">
      <div>
        <h1 className="text-3xl font-bold flex items-center gap-3">
          <Settings className="text-purple-500" /> System Settings
        </h1>
        <p className="text-gray-400">Control global application features and systems.</p>
      </div>

      <div className="max-w-2xl bg-[#1C1C1C] rounded-2xl border border-white/5 overflow-hidden">
        <div className="p-6 border-b border-white/5 bg-[#262626]">
          <h2 className="font-bold">Feature Toggles</h2>
          <p className="text-xs text-gray-500">Enabled features will be visible to all users across all platforms.</p>
        </div>

        <div className="p-6 space-y-6">
          <ToggleItem
            icon={<Smartphone className="text-blue-400" />}
            title="Downloads System"
            description="Allow users to download content for offline viewing."
            enabled={config.downloadsEnabled}
            onToggle={() => handleToggle('downloadsEnabled')}
          />
          <ToggleItem
            icon={<Cast className="text-orange-400" />}
            title="Google Cast / DLNA"
            description="Enable TV casting features in the mobile app."
            enabled={config.castingEnabled}
            onToggle={() => handleToggle('castingEnabled')}
          />
          <ToggleItem
            icon={<Bell className="text-yellow-400" />}
            title="Push Notifications"
            description="Send automated notifications for new releases and updates."
            enabled={config.notificationsOn}
            onToggle={() => handleToggle('notificationsOn')}
          />
          <ToggleItem
            icon={<Play className="text-green-400" />}
            title="Trailer Autoplay"
            description="Automatically play trailers on the movie details screen."
            enabled={config.trailerAutoplay}
            onToggle={() => handleToggle('trailerAutoplay')}
          />
          <ToggleItem
            icon={<MessageSquare className="text-purple-400" />}
            title="Comments System"
            description="Allow users to post reviews and comments on movies."
            enabled={config.commentsEnabled}
            onToggle={() => handleToggle('commentsEnabled')}
          />
        </div>

        <div className="p-6 bg-[#262626] flex justify-end">
           <button
            onClick={handleSave}
            disabled={saving}
            className="bg-purple-600 hover:bg-purple-700 disabled:opacity-50 text-white px-8 py-3 rounded-xl font-bold flex items-center gap-2 transition-all shadow-lg shadow-purple-600/20"
           >
             {saving ? <RefreshCw size={18} className="animate-spin" /> : <Save size={18} />}
             SAVE CONFIGURATION
           </button>
        </div>
      </div>
    </div>
  );
};

const ToggleItem = ({ icon, title, description, enabled, onToggle }) => (
  <div className="flex items-center justify-between group">
    <div className="flex items-center gap-4">
      <div className="w-10 h-10 rounded-xl bg-white/5 flex items-center justify-center group-hover:scale-110 transition-transform">
        {icon}
      </div>
      <div>
        <h3 className="font-bold text-white">{title}</h3>
        <p className="text-xs text-gray-500">{description}</p>
      </div>
    </div>
    <button
      onClick={onToggle}
      className={`w-14 h-7 rounded-full transition-all relative ${enabled ? 'bg-purple-600' : 'bg-gray-700'}`}
    >
      <div className={`absolute top-1 w-5 h-5 bg-white rounded-full transition-all ${enabled ? 'left-8' : 'left-1'}`} />
    </button>
  </div>
);

export default SystemSettings;
