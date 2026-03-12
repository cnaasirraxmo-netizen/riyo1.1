import React from 'react';
import { Plus, List, GripVertical } from 'lucide-react';

const Categories = () => (
  <div className="space-y-6">
    <div className="flex items-center justify-between">
      <h1 className="text-2xl font-bold text-[#1d2327]">Category Management</h1>
      <button className="btn-primary"><Plus size={18} /> Create Category</button>
    </div>
    <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
      <div className="admin-card">
        <h2 className="text-lg font-bold mb-4">Homepage Categories Order</h2>
        <div className="space-y-2">
          {['Trending', 'Popular', 'New Releases', 'Top Rated'].map(cat => (
            <div key={cat} className="flex items-center gap-4 p-3 border border-[#dcdcde] rounded bg-gray-50 cursor-move">
              <GripVertical size={16} className="text-gray-400" />
              <span className="font-semibold">{cat}</span>
            </div>
          ))}
        </div>
      </div>
      <div className="admin-card">
        <h2 className="text-lg font-bold mb-4">Add New Category</h2>
        <form className="space-y-4">
          <div>
            <label className="block text-sm font-bold mb-1">Name</label>
            <input type="text" className="input-field w-full" />
            <p className="text-xs text-gray-400 mt-1">The name is how it appears on your site.</p>
          </div>
          <button type="button" className="btn-primary">Add New Category</button>
        </form>
      </div>
    </div>
  </div>
);

export default Categories;
