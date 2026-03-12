import React from 'react';
import { BarChart3 } from 'lucide-react';

const Analytics = () => (
  <div className="space-y-6">
    <h1 className="text-2xl font-bold text-[#1d2327]">Analytics Dashboard</h1>
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
      <div className="admin-card">
        <h3 className="font-bold mb-4">Watch Time Distribution</h3>
        <div className="h-64 bg-gray-50 border border-dashed border-gray-300 rounded flex items-center justify-center text-gray-400 italic text-sm">
          Analytics Chart Visualization
        </div>
      </div>
      <div className="admin-card">
        <h3 className="font-bold mb-4">Streaming Bandwidth Usage</h3>
        <div className="h-64 bg-gray-50 border border-dashed border-gray-300 rounded flex items-center justify-center text-gray-400 italic text-sm">
          Bandwidth Usage Chart
        </div>
      </div>
    </div>
  </div>
);

export default Analytics;
