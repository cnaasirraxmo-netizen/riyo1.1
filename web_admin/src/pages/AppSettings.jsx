
import React, { useState, useEffect } from 'react';
import { Settings, Globe, Shield, Mail, Database, Zap, RefreshCw, Trash2, Cpu, HardDrive, Layout, Monitor } from 'lucide-react';
import api from '../utils/api';

const AppSettings = () => {
  const [activeTab, setActiveTab] = useState('general');
  const [settings, setSettings] = useState({});
  const [loading, setLoading] = useState(true);

  const fetchSettings = async () => {
    try {
      const res = await api.get('/settings');
      setSettings(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSettings();
  }, []);

  const handleUpdate = async (key, value) => {
    try {
      await api.post('/settings', { key, value });
      fetchSettings();
    } catch (err) {
      alert('Update failed');
    }
  };

  const tabs = [
    { id: 'general', label: 'General', icon: <Settings size={18} /> },
    { id: 'streaming', label: 'Streaming', icon: <Zap size={18} /> },
    { id: 'storage', label: 'Storage & CDN', icon: <HardDrive size={18} /> },
    { id: 'branding', label: 'App Branding', icon: <Layout size={18} /> },
    { id: 'email', label: 'Email & Push', icon: <Mail size={18} /> },
    { id: 'tools', label: 'System Tools', icon: <Cpu size={18} /> },
  ];

  return (
    <div className="p-8 pb-24">
      <div className="mb-8">
        <h1 className="text-3xl font-black text-white uppercase tracking-tight">System Configuration</h1>
        <p className="text-gray-400 mt-1 font-medium">Manage global application settings, integrations, and infrastructure.</p>
      </div>

      <div className="flex gap-8">
        {/* Sidebar Tabs */}
        <div className="w-64 space-y-2">
          {tabs.map(tab => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`w-full flex items-center px-4 py-3 rounded-2xl transition-all duration-200 font-bold uppercase tracking-widest text-xs ${activeTab === tab.id ? 'bg-[#0ea5e9] text-white shadow-lg shadow-[#0ea5e9]/20' : 'text-gray-500 hover:bg-white/5 hover:text-gray-300'}`}
            >
              <span className="mr-3">{tab.icon}</span>
              {tab.label}
            </button>
          ))}
        </div>

        {/* Content Area */}
        <div className="flex-1 bg-[#1f2937] rounded-3xl border border-white/5 overflow-hidden shadow-2xl p-8">
           {activeTab === 'general' && (
             <div className="space-y-8">
                <h3 className="text-xl font-black text-white uppercase tracking-widest border-b border-white/5 pb-4">General Info</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                   <div className="space-y-4">
                      <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest">Platform Name</label>
                      <input
                        type="text"
                        defaultValue={settings.app_name || 'RIYOBOX'}
                        onBlur={(e) => handleUpdate('app_name', e.target.value)}
                        className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white outline-none focus:border-[#0ea5e9]"
                      />
                   </div>
                   <div className="space-y-4">
                      <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest">Support Email Address</label>
                      <input
                        type="email"
                        defaultValue={settings.support_email || 'support@riyobox.app'}
                        onBlur={(e) => handleUpdate('support_email', e.target.value)}
                        className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white outline-none focus:border-[#0ea5e9]"
                      />
                   </div>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-8 pt-4">
                   <div className="space-y-4">
                      <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest">Default Language</label>
                      <select
                        defaultValue={settings.default_lang || 'English'}
                        onChange={(e) => handleUpdate('default_lang', e.target.value)}
                        className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white outline-none focus:border-[#0ea5e9]"
                      >
                         <option>English</option>
                         <option>Arabic</option>
                         <option>Somali</option>
                      </select>
                   </div>
                   <div className="space-y-4">
                      <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest">System Timezone</label>
                      <select
                        defaultValue={settings.timezone || 'UTC'}
                        onChange={(e) => handleUpdate('timezone', e.target.value)}
                        className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white outline-none focus:border-[#0ea5e9]"
                      >
                         <option>UTC</option>
                         <option>GMT+3 (East Africa)</option>
                         <option>EST</option>
                      </select>
                   </div>
                </div>
             </div>
           )}

           {activeTab === 'streaming' && (
             <div className="space-y-8">
                <h3 className="text-xl font-black text-white uppercase tracking-widest border-b border-white/5 pb-4">Streaming Engine</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                   <div className="space-y-4">
                      <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest">Default Playback Quality</label>
                      <select className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white outline-none">
                         <option>Auto (Recommended)</option>
                         <option>4K Ultra HD</option>
                         <option>1080p Full HD</option>
                         <option>720p HD</option>
                      </select>
                   </div>
                   <div className="space-y-4">
                      <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest">Concurrent Streams Limit (Per Account)</label>
                      <input type="number" defaultValue={3} className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white outline-none" />
                   </div>
                </div>
                <div className="flex items-center justify-between p-6 bg-[#111827] rounded-2xl border border-white/5 mt-4">
                   <div className="flex items-center space-x-4">
                      <div className="p-3 bg-purple-500/10 text-purple-500 rounded-xl"><Shield size={24} /></div>
                      <div>
                        <h4 className="text-sm font-black text-white uppercase tracking-tight">Enforce DRM Protection</h4>
                        <p className="text-[10px] text-gray-500 font-medium">Restrict playback to secure devices only.</p>
                      </div>
                   </div>
                   <label className="relative inline-flex items-center cursor-pointer">
                      <input type="checkbox" defaultChecked className="sr-only peer" />
                      <div className="w-11 h-6 bg-white/10 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-purple-600"></div>
                   </label>
                </div>
             </div>
           )}

           {activeTab === 'tools' && (
             <div className="space-y-8">
                <h3 className="text-xl font-black text-white uppercase tracking-widest border-b border-white/5 pb-4">Infrastructure Tools</h3>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                   <button className="p-6 bg-[#111827] rounded-3xl border border-white/5 hover:border-[#0ea5e9]/30 transition-all text-left group">
                      <div className="w-12 h-12 bg-[#0ea5e9]/10 text-[#0ea5e9] rounded-2xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                        <RefreshCw size={24} />
                      </div>
                      <h4 className="text-sm font-black text-white uppercase tracking-tighter">Clear API Cache</h4>
                      <p className="text-[10px] text-gray-500 mt-1">Flush all cached response data.</p>
                   </button>
                   <button className="p-6 bg-[#111827] rounded-3xl border border-white/5 hover:border-rose-500/30 transition-all text-left group">
                      <div className="w-12 h-12 bg-rose-500/10 text-rose-500 rounded-2xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                        <Trash2 size={24} />
                      </div>
                      <h4 className="text-sm font-black text-white uppercase tracking-tighter">Prune Temp Files</h4>
                      <p className="text-[10px] text-gray-500 mt-1">Remove unused assets from storage.</p>
                   </button>
                   <button className="p-6 bg-[#111827] rounded-3xl border border-white/5 hover:border-purple-500/30 transition-all text-left group">
                      <div className="w-12 h-12 bg-purple-500/10 text-purple-500 rounded-2xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                        <Database size={24} />
                      </div>
                      <h4 className="text-sm font-black text-white uppercase tracking-tighter">DB Health Check</h4>
                      <p className="text-[10px] text-gray-500 mt-1">Verify indexes and collection state.</p>
                   </button>
                </div>

                <div className="p-8 bg-[#111827] rounded-3xl border border-white/5 mt-8">
                   <h4 className="text-xs font-black text-gray-500 uppercase tracking-widest mb-6">Real-Time Performance</h4>
                   <div className="space-y-6">
                      <div className="space-y-2">
                        <div className="flex justify-between text-xs font-bold uppercase tracking-widest">
                           <span className="text-gray-400">CPU Usage</span>
                           <span className="text-[#0ea5e9]">12%</span>
                        </div>
                        <div className="w-full bg-white/5 h-2 rounded-full overflow-hidden">
                           <div className="bg-[#0ea5e9] h-full w-[12%]"></div>
                        </div>
                      </div>
                      <div className="space-y-2">
                        <div className="flex justify-between text-xs font-bold uppercase tracking-widest">
                           <span className="text-gray-400">Memory Allocation</span>
                           <span className="text-purple-500">4.2 GB / 16 GB</span>
                        </div>
                        <div className="w-full bg-white/5 h-2 rounded-full overflow-hidden">
                           <div className="bg-purple-500 h-full w-[26%]"></div>
                        </div>
                      </div>
                   </div>
                </div>
             </div>
           )}
        </div>
      </div>
    </div>
  );
};

export default AppSettings;
