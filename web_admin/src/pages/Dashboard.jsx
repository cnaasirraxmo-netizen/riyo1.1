import React, { useState, useEffect } from 'react';
import {
  Film,
  Tv,
  Users,
  Activity,
  DollarSign,
  TrendingUp,
  Clock,
  PlusCircle,
  UserPlus,
  CreditCard,
  Loader2
} from 'lucide-react';
import { systemService } from '../services/api';

const Dashboard = () => {
  const [stats, setStats] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    fetchStats();
    // Refresh every 30 seconds
    const interval = setInterval(fetchStats, 30000);
    return () => clearInterval(interval);
  }, []);

  const fetchStats = async () => {
    try {
      const data = await systemService.getStats();
      setStats(data);
    } catch (err) {
      console.error('Error fetching stats:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const statItems = [
    { title: 'Total Movies', value: stats?.totalMovies || 0, icon: <Film size={24} />, color: 'text-blue-600', bg: 'bg-blue-100' },
    { title: 'Total TV Shows', value: stats?.totalTVShows || 0, icon: <Tv size={24} />, color: 'text-purple-600', bg: 'bg-purple-100' },
    { title: 'Total Users', value: stats?.totalUsers?.toLocaleString() || 0, icon: <Users size={24} />, color: 'text-green-600', bg: 'bg-green-100' },
    { title: 'Active Streams', value: stats?.activeStreams || 0, icon: <Activity size={24} />, color: 'text-orange-600', bg: 'bg-orange-100' },
    { title: 'Total Revenue', value: `$${stats?.totalRevenue || 0}`, icon: <DollarSign size={24} />, color: 'text-emerald-600', bg: 'bg-emerald-100' },
    { title: 'Trending Movie', value: stats?.trendingMovie || 'N/A', icon: <TrendingUp size={24} />, color: 'text-red-600', bg: 'bg-red-100' },
  ];

  const recentActivity = [
    { id: 1, type: 'upload', title: 'New movie uploaded', description: 'Inception (2010) was added to the library', time: '2 mins ago', icon: <PlusCircle size={16} /> },
    { id: 2, type: 'episode', title: 'New episode uploaded', description: 'Stranger Things S04E08', time: '15 mins ago', icon: <Film size={16} /> },
    { id: 3, type: 'user', title: 'New user registered', description: 'john.doe@example.com joined RIYO', time: '1 hour ago', icon: <UserPlus size={16} /> },
    { id: 4, type: 'sub', title: 'New subscription', description: 'Premium Plan - $9.99/mo', time: '2 hours ago', icon: <CreditCard size={16} /> },
  ];

  if (isLoading && !stats) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-[#2271b1]" />
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[#1d2327] dark:text-white">Dashboard</h1>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Welcome to RIYO streaming platform administration.</p>
        </div>
        {isLoading && <Loader2 className="w-5 h-5 animate-spin text-blue-500" />}
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
        {statItems.map((stat, index) => (
          <div key={index} className="admin-card flex items-center gap-4 hover:shadow-md transition-shadow cursor-default dark:bg-[#1e1e1e] dark:border-gray-800">
            <div className={`p-3 rounded-lg ${stat.bg} ${stat.color}`}>
              {stat.icon}
            </div>
            <div className="min-w-0">
              <p className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider truncate">{stat.title}</p>
              <p className="text-xl font-bold text-gray-900 dark:text-white truncate">{stat.value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Charts Mockups */}
        <div className="lg:col-span-2 space-y-8">
          <div className="admin-card dark:bg-[#1e1e1e] dark:border-gray-800">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-bold flex items-center gap-2 dark:text-white">
                <Activity size={20} className="text-blue-600" /> Daily Streams
              </h2>
              <select className="input-field text-xs py-1 dark:bg-[#2c3338] dark:border-gray-700 dark:text-white">
                <option>Last 7 days</option>
                <option>Last 30 days</option>
              </select>
            </div>
            <div className="h-64 w-full bg-gray-50 dark:bg-[#2c3338] rounded-lg border border-dashed border-gray-300 dark:border-gray-700 flex items-center justify-center">
              <p className="text-gray-400 dark:text-gray-500 italic">Streams Analytics Chart Visualization</p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="admin-card dark:bg-[#1e1e1e] dark:border-gray-800">
              <h2 className="text-lg font-bold mb-4 flex items-center gap-2 dark:text-white">
                <UserPlus size={20} className="text-green-600" /> User Growth
              </h2>
              <div className="h-48 bg-gray-50 dark:bg-[#2c3338] rounded-lg border border-dashed border-gray-300 dark:border-gray-700 flex items-center justify-center">
                <p className="text-gray-400 dark:text-gray-500 text-xs italic">User Growth Chart</p>
              </div>
            </div>
            <div className="admin-card dark:bg-[#1e1e1e] dark:border-gray-800">
              <h2 className="text-lg font-bold mb-4 flex items-center gap-2 dark:text-white">
                <TrendingUp size={20} className="text-red-600" /> Top Content
              </h2>
              <div className="space-y-3">
                {[1, 2, 3, 4].map(i => (
                  <div key={i} className="flex items-center justify-between text-sm">
                    <span className="text-gray-600 dark:text-gray-400">{i}. Movie Title Here</span>
                    <span className="font-bold dark:text-white">2.4k views</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* Recent Activity */}
        <div className="space-y-8">
          <div className="admin-card dark:bg-[#1e1e1e] dark:border-gray-800">
            <h2 className="text-lg font-bold mb-6 flex items-center gap-2 dark:text-white">
              <Clock size={20} className="text-orange-600" /> Recent Activity
            </h2>
            <div className="space-y-6">
              {recentActivity.map((activity) => (
                <div key={activity.id} className="flex gap-4">
                  <div className="mt-1 p-2 bg-gray-100 dark:bg-[#2c3338] rounded text-gray-600 dark:text-gray-400">
                    {activity.icon}
                  </div>
                  <div>
                    <p className="text-sm font-bold text-gray-900 dark:text-white">{activity.title}</p>
                    <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">{activity.description}</p>
                    <p className="text-[10px] text-gray-400 dark:text-gray-500 mt-1 uppercase font-semibold">{activity.time}</p>
                  </div>
                </div>
              ))}
            </div>
            <button className="w-full mt-8 text-sm text-[#2271b1] hover:text-[#135e96] font-semibold border-t border-gray-100 dark:border-gray-800 pt-4">
              View All Activity
            </button>
          </div>

          <div className="admin-card bg-[#1e1e1e] border-none text-white">
            <h2 className="text-lg font-bold mb-4">Quick Press</h2>
            <form className="space-y-4">
              <input type="text" placeholder="Title" className="w-full bg-[#32373c] border-none rounded p-2 text-sm outline-none focus:ring-1 focus:ring-blue-500" />
              <textarea placeholder="What's on your mind?" className="w-full bg-[#32373c] border-none rounded p-2 text-sm outline-none focus:ring-1 focus:ring-blue-500 h-24 resize-none"></textarea>
              <button type="button" className="bg-[#2271b1] px-4 py-2 rounded text-sm font-semibold hover:bg-blue-600 transition-colors">Save Draft</button>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
