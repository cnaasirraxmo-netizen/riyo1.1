import React, { useState, useEffect } from 'react';
import api from '../utils/api';

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
      setError('Failed to fetch live matches. Ensure FOOTBALL_API_KEY is configured in backend.');
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
    <div className="text-white">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold">Sports Monitor</h1>
          <p className="text-gray-400">Real-time football match monitoring and system control.</p>
        </div>
        <button
          onClick={fetchFixtures}
          className="bg-yellow-500 hover:bg-yellow-600 px-6 py-2 rounded-lg font-bold transition-colors text-black flex items-center"
        >
          <span className="mr-2">🔄</span> Refresh Now
        </button>
      </div>

      <div className="bg-purple-900/10 border border-purple-500/20 p-4 rounded-xl mb-8 flex items-center justify-between">
        <div className="flex items-center">
          <div className="h-3 w-3 bg-green-500 rounded-full animate-pulse mr-3"></div>
          <span className="text-sm font-medium">Backend Sync: <span className="text-green-500">Active</span></span>
        </div>
        <div className="text-xs text-gray-500 italic">
          Fetching from API-Football every 60 seconds
        </div>
      </div>

      {loading && fixtures.length === 0 ? (
        <div className="text-center py-20 text-gray-500 italic">Connecting to API-Football service...</div>
      ) : error ? (
        <div className="bg-red-900/20 border border-red-900/50 p-6 rounded-xl text-red-400">
          <p className="font-bold mb-1">Service Error</p>
          <p className="text-sm">{error}</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {fixtures.map((item) => (
            <div key={item.fixture.id} className="bg-[#1C1C1C] rounded-xl p-6 border border-white/5 hover:border-white/10 transition-colors">
              <div className="flex justify-between text-[10px] text-gray-500 mb-4 uppercase tracking-widest font-black">
                <span>{item.league.name} • {item.league.country}</span>
                <span className="bg-green-500/10 text-green-500 px-2 py-1 rounded">
                   {item.fixture.status.long} {item.fixture.status.elapsed && `• ${item.fixture.status.elapsed}'`}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <div className="flex flex-col items-center flex-1">
                  <div className="h-16 w-16 bg-white/5 rounded-full flex items-center justify-center p-3 mb-3">
                    <img src={item.teams.home.logo} alt="" className="max-h-full max-w-full object-contain" />
                  </div>
                  <span className="text-xs font-black text-center uppercase tracking-tighter">{item.teams.home.name}</span>
                </div>

                <div className="px-6 flex flex-col items-center">
                  <div className="text-4xl font-black text-yellow-500 tracking-tighter">
                    {item.goals.home} - {item.goals.away}
                  </div>
                  <div className="text-[10px] text-gray-600 font-bold mt-2 uppercase">Live Score</div>
                </div>

                <div className="flex flex-col items-center flex-1">
                  <div className="h-16 w-16 bg-white/5 rounded-full flex items-center justify-center p-3 mb-3">
                    <img src={item.teams.away.logo} alt="" className="max-h-full max-w-full object-contain" />
                  </div>
                  <span className="text-xs font-black text-center uppercase tracking-tighter">{item.teams.away.name}</span>
                </div>
              </div>

              <div className="mt-6 pt-4 border-t border-white/5 flex justify-between items-center text-[10px]">
                 <span className="text-gray-500 italic">Venue: {item.fixture.venue.name}, {item.fixture.venue.city}</span>
                 <button className="text-purple-500 font-bold hover:underline">VIEW FULL STATS</button>
              </div>
            </div>
          ))}
          {fixtures.length === 0 && !loading && (
            <div className="col-span-full bg-[#1C1C1C] border border-white/5 rounded-2xl py-20 text-center">
               <div className="text-4xl mb-4">🏟️</div>
               <h3 className="text-xl font-bold">No Live Matches</h3>
               <p className="text-gray-500 mt-2">There are currently no live matches being monitored.</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default Sports;
