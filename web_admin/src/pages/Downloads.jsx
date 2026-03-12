import React from 'react';
import { Download } from 'lucide-react';

const Downloads = () => (
  <div className="space-y-6">
    <h1 className="text-2xl font-bold text-[#1d2327]">Downloads Log</h1>
    <div className="admin-card">
      <div className="text-center py-20 text-gray-400">
        <Download size={48} className="mx-auto mb-4 opacity-20" />
        <p>Monitor real-time user download activity and statistics.</p>
      </div>
    </div>
  </div>
);

export default Downloads;
