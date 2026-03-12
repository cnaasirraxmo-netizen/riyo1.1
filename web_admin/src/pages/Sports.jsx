import React from 'react';
import { Trophy, Save } from 'lucide-react';

const Sports = () => (
  <div className="space-y-6">
    <h1 className="text-2xl font-bold text-[#1d2327]">Sports API Management</h1>
    <div className="admin-card max-w-2xl">
      <h2 className="text-lg font-bold mb-6 flex items-center gap-2"><Trophy size={20} className="text-yellow-600" /> API Configuration</h2>
      <form className="space-y-4">
        <div>
          <label className="block text-sm font-bold mb-1">API Provider</label>
          <input type="text" defaultValue="API-Football" className="input-field w-full" />
        </div>
        <div>
          <label className="block text-sm font-bold mb-1">API Key</label>
          <input type="password" value="************************" className="input-field w-full" />
        </div>
        <div>
          <label className="block text-sm font-bold mb-1">Refresh Interval (minutes)</label>
          <input type="number" defaultValue="60" className="input-field w-40" />
        </div>
        <button type="button" className="btn-primary"><Save size={18} /> Save Settings</button>
      </form>
    </div>
  </div>
);

export default Sports;
