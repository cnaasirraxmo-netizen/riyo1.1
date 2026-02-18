import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import { Trophy, RefreshCcw, Wifi, MapPin, ExternalLink, Activity, Info, AlertCircle } from 'lucide-react';

const Sports = () => {
  const [fixtures, setFixtures] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchFixtures = async () => {
    setLoading(true);
    try {
      const res = await api.get('/sports/fixtures?live=all');
      setFixtures(res.data.response || []);
      setError(null);
    } catch (err) {
      setError('Service connection interrupted. Please verify your FOOTBALL_API_KEY configuration.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFixtures();
    const interval = setInterval(fetchFixtures, 60000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h1 className="text-4xl font-black text-white tracking-tight">Sports Intelligence</h1>
          <p className="text-gray-400 text-lg mt-1">Real-time global match monitoring system.</p>
        </div>
        <button
          onClick={fetchFixtures}
          className="bg-white hover:bg-gray-100 text-black px-8 py-3 rounded-2xl font-black text-sm transition-all shadow-xl active:scale-95 flex items-center gap-2"
        >
          <RefreshCcw size={18} className={loading ? 'animate-spin' : ''} />
          REFRESH SYSTEM
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-[#1C1C1C] p-6 rounded-3xl border border-white/5 flex items-center gap-6 relative overflow-hidden group">
          <div className="absolute inset-0 bg-green-500/5 translate-y-12 group-hover:translate-y-0 transition-transform duration-500"></div>
          <div className="p-4 bg-green-500/20 rounded-2xl text-green-500 z-10">
            <Wifi size={24} className="animate-pulse" />
          </div>
          <div className="z-10">
            <p className="text-gray-500 text-[10px] font-black uppercase tracking-widest">Network Status</p>
            <h3 className="text-xl font-black text-white mt-1 uppercase italic tracking-tighter">Live Stream Active</h3>
          </div>
        </div>
        <div className="bg-[#1C1C1C] p-6 rounded-3xl border border-white/5 flex items-center gap-6 relative overflow-hidden group">
          <div className="absolute inset-0 bg-purple-500/5 translate-y-12 group-hover:translate-y-0 transition-transform duration-500"></div>
          <div className="p-4 bg-purple-500/20 rounded-2xl text-purple-500 z-10">
            <Activity size={24} />
          </div>
          <div className="z-10">
            <p className="text-gray-500 text-[10px] font-black uppercase tracking-widest">Global Fixtures</p>
            <h3 className="text-xl font-black text-white mt-1 uppercase italic tracking-tighter">{fixtures.length} Active Matches</h3>
          </div>
        </div>
        <div className="bg-[#1C1C1C] p-6 rounded-3xl border border-white/5 flex items-center gap-6 relative overflow-hidden group">
          <div className="absolute inset-0 bg-blue-500/5 translate-y-12 group-hover:translate-y-0 transition-transform duration-500"></div>
          <div className="p-4 bg-blue-500/20 rounded-2xl text-blue-500 z-10">
            <Info size={24} />
          </div>
          <div className="z-10">
            <p className="text-gray-500 text-[10px] font-black uppercase tracking-widest">Service Provider</p>
            <h3 className="text-xl font-black text-white mt-1 uppercase italic tracking-tighter">API-Football v3</h3>
          </div>
        </div>
      </div>

      {error && (
        <div className="bg-red-500/10 border border-red-500/20 p-8 rounded-[32px] flex items-center gap-6 animate-in slide-in-from-top-4 duration-300">
          <div className="p-4 bg-red-500/20 rounded-2xl text-red-500">
            <AlertCircle size={32} />
          </div>
          <div>
            <h3 className="text-red-500 font-black uppercase tracking-widest text-sm">System Interruption</h3>
            <p className="text-red-500/70 text-sm font-medium mt-1">{error}</p>
          </div>
        </div>
      )}

      {loading && fixtures.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-40 space-y-6">
          <div className="w-16 h-16 border-4 border-white/5 border-t-white rounded-full animate-spin"></div>
          <div className="flex flex-col items-center">
            <p className="text-white font-black uppercase tracking-[0.3em] text-xs">Synchronizing Live Data</p>
            <p className="text-gray-600 text-[10px] font-bold mt-2 uppercase">Connecting to global sports exchange...</p>
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-8">
          {fixtures.map((item) => (
            <div key={item.fixture.id} className="bg-[#1C1C1C] rounded-[40px] p-8 border border-white/5 hover:border-white/10 transition-all group shadow-2xl relative overflow-hidden">
              <div className="absolute top-0 right-0 p-8 opacity-5 group-hover:opacity-10 transition-opacity">
                <Trophy size={120} />
              </div>

              <div className="flex justify-between items-center mb-10 relative z-10">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-white/5 p-2 border border-white/5 overflow-hidden">
                    <img src={item.league.logo} alt="" className="w-full h-full object-contain" />
                  </div>
                  <div className="flex flex-col">
                    <span className="text-white font-black text-xs uppercase tracking-widest">{item.league.name}</span>
                    <span className="text-gray-500 text-[10px] font-bold uppercase">{item.league.country}</span>
                  </div>
                </div>
                <div className="flex items-center gap-2 bg-green-500/10 text-green-500 px-4 py-2 rounded-full border border-green-500/20">
                  <div className="w-1.5 h-1.5 bg-green-500 rounded-full animate-pulse"></div>
                  <span className="text-[10px] font-black uppercase tracking-widest">
                    {item.fixture.status.elapsed}' - {item.fixture.status.long}
                  </span>
                </div>
              </div>

              <div className="flex items-center justify-between mb-10 relative z-10">
                <div className="flex flex-col items-center flex-1 space-y-4">
                  <div className="h-24 w-24 bg-gradient-to-br from-white/5 to-white/0 rounded-[32px] flex items-center justify-center p-6 border border-white/5 shadow-inner group-hover:scale-110 transition-transform duration-500">
                    <img src={item.teams.home.logo} alt="" className="max-h-full max-w-full object-contain filter drop-shadow-2xl" />
                  </div>
                  <span className="text-sm font-black text-center text-white uppercase tracking-tight max-w-[120px]">{item.teams.home.name}</span>
                </div>

                <div className="px-10 flex flex-col items-center justify-center">
                  <div className="flex items-center gap-6">
                    <span className="text-6xl font-black text-white tracking-tighter">{item.goals.home}</span>
                    <span className="text-2xl font-black text-gray-700">:</span>
                    <span className="text-6xl font-black text-white tracking-tighter">{item.goals.away}</span>
                  </div>
                  <div className="mt-4 px-4 py-1.5 bg-white/5 rounded-full border border-white/5 text-[9px] font-black text-gray-500 uppercase tracking-widest">
                    Live Indicator
                  </div>
                </div>

                <div className="flex flex-col items-center flex-1 space-y-4">
                  <div className="h-24 w-24 bg-gradient-to-br from-white/5 to-white/0 rounded-[32px] flex items-center justify-center p-6 border border-white/5 shadow-inner group-hover:scale-110 transition-transform duration-500">
                    <img src={item.teams.away.logo} alt="" className="max-h-full max-w-full object-contain filter drop-shadow-2xl" />
                  </div>
                  <span className="text-sm font-black text-center text-white uppercase tracking-tight max-w-[120px]">{item.teams.away.name}</span>
                </div>
              </div>

              <div className="pt-8 border-t border-white/5 flex justify-between items-center relative z-10">
                 <div className="flex items-center gap-2 text-gray-500 font-bold text-[10px] uppercase tracking-tighter">
                   <MapPin size={14} className="text-gray-700" />
                   {item.fixture.venue.name}, {item.fixture.venue.city}
                 </div>
                 <button className="flex items-center gap-2 text-white font-black text-[10px] uppercase tracking-widest group/btn bg-white/5 px-6 py-3 rounded-2xl hover:bg-white/10 transition-all border border-white/5">
                   DATA ANALYSIS
                   <ExternalLink size={14} className="group-hover/btn:translate-x-1 group-hover/btn:-translate-y-1 transition-transform" />
                 </button>
              </div>
            </div>
          ))}

          {fixtures.length === 0 && !loading && (
            <div className="col-span-full bg-[#1C1C1C] border border-white/5 rounded-[40px] py-40 text-center flex flex-col items-center justify-center">
               <div className="w-24 h-24 bg-white/5 rounded-full flex items-center justify-center text-5xl mb-8 border border-white/5">🏟️</div>
               <h3 className="text-3xl font-black text-white uppercase tracking-tighter">Stadium Silence</h3>
               <p className="text-gray-500 mt-2 font-medium">There are currently no active professional matches globally.</p>
               <button onClick={fetchFixtures} className="mt-10 text-purple-500 font-black uppercase tracking-widest text-xs hover:text-purple-400 transition-colors">Force System Sync</button>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default Sports;
