import React from 'react';
import { Baby, Plus } from 'lucide-react';

const KidsContent = () => (
  <div className="space-y-6">
    <div className="flex items-center justify-between">
      <h1 className="text-2xl font-bold text-[#1d2327]">Kids Content Management</h1>
      <button className="btn-primary"><Plus size={18} /> Add Kids Content</button>
    </div>
    <div className="admin-card">
      <div className="text-center py-20 text-gray-400">
        <Baby size={48} className="mx-auto mb-4 opacity-20" />
        <p>Manage kids movies and TV shows with parental controls.</p>
      </div>
    </div>
  </div>
);

export default KidsContent;
