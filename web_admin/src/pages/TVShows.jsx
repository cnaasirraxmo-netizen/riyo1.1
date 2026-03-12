import React, { useState, useEffect } from 'react';
import {
  Plus,
  Search,
  ChevronRight,
  ChevronDown,
  Film,
  Tv,
  MoreVertical,
  GripVertical,
  PlayCircle,
  Clock,
  Calendar,
  Image as ImageIcon,
  Loader2,
  X,
  Edit,
  Trash2
} from 'lucide-react';
import api from '../services/api';

const TVShows = () => {
  const [expandedShow, setExpandedShow] = useState(null);
  const [expandedSeason, setExpandedSeason] = useState(null);
  const [shows, setShows] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isAddingNew, setIsAddingNew] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    fetchShows();
  }, []);

  const fetchShows = async () => {
    setIsLoading(true);
    try {
      const res = await api.get('/admin/movies?isTvShow=true&paginate=false');
      setShows(res.data || []);
    } catch (err) {
      console.error('Error fetching shows:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const filteredShows = shows.filter(s =>
    s.title.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-[#1d2327] dark:text-white">TV Shows</h1>
        <button onClick={() => setIsAddingNew(true)} className="btn-primary">
          <Plus size={18} /> Add New Show
        </button>
      </div>

      <div className="admin-card p-0 overflow-hidden dark:bg-[#1e1e1e] dark:border-gray-800">
        <div className="p-4 border-b border-[#dcdcde] dark:border-gray-800 bg-gray-50 dark:bg-[#2c3338] flex items-center justify-between">
          <div className="relative">
            <input
              type="text"
              placeholder="Search shows..."
              className="input-field pl-10 text-sm py-1 w-64 dark:bg-[#1e1e1e] dark:border-gray-700 dark:text-white"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          </div>
        </div>

        {isLoading ? (
          <div className="p-12 flex justify-center">
            <Loader2 className="w-8 h-8 animate-spin text-[#2271b1]" />
          </div>
        ) : (
          <div className="divide-y divide-[#dcdcde] dark:divide-gray-800">
            {filteredShows.map(show => (
              <div key={show._id} className="bg-white dark:bg-[#1e1e1e]">
                <div
                  className={`p-4 flex items-center gap-4 hover:bg-gray-50 dark:hover:bg-[#2c3338] cursor-pointer transition-colors ${expandedShow === show._id ? 'bg-blue-50/30 dark:bg-blue-900/10' : ''}`}
                  onClick={() => setExpandedShow(expandedShow === show._id ? null : show._id)}
                >
                  <div className="w-10 h-14 bg-gray-200 dark:bg-gray-800 rounded overflow-hidden shadow-sm">
                    <img src={show.posterUrl || 'https://via.placeholder.com/100x150'} alt={show.title} className="w-full h-full object-cover" />
                  </div>
                  <div className="flex-1">
                    <h3 className="font-bold text-[#2271b1] dark:text-blue-400">{show.title}</h3>
                    <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{show.seasons?.length || 0} Seasons</p>
                  </div>
                  <div className="flex items-center gap-6">
                    <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold border ${show.isPublished ? 'bg-green-50 text-green-600 border-green-200 dark:bg-green-900/20 dark:text-green-400' : 'bg-gray-50 text-gray-600 border-gray-200 dark:bg-gray-800 dark:text-gray-400'}`}>
                      {show.isPublished ? 'PUBLISHED' : 'DRAFT'}
                    </span>
                    {expandedShow === show._id ? <ChevronDown size={20} className="text-gray-400" /> : <ChevronRight size={20} className="text-gray-400" />}
                  </div>
                </div>

                {expandedShow === show._id && (
                  <div className="bg-gray-50 dark:bg-[#1a1a1a] p-6 border-t border-[#dcdcde] dark:border-gray-800 space-y-6">
                    <div className="flex items-center justify-between">
                      <h4 className="text-sm font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400">Seasons Management</h4>
                      <button className="text-[12px] text-[#2271b1] dark:text-blue-400 font-bold flex items-center gap-1 hover:underline">
                        <Plus size={14} /> Add New Season
                      </button>
                    </div>

                    <div className="space-y-4">
                      {show.seasons?.map(season => (
                        <div key={season.number} className="bg-white dark:bg-[#252525] border border-[#dcdcde] dark:border-gray-800 rounded overflow-hidden">
                          <div
                            className="p-3 bg-white dark:bg-[#252525] flex items-center justify-between cursor-pointer hover:bg-gray-50 dark:hover:bg-[#2c3338]"
                            onClick={() => setExpandedSeason(expandedSeason === `${show._id}-${season.number}` ? null : `${show._id}-${season.number}`)}
                          >
                            <div className="flex items-center gap-3">
                              <div className="p-2 bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded">
                                <Tv size={16} />
                              </div>
                              <span className="font-bold text-sm dark:text-white">Season {season.number}: {season.title}</span>
                              <span className="text-xs text-gray-400">({season.episodes?.length || 0} episodes)</span>
                            </div>
                            {expandedSeason === `${show._id}-${season.number}` ? <ChevronDown size={18} className="text-gray-400" /> : <ChevronRight size={18} className="text-gray-400" />}
                          </div>

                          {expandedSeason === `${show._id}-${season.number}` && (
                            <div className="border-t border-[#dcdcde] dark:border-gray-800 p-4 bg-white dark:bg-[#1e1e1e] space-y-4">
                              <div className="flex items-center justify-between mb-4">
                                <span className="text-xs font-bold text-gray-400 uppercase">Episodes List</span>
                                <button className="btn-primary py-1 px-3 text-xs"><Plus size={14} /> Add Episode</button>
                              </div>

                              <div className="space-y-2">
                                {season.episodes?.length > 0 ? season.episodes.map((ep, idx) => (
                                  <div key={idx} className="group flex items-center gap-4 p-3 border border-gray-100 dark:border-gray-800 rounded hover:border-blue-200 dark:hover:border-blue-800 hover:bg-blue-50/20 dark:hover:bg-blue-900/10 transition-all">
                                    <div className="cursor-grab text-gray-300 dark:text-gray-600">
                                      <GripVertical size={16} />
                                    </div>
                                    <div className="w-16 h-10 bg-gray-100 dark:bg-gray-800 rounded flex items-center justify-center text-gray-400 dark:text-gray-600">
                                      <ImageIcon size={16} />
                                    </div>
                                    <div className="flex-1 min-w-0">
                                      <p className="text-sm font-bold text-gray-800 dark:text-gray-200 truncate">E{ep.number}: {ep.title}</p>
                                      <div className="flex items-center gap-3 mt-1">
                                        <span className="text-[11px] text-gray-500 dark:text-gray-400 flex items-center gap-1"><Clock size={10} /> {ep.duration}</span>
                                      </div>
                                    </div>
                                    <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100">
                                      <button className="p-1 hover:bg-gray-200 dark:hover:bg-gray-700 rounded text-gray-500 dark:text-gray-400"><Edit size={14} /></button>
                                      <button className="p-1 hover:bg-red-100 dark:hover:bg-red-900/30 rounded text-red-500"><Trash2 size={14} /></button>
                                    </div>
                                  </div>
                                )) : (
                                  <div className="text-center py-8 text-gray-400 dark:text-gray-500 text-sm italic">
                                    No episodes added to this season yet.
                                  </div>
                                )}
                              </div>
                            </div>
                          )}
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            ))}
            {filteredShows.length === 0 && (
              <div className="p-12 text-center text-gray-500 dark:text-gray-400">
                No TV shows found.
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default TVShows;
