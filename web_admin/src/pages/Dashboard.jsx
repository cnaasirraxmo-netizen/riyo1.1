import React, { useState, useEffect } from 'react';
import {
  Users,
  Activity,
  CreditCard,
  Film,
  Tv,
  Download,
  HardDrive,
  DollarSign,
  RefreshCw,
  Server,
  Zap,
  ShieldCheck,
  Plus,
  Bell,
  BarChart2,
  Settings,
  ArrowUpRight,
  ArrowDownRight
} from 'lucide-react';
import api from '../utils/api';
import { useNavigate } from 'react-router-dom';

const Dashboard = () => {
  const navigate = useNavigate();
  const [stats, setStats] = useState({
    totalUsers: 12540,
    activeNow: 420,
    premiumUsers: 3820,
    totalMovies: 1250,
    totalSeries: 450,
    totalDownloads: 89000,
    storageUsage: '4.2 TB',
    revenue: '$42,500',
    renewalRate: '88%',
    uptime: '99.98%',
    apiLatency: '45ms',
    cdnHitRate: '94%'
  });

  const widgets = [
    { label: 'Total Users', value: stats.totalUsers, change: '+12%', icon: <Users />, color: 'text-blue-500', bg: 'bg-blue-500/10' },
    { label: 'Active Now', value: stats.activeNow, change: '+5%', icon: <Activity />, color: 'text-green-500', bg: 'bg-green-500/10' },
    { label: 'Premium Users', value: stats.premiumUsers, change: '+8%', icon: <CreditCard />, color: 'text-purple-500', bg: 'bg-purple-500/10' },
    { label: 'Total Movies', value: stats.totalMovies, change: '+24', icon: <Film />, color: 'text-amber-500', bg: 'bg-amber-500/10' },
    { label: 'Total TV Shows', value: stats.totalSeries, change: '+12', icon: <Tv />, color: 'text-rose-500', bg: 'bg-rose-500/10' },
    { label: 'Total Downloads', value: stats.totalDownloads, change: '+15k', icon: <Download />, color: 'text-indigo-500', bg: 'bg-indigo-500/10' },
    { label: 'Storage Usage', value: stats.storageUsage, icon: <HardDrive />, color: 'text-cyan-500', bg: 'bg-cyan-500/10' },
    { label: 'Monthly Revenue', value: stats.revenue, change: '+18%', icon: <DollarSign />, color: 'text-emerald-500', bg: 'bg-emerald-500/10' },
    { label: 'Renewal Rate', value: stats.renewalRate, change: '+2%', icon: <RefreshCw />, color: 'text-orange-500', bg: 'bg-orange-500/10' },
    { label: 'App Uptime', value: stats.uptime, icon: <Server />, color: 'text-lime-500', bg: 'bg-lime-500/10' },
    { label: 'API Response', value: stats.apiLatency, icon: <Zap />, color: 'text-yellow-500', bg: 'bg-yellow-500/10' },
    { label: 'CDN Hit Rate', value: stats.cdnHitRate, icon: <ShieldCheck />, color: 'text-sky-500', bg: 'bg-sky-500/10' },
  ];

  const quickActions = [
    { label: 'Add Movie', icon: <Plus size={18} />, onClick: () => navigate('/movies/add'), color: 'bg-[#0ea5e9]' },
    { label: 'Add TV Show', icon: <Plus size={18} />, onClick: () => navigate('/series/add'), color: 'bg-purple-600' },
    { label: 'Manage Users', icon: <Users size={18} />, onClick: () => navigate('/users'), color: 'bg-emerald-600' },
    { label: 'Send Alert', icon: <Bell size={18} />, onClick: () => navigate('/notifications'), color: 'bg-rose-600' },
    { label: 'View Analytics', icon: <BarChart2 size={18} />, onClick: () => navigate('/analytics'), color: 'bg-amber-600' },
    { label: 'System Health', icon: <Activity size={18} />, onClick: () => {}, color: 'bg-slate-600' },
  ];

  return (
    <div className="p-8 pb-12 bg-[#111827] min-h-full">
      <div className="flex justify-between items-end mb-8">
        <div>
          <h1 className="text-3xl font-black text-white tracking-tight">Dashboard Overview</h1>
          <p className="text-gray-400 mt-1">Real-time performance and system status.</p>
        </div>
        <div className="flex space-x-3">
            <button className="bg-[#1f2937] border border-white/5 text-sm px-4 py-2 rounded-lg text-white font-medium hover:bg-[#374151] transition-colors">
                Export Data
            </button>
            <button className="bg-[#0ea5e9] text-sm px-4 py-2 rounded-lg text-white font-bold hover:bg-[#0284c7] transition-colors flex items-center">
                <RefreshCw size={14} className="mr-2" /> Refresh
            </button>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 xl:grid-cols-6 gap-4 mb-8">
        {widgets.map((w, idx) => (
          <div key={idx} className="bg-[#1f2937] p-5 rounded-2xl border border-white/5 hover:border-white/10 transition-all group">
            <div className="flex items-center justify-between mb-3">
              <div className={`p-2 rounded-xl ${w.bg} ${w.color} group-hover:scale-110 transition-transform`}>
                {React.cloneElement(w.icon, { size: 20 })}
              </div>
              {w.change && (
                <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full flex items-center ${w.change.startsWith('+') ? 'bg-green-500/10 text-green-500' : 'bg-red-500/10 text-red-500'}`}>
                  {w.change.startsWith('+') ? <ArrowUpRight size={10} className="mr-0.5" /> : <ArrowDownRight size={10} className="mr-0.5" />}
                  {w.change}
                </span>
              )}
            </div>
            <p className="text-gray-400 text-xs font-bold uppercase tracking-wider">{w.label}</p>
            <h2 className="text-2xl font-black text-white mt-1">{w.value}</h2>
          </div>
        ))}
      </div>

      {/* Main Content Area */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-8">
        {/* Charts Section */}
        <div className="xl:col-span-2 space-y-8">
          <div className="bg-[#1f2937] p-6 rounded-2xl border border-white/5">
            <div className="flex justify-between items-center mb-6">
                <h3 className="font-bold text-lg text-white">User Growth & Revenue</h3>
                <div className="flex space-x-2">
                    {['1D', '1W', '1M', '1Y'].map(t => (
                        <button key={t} className={`text-[10px] font-black px-2 py-1 rounded ${t === '1M' ? 'bg-[#0ea5e9] text-white' : 'bg-white/5 text-gray-500 hover:bg-white/10'}`}>
                            {t}
                        </button>
                    ))}
                </div>
            </div>
            {/* Mock Chart Area */}
            <div className="h-64 flex items-end justify-between px-2 gap-2">
              {[45, 60, 40, 80, 50, 70, 90, 65, 85, 45, 75, 100, 80, 60].map((h, i) => (
                <div key={i} className="flex-1 bg-gradient-to-t from-[#0ea5e9]/20 to-[#0ea5e9] rounded-t-sm" style={{ height: `${h}%` }}></div>
              ))}
            </div>
            <div className="flex justify-between mt-4 text-[10px] text-gray-500 font-bold uppercase px-2">
                <span>01 Feb</span>
                <span>07 Feb</span>
                <span>14 Feb</span>
                <span>21 Feb</span>
                <span>28 Feb</span>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="bg-[#1f2937] p-6 rounded-2xl border border-white/5">
                <h3 className="font-bold text-lg text-white mb-6 text-center">Genre Distribution</h3>
                <div className="relative h-48 flex items-center justify-center">
                    {/* Mock Donut Chart */}
                    <div className="w-32 h-32 rounded-full border-[12px] border-purple-500 border-t-amber-500 border-r-rose-500 border-b-emerald-500 relative">
                        <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
                            <span className="text-xl font-black text-white">12</span>
                            <span className="text-[8px] text-gray-400 font-bold uppercase">Genres</span>
                        </div>
                    </div>
                    <div className="ml-8 space-y-2">
                        <div className="flex items-center text-xs"><div className="w-2 h-2 rounded-full bg-purple-500 mr-2"></div> <span className="text-gray-400">Action (35%)</span></div>
                        <div className="flex items-center text-xs"><div className="w-2 h-2 rounded-full bg-amber-500 mr-2"></div> <span className="text-gray-400">Comedy (25%)</span></div>
                        <div className="flex items-center text-xs"><div className="w-2 h-2 rounded-full bg-rose-500 mr-2"></div> <span className="text-gray-400">Drama (20%)</span></div>
                        <div className="flex items-center text-xs"><div className="w-2 h-2 rounded-full bg-emerald-500 mr-2"></div> <span className="text-gray-400">Sci-Fi (20%)</span></div>
                    </div>
                </div>
            </div>
            <div className="bg-[#1f2937] p-6 rounded-2xl border border-white/5">
                <h3 className="font-bold text-lg text-white mb-6">Quick Streaming Stats</h3>
                <div className="space-y-4">
                    <div>
                        <div className="flex justify-between text-xs mb-1 font-medium">
                            <span className="text-gray-400">Peak Hours (20:00 - 23:00)</span>
                            <span className="text-white">85% Capacity</span>
                        </div>
                        <div className="w-full bg-white/5 h-1.5 rounded-full overflow-hidden">
                            <div className="bg-[#0ea5e9] h-full w-[85%]"></div>
                        </div>
                    </div>
                    <div>
                        <div className="flex justify-between text-xs mb-1 font-medium">
                            <span className="text-gray-400">Mobile Data Users</span>
                            <span className="text-white">62%</span>
                        </div>
                        <div className="w-full bg-white/5 h-1.5 rounded-full overflow-hidden">
                            <div className="bg-purple-500 h-full w-[62%]"></div>
                        </div>
                    </div>
                    <div>
                        <div className="flex justify-between text-xs mb-1 font-medium">
                            <span className="text-gray-400">4K Streaming Shares</span>
                            <span className="text-white">18%</span>
                        </div>
                        <div className="w-full bg-white/5 h-1.5 rounded-full overflow-hidden">
                            <div className="bg-amber-500 h-full w-[18%]"></div>
                        </div>
                    </div>
                </div>
            </div>
          </div>
        </div>

        {/* Sidebar for Quick Actions & Health */}
        <div className="space-y-8">
            <div className="bg-[#1f2937] p-6 rounded-2xl border border-white/5">
                <h3 className="font-bold text-lg text-white mb-6">Quick Actions</h3>
                <div className="grid grid-cols-2 gap-3">
                    {quickActions.map((action, i) => (
                        <button
                            key={i}
                            onClick={action.onClick}
                            className={`${action.color} p-4 rounded-xl flex flex-col items-center justify-center text-white hover:opacity-90 transition-all transform active:scale-95 group shadow-lg`}
                        >
                            <div className="mb-2 group-hover:scale-110 transition-transform">
                                {action.icon}
                            </div>
                            <span className="text-[10px] font-black uppercase tracking-wider">{action.label}</span>
                        </button>
                    ))}
                </div>
            </div>

            <div className="bg-[#1f2937] p-6 rounded-2xl border border-white/5 overflow-hidden relative">
                <div className="flex items-center justify-between mb-6">
                    <h3 className="font-bold text-lg text-white">System Health</h3>
                    <span className="text-[10px] font-black text-green-500 bg-green-500/10 px-2 py-1 rounded">ALL SYSTEMS NORMAL</span>
                </div>
                <div className="space-y-4 relative z-10">
                    <div className="flex items-center justify-between bg-[#111827] p-3 rounded-xl border border-white/5">
                        <div className="flex items-center">
                            <div className="w-2 h-2 bg-green-500 rounded-full mr-3 animate-pulse shadow-[0_0_8px_rgba(34,197,94,0.6)]"></div>
                            <span className="text-xs text-gray-300 font-medium">API Gateway</span>
                        </div>
                        <span className="text-[10px] text-gray-500 font-bold uppercase tracking-widest">Active</span>
                    </div>
                    <div className="flex items-center justify-between bg-[#111827] p-3 rounded-xl border border-white/5">
                        <div className="flex items-center">
                            <div className="w-2 h-2 bg-green-500 rounded-full mr-3 shadow-[0_0_8px_rgba(34,197,94,0.6)]"></div>
                            <span className="text-xs text-gray-300 font-medium">Content Delivery</span>
                        </div>
                        <span className="text-[10px] text-gray-500 font-bold uppercase tracking-widest">Active</span>
                    </div>
                    <div className="flex items-center justify-between bg-[#111827] p-3 rounded-xl border border-white/5">
                        <div className="flex items-center">
                            <div className="w-2 h-2 bg-green-500 rounded-full mr-3 shadow-[0_0_8px_rgba(34,197,94,0.6)]"></div>
                            <span className="text-xs text-gray-300 font-medium">Database Cluster</span>
                        </div>
                        <span className="text-[10px] text-gray-500 font-bold uppercase tracking-widest">Active</span>
                    </div>
                </div>
                {/* Visual decoration */}
                <div className="absolute -bottom-4 -right-4 w-24 h-24 bg-[#0ea5e9]/5 rounded-full blur-2xl"></div>
            </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
