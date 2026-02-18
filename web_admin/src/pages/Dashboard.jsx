import React, { useState, useEffect } from 'react';
import api from '../utils/api';

const Dashboard = () => {
  const [stats, setStats] = useState({
    movies: 0,
    users: 0,
    genres: 0
  });

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const movieRes = await api.get('/admin/movies');
        // Assuming we might have a users endpoint later, or just mock for now
        setStats({
          movies: movieRes.data.length,
          users: 'Active', // Placeholder
          genres: 12 // Placeholder
        });
      } catch (err) {
        console.error(err);
      }
    };
    fetchStats();
  }, []);

  const cards = [
    { label: 'Total Movies', value: stats.movies, icon: '🎬', color: 'bg-blue-500', trend: '+12% this month' },
    { label: 'Active Users', value: '1,284', icon: '👥', color: 'bg-green-500', trend: '+5.4% this week' },
    { label: 'Total Revenue', value: '$12,450', icon: '💰', color: 'bg-yellow-500', trend: '+8.2% this month' },
    { label: 'Total Series', value: '42', icon: '📺', color: 'bg-purple-500', trend: '+2 new series' },
  ];

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-4xl font-black text-white tracking-tight">Dashboard</h1>
          <p className="text-gray-400 text-lg mt-1">Overview of your streaming empire.</p>
        </div>
        <div className="flex items-center space-x-3 bg-white/5 p-2 rounded-2xl border border-white/10">
          <div className="flex -space-x-2">
            {[1, 2, 3].map(i => (
              <div key={i} className="w-8 h-8 rounded-full border-2 border-[#141414] bg-purple-600 flex items-center justify-center text-[10px] font-bold">
                U{i}
              </div>
            ))}
          </div>
          <span className="text-xs text-gray-400 font-medium px-2">3 Admins Online</span>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {cards.map((card) => (
          <div key={card.label} className="bg-[#1C1C1C] p-6 rounded-3xl border border-white/5 hover:border-purple-500/30 transition-all group relative overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-purple-600/5 rounded-full -mr-16 -mt-16 blur-3xl group-hover:bg-purple-600/10 transition-colors"></div>
            <div className="flex items-center justify-between mb-6">
              <span className={`p-4 rounded-2xl ${card.color} bg-opacity-20 text-2xl shadow-inner`}>
                {card.icon}
              </span>
              <span className="text-[10px] font-black uppercase tracking-widest text-green-500 bg-green-500/10 px-2 py-1 rounded-full">
                {card.trend}
              </span>
            </div>
            <div>
              <p className="text-gray-500 text-sm font-bold uppercase tracking-widest">{card.label}</p>
              <h2 className="text-4xl font-black mt-2 text-white">{card.value}</h2>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 space-y-8">
          <div className="bg-[#1C1C1C] rounded-3xl border border-white/5 overflow-hidden shadow-2xl">
            <div className="p-8 border-b border-white/5 flex items-center justify-between">
              <h2 className="text-xl font-black uppercase tracking-tighter">Content Performance</h2>
              <select className="bg-white/5 border border-white/10 rounded-xl px-4 py-2 text-xs font-bold outline-none focus:border-purple-500 transition-colors">
                <option>Last 7 Days</option>
                <option>Last 30 Days</option>
              </select>
            </div>
            <div className="p-8">
              <div className="h-64 flex items-end justify-between gap-4">
                {[40, 70, 45, 90, 65, 80, 55].map((h, i) => (
                  <div key={i} className="flex-1 group flex flex-col items-center">
                    <div
                      className="w-full bg-purple-600/20 rounded-t-xl group-hover:bg-purple-600/40 transition-all relative overflow-hidden"
                      style={{ height: `${h}%` }}
                    >
                      <div className="absolute inset-0 bg-gradient-to-t from-purple-600/20 to-transparent"></div>
                    </div>
                    <span className="text-[10px] text-gray-500 mt-4 font-black uppercase tracking-tighter">Day {i+1}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        <div className="space-y-8">
          <div className="bg-[#1C1C1C] rounded-3xl border border-white/5 overflow-hidden shadow-2xl">
            <div className="p-8 border-b border-white/5">
              <h2 className="text-xl font-black uppercase tracking-tighter">System Pulse</h2>
            </div>
            <div className="p-8 space-y-6">
              <div className="flex items-center justify-between p-5 bg-white/5 rounded-2xl border border-white/5 group hover:border-purple-500/30 transition-all">
                <div className="flex items-center">
                  <div className="w-3 h-3 bg-green-500 rounded-full mr-4 shadow-[0_0_15px_rgba(34,197,94,0.5)] animate-pulse"></div>
                  <div className="flex flex-col">
                    <span className="text-sm font-bold text-white">Main API</span>
                    <span className="text-[10px] text-gray-500 font-medium">riyobox-prod-01</span>
                  </div>
                </div>
                <span className="text-green-500 text-[10px] font-black uppercase bg-green-500/10 px-3 py-1 rounded-full tracking-widest">Active</span>
              </div>
              <div className="flex items-center justify-between p-5 bg-white/5 rounded-2xl border border-white/5 group hover:border-purple-500/30 transition-all">
                <div className="flex items-center">
                  <div className="w-3 h-3 bg-green-500 rounded-full mr-4 shadow-[0_0_15px_rgba(34,197,94,0.5)]"></div>
                  <div className="flex flex-col">
                    <span className="text-sm font-bold text-white">Database</span>
                    <span className="text-[10px] text-gray-500 font-medium">MongoDB Cluster</span>
                  </div>
                </div>
                <span className="text-green-500 text-[10px] font-black uppercase bg-green-500/10 px-3 py-1 rounded-full tracking-widest">Stable</span>
              </div>
              <div className="flex items-center justify-between p-5 bg-white/5 rounded-2xl border border-white/5 group hover:border-purple-500/30 transition-all">
                <div className="flex items-center">
                  <div className="w-3 h-3 bg-blue-500 rounded-full mr-4 shadow-[0_0_15px_rgba(59,130,246,0.5)]"></div>
                  <div className="flex flex-col">
                    <span className="text-sm font-bold text-white">R2 Storage</span>
                    <span className="text-[10px] text-gray-500 font-medium">Cloudflare R2</span>
                  </div>
                </div>
                <span className="text-blue-500 text-[10px] font-black uppercase bg-blue-500/10 px-3 py-1 rounded-full tracking-widest">Normal</span>
              </div>
            </div>
          </div>

          <div className="bg-gradient-to-br from-purple-600 to-indigo-700 rounded-3xl p-8 text-white relative overflow-hidden shadow-2xl">
            <div className="absolute top-0 right-0 p-4 opacity-20">
              <svg className="w-24 h-24" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/>
              </svg>
            </div>
            <h3 className="text-xl font-black mb-2 uppercase tracking-tighter">Administrator Tips</h3>
            <p className="text-purple-100 text-sm leading-relaxed mb-6 font-medium">Keep your content fresh! Trending movies get 4x more engagement.</p>
            <button className="bg-white text-purple-700 px-6 py-2 rounded-xl text-xs font-black uppercase tracking-widest hover:bg-purple-50 shadow-xl transition-all active:scale-95">
              Read Guide
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
