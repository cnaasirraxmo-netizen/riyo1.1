import React, { useState, useEffect } from 'react';
import {
  TrendingUp,
  Users,
  Play,
  Clock,
  Calendar,
  ArrowUpRight,
  ArrowDownRight,
  Filter,
  Download,
  Eye,
  BarChart3,
  PieChart as PieChartIcon,
  Loader2
} from 'lucide-react';
import { systemService } from '../services/api';

const Analytics = () => {
  const [isLoading, setIsLoading] = useState(true);
  const [stats, setStats] = useState(null);
  const [timeRange, setTimeRange] = useState('7d');

  useEffect(() => {
    fetchAnalytics();
  }, [timeRange]);

  const fetchAnalytics = async () => {
    setIsLoading(true);
    try {
      const data = await systemService.getStats();
      setStats(data);
    } catch (err) {
      console.error('Error fetching analytics:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const metricCards = [
    { title: 'Total Views', value: stats?.totalViews?.toLocaleString() || '1.2M', trend: '+12.5%', isUp: true, icon: <Eye size={20} />, color: 'blue' },
    { title: 'Avg. Watch Time', value: '42m', trend: '+5.2%', isUp: true, icon: <Clock size={20} />, color: 'purple' },
    { title: 'Active Sessions', value: stats?.activeStreams || '842', trend: '-2.4%', isUp: false, icon: <Users size={20} />, color: 'green' },
    { title: 'Completion Rate', value: '78%', trend: '+0.8%', isUp: true, icon: <TrendingUp size={20} />, color: 'orange' },
  ];

  const popularMovies = [
    { id: 1, title: 'Inception', views: '142.5k', growth: '+15%', status: 'Trending' },
    { id: 2, title: 'Interstellar', views: '98.2k', growth: '+8%', status: 'Popular' },
    { id: 3, title: 'The Dark Knight', views: '85.4k', growth: '-2%', status: 'Steady' },
    { id: 4, title: 'Dunkirk', views: '72.1k', growth: '+22%', status: 'Rising' },
  ];

  if (isLoading && !stats) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="w-10 h-10 animate-spin text-blue-600" />
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-[#1d2327] dark:text-white">Content Performance Analytics</h1>
          <p className="text-sm text-gray-500 mt-1">Deep dive into your streaming platform's audience and content trends.</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex bg-white dark:bg-[#1e1e1e] border border-[#dcdcde] dark:border-gray-800 rounded-lg p-1">
            {['24h', '7d', '30d', '90d'].map(range => (
              <button
                key={range}
                onClick={() => setTimeRange(range)}
                className={`px-4 py-1.5 text-xs font-bold rounded-md transition-all ${
                  timeRange === range ? 'bg-blue-600 text-white shadow-md' : 'text-gray-500 hover:bg-gray-50'
                }`}
              >
                {range.toUpperCase()}
              </button>
            ))}
          </div>
          <button className="btn-secondary py-2"><Download size={16} /> Export CSV</button>
        </div>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {metricCards.map((card, idx) => (
          <div key={idx} className="admin-card hover:shadow-lg transition-all border-l-4 border-l-blue-600">
            <div className="flex items-center justify-between mb-4">
              <div className={`p-2 bg-gray-50 dark:bg-gray-800 rounded-lg text-gray-600`}>
                {card.icon}
              </div>
              <div className={`flex items-center gap-1 text-xs font-bold ${card.isUp ? 'text-green-600' : 'text-red-500'}`}>
                {card.isUp ? <ArrowUpRight size={14} /> : <ArrowDownRight size={14} />} {card.trend}
              </div>
            </div>
            <p className="text-xs font-bold text-gray-500 uppercase tracking-widest">{card.title}</p>
            <p className="text-2xl font-black text-gray-900 dark:text-white mt-1">{card.value}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Main Chart Card */}
        <div className="lg:col-span-2 admin-card h-[450px] flex flex-col">
          <div className="flex items-center justify-between mb-8">
            <h2 className="text-lg font-bold flex items-center gap-2">
              <BarChart3 size={20} className="text-blue-600" /> Views Trend Over Time
            </h2>
            <div className="flex items-center gap-4 text-xs font-bold text-gray-400">
              <span className="flex items-center gap-2"><div className="w-3 h-3 bg-blue-600 rounded-full"></div> This Period</span>
              <span className="flex items-center gap-2"><div className="w-3 h-3 bg-gray-200 rounded-full"></div> Last Period</span>
            </div>
          </div>
          <div className="flex-1 bg-gray-50 dark:bg-[#1a1a1a] rounded-xl border-2 border-dashed border-gray-200 dark:border-gray-800 flex items-center justify-center relative overflow-hidden">
             <div className="absolute inset-0 opacity-10 bg-[radial-gradient(circle_at_50%_50%,#2563eb_0,transparent_50%)]"></div>
             <p className="text-gray-400 font-bold text-sm z-10">Advanced Data Visualization Components Loading...</p>
          </div>
        </div>

        {/* Top Content Card */}
        <div className="admin-card h-[450px] flex flex-col">
          <h2 className="text-lg font-bold mb-6 flex items-center gap-2">
            <TrendingUp size={20} className="text-red-500" /> Popular Content
          </h2>
          <div className="space-y-6 flex-1 overflow-y-auto pr-2">
            {popularMovies.map((movie) => (
              <div key={movie.id} className="group p-3 hover:bg-gray-50 dark:hover:bg-gray-800 rounded-lg transition-colors border border-transparent hover:border-gray-100">
                <div className="flex items-center justify-between mb-2">
                   <p className="font-bold text-sm dark:text-white group-hover:text-blue-600 transition-colors">{movie.title}</p>
                   <span className={`text-[10px] font-black uppercase px-2 py-0.5 rounded-full ${
                     movie.status === 'Trending' ? 'bg-red-100 text-red-600' : 'bg-blue-100 text-blue-600'
                   }`}>{movie.status}</span>
                </div>
                <div className="flex items-center justify-between">
                   <div className="flex items-center gap-4 text-[11px] text-gray-500 font-bold">
                     <span className="flex items-center gap-1"><Eye size={12} /> {movie.views}</span>
                     <span className="text-green-600">{movie.growth}</span>
                   </div>
                   <div className="w-24 h-1.5 bg-gray-100 rounded-full overflow-hidden">
                      <div className="h-full bg-blue-600 rounded-full" style={{ width: '70%' }}></div>
                   </div>
                </div>
              </div>
            ))}
          </div>
          <button className="w-full mt-6 py-3 text-xs font-black text-gray-500 border-t hover:text-blue-600 transition-colors uppercase tracking-widest">
            Detailed Content Report
          </button>
        </div>
      </div>
    </div>
  );
};

export default Analytics;
