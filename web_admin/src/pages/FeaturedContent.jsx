import React from 'react';
import { Star, Plus } from 'lucide-react';

const FeaturedContent = () => (
  <div className="space-y-6">
    <div className="flex items-center justify-between">
      <h1 className="text-2xl font-bold text-[#1d2327]">Featured Content</h1>
      <button className="btn-primary"><Plus size={18} /> Manage Hero Slider</button>
    </div>
    <div className="admin-card">
      <div className="text-center py-20 text-gray-400">
        <Star size={48} className="mx-auto mb-4 opacity-20" />
        <p>Manage content that appears in the homepage hero slider.</p>
      </div>
    </div>
  </div>
);

export default FeaturedContent;
