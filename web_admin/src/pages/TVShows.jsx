import React, { useState } from 'react';
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
  Image as ImageIcon
} from 'lucide-react';

const TVShows = () => {
  const [expandedShow, setExpandedShow] = useState(null);
  const [expandedSeason, setExpandedSeason] = useState(null);

  const shows = [
    {
      id: 1,
      title: 'Stranger Things',
      seasons: [
        {
          id: 101,
          number: 1,
          episodes: [
            { id: 1001, title: 'The Vanishing of Will Byers', duration: '48 min', date: '2016-07-15' },
            { id: 1002, title: 'The Weirdo on Maple Street', duration: '55 min', date: '2016-07-15' },
          ]
        },
        { id: 102, number: 2, episodes: [] }
      ],
      poster: 'https://picsum.photos/seed/stranger/100/150'
    },
    { id: 2, title: 'The Witcher', seasons: [], poster: 'https://picsum.photos/seed/witcher/100/150' },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-[#1d2327]">TV Shows</h1>
        <button className="btn-primary"><Plus size={18} /> Add New Show</button>
      </div>

      <div className="admin-card p-0 overflow-hidden">
        <div className="p-4 border-b border-[#dcdcde] bg-gray-50 flex items-center justify-between">
          <div className="relative">
            <input type="text" placeholder="Search shows..." className="input-field pl-10 text-sm py-1 w-64" />
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          </div>
          <div className="flex gap-2">
            <button className="btn-secondary py-1 text-sm">Bulk Actions</button>
          </div>
        </div>

        <div className="divide-y divide-[#dcdcde]">
          {shows.map(show => (
            <div key={show.id} className="bg-white">
              <div
                className={`p-4 flex items-center gap-4 hover:bg-gray-50 cursor-pointer transition-colors ${expandedShow === show.id ? 'bg-blue-50/30' : ''}`}
                onClick={() => setExpandedShow(expandedShow === show.id ? null : show.id)}
              >
                <div className="w-10 h-14 bg-gray-200 rounded overflow-hidden shadow-sm">
                  <img src={show.poster} alt={show.title} className="w-full h-full object-cover" />
                </div>
                <div className="flex-1">
                  <h3 className="font-bold text-[#2271b1]">{show.title}</h3>
                  <p className="text-xs text-gray-500 mt-1">{show.seasons.length} Seasons</p>
                </div>
                <div className="flex items-center gap-6">
                  <span className="px-2 py-0.5 rounded-full bg-green-50 text-green-600 text-[10px] font-bold border border-green-200">PUBLISHED</span>
                  {expandedShow === show.id ? <ChevronDown size={20} className="text-gray-400" /> : <ChevronRight size={20} className="text-gray-400" />}
                </div>
              </div>

              {expandedShow === show.id && (
                <div className="bg-gray-50 p-6 border-t border-[#dcdcde] space-y-6">
                  <div className="flex items-center justify-between">
                    <h4 className="text-sm font-bold uppercase tracking-wider text-gray-500">Seasons Management</h4>
                    <button className="text-[12px] text-[#2271b1] font-bold flex items-center gap-1 hover:underline">
                      <Plus size={14} /> Add New Season
                    </button>
                  </div>

                  <div className="space-y-4">
                    {show.seasons.map(season => (
                      <div key={season.id} className="bg-white border border-[#dcdcde] rounded overflow-hidden">
                        <div
                          className="p-3 bg-white flex items-center justify-between cursor-pointer hover:bg-gray-50"
                          onClick={() => setExpandedSeason(expandedSeason === season.id ? null : season.id)}
                        >
                          <div className="flex items-center gap-3">
                            <div className="p-2 bg-blue-100 text-blue-600 rounded">
                              <Tv size={16} />
                            </div>
                            <span className="font-bold text-sm">Season {season.number}</span>
                            <span className="text-xs text-gray-400">({season.episodes.length} episodes)</span>
                          </div>
                          {expandedSeason === season.id ? <ChevronDown size={18} className="text-gray-400" /> : <ChevronRight size={18} className="text-gray-400" />}
                        </div>

                        {expandedSeason === season.id && (
                          <div className="border-t border-[#dcdcde] p-4 bg-white space-y-4">
                            <div className="flex items-center justify-between mb-4">
                              <span className="text-xs font-bold text-gray-400">EPISODES LIST</span>
                              <button className="btn-primary py-1 px-3 text-xs"><Plus size={14} /> Add Episode</button>
                            </div>

                            <div className="space-y-2">
                              {season.episodes.length > 0 ? season.episodes.map((ep, idx) => (
                                <div key={ep.id} className="group flex items-center gap-4 p-3 border border-gray-100 rounded hover:border-blue-200 hover:bg-blue-50/20 transition-all">
                                  <div className="cursor-grab text-gray-300">
                                    <GripVertical size={16} />
                                  </div>
                                  <div className="w-16 h-10 bg-gray-100 rounded flex items-center justify-center text-gray-400">
                                    <ImageIcon size={16} />
                                  </div>
                                  <div className="flex-1 min-w-0">
                                    <p className="text-sm font-bold text-gray-800 truncate">E{idx + 1}: {ep.title}</p>
                                    <div className="flex items-center gap-3 mt-1">
                                      <span className="text-[11px] text-gray-500 flex items-center gap-1"><Clock size={10} /> {ep.duration}</span>
                                      <span className="text-[11px] text-gray-500 flex items-center gap-1"><Calendar size={10} /> {ep.date}</span>
                                    </div>
                                  </div>
                                  <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100">
                                    <button className="p-1 hover:bg-gray-200 rounded text-gray-500"><Edit size={14} /></button>
                                    <button className="p-1 hover:bg-red-100 rounded text-red-500"><Trash2 size={14} /></button>
                                  </div>
                                </div>
                              )) : (
                                <div className="text-center py-8 text-gray-400 text-sm italic">
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
        </div>
      </div>
    </div>
  );
};

export default TVShows;
