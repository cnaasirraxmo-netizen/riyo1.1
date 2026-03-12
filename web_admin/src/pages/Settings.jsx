import React from 'react';
import { Settings as SettingsIcon, Save, EyeOff } from 'lucide-react';

const Settings = () => (
  <div className="space-y-6">
    <h1 className="text-2xl font-bold text-[#1d2327]">General Settings</h1>
    <div className="admin-card max-w-4xl">
      <div className="space-y-8">
        <section>
          <h2 className="text-md font-bold mb-4 border-b pb-2">App Visibility Control</h2>
          <div className="space-y-3">
            {[
              { label: 'Hide Download Button', id: 'hide_download' },
              { label: 'Hide TV Cast Icon', id: 'hide_cast' },
              { label: 'Hide Sports Section', id: 'hide_sports' },
              { label: 'Hide Kids Mode', id: 'hide_kids' }
            ].map(item => (
              <label key={item.id} className="flex items-center gap-3 cursor-pointer">
                <input type="checkbox" className="w-4 h-4" />
                <span className="text-sm">{item.label}</span>
              </label>
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

        <button className="btn-primary"><Save size={18} /> Save All Changes</button>
      </div>
    </div>
  </div>
);

export default Settings;
