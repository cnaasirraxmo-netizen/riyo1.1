import React from 'react';
import { Plus, PlaySquare } from 'lucide-react';

const Trailers = () => (
  <div className="space-y-6">
    <div className="flex items-center justify-between">
      <h1 className="text-2xl font-bold text-[#1d2327]">Trailer Management</h1>
      <button className="btn-primary"><Plus size={18} /> Add New Trailer</button>
    </div>
    <div className="admin-card">
      <div className="text-center py-20 text-gray-400">
        <PlaySquare size={48} className="mx-auto mb-4 opacity-20" />
        <p>No trailers found. Start by uploading a trailer for a movie.</p>
      </div>
    </div>
  </div>
);

export default Trailers;
