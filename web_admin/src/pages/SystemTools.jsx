import React from 'react';
import { Wrench, Trash2, RefreshCw, Database, Activity } from 'lucide-react';

const SystemTools = () => {
  const tools = [
    { title: 'Clear Cache', desc: 'Flush all system and image caches', icon: <Trash2 size={24} />, action: 'Flush' },
    { title: 'Rebuild Thumbnails', desc: 'Regenerate all movie/TV show thumbnails', icon: <RefreshCw size={24} />, action: 'Rebuild' },
    { title: 'Database Backup', desc: 'Create a full backup of the system database', icon: <Database size={24} />, action: 'Backup' },
    { title: 'System Health', desc: 'Check API and storage server connectivity', icon: <Activity size={24} />, action: 'Check' },
  ];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-[#1d2327]">System Tools</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {tools.map(tool => (
          <div key={tool.title} className="admin-card flex flex-col items-center text-center">
            <div className="p-4 bg-gray-100 rounded-full text-gray-600 mb-4">
              {tool.icon}
            </div>
            <h3 className="font-bold mb-2">{tool.title}</h3>
            <p className="text-xs text-gray-500 mb-6 flex-1">{tool.desc}</p>
            <button className="btn-secondary w-full justify-center text-sm">{tool.action}</button>
          </div>
        ))}
      </div>
    </div>
  );
};

export default SystemTools;
