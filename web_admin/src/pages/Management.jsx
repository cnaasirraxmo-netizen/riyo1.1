import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import { Play, Send, Star, Clock } from 'lucide-react';

const Management = () => {
  const [movies, setMovies] = useState([]);
  const [loading, setLoading] = useState(true);
  const [publishModal, setPublishModal] = useState(null);
  const [fullVideoUrl, setFullVideoUrl] = useState('');
  const [publishType, setPublishType] = useState('free');

  const fetchMovies = async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/movies');
      setMovies(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMovies();
  }, []);

  const handlePublish = async () => {
    if (!fullVideoUrl) return alert('Please enter full movie URL');
    try {
      await api.put(`/admin/movies/${publishModal._id}/publish`, {
        videoUrl: fullVideoUrl,
        contentType: publishType
      });
      setPublishModal(null);
      setFullVideoUrl('');
      fetchMovies();
      alert('Movie published successfully!');
    } catch (err) {
      alert('Publication failed');
    }
  };

  const comingSoon = movies.filter(m => m.contentType === 'coming_soon');
  const premium = movies.filter(m => m.contentType === 'premium');
  const hasTrailers = movies.filter(m => m.trailerUrl);

  return (
    <div className="space-y-10 pb-20">
      <div>
        <h1 className="text-3xl font-bold">Content Management</h1>
        <p className="text-gray-400">Manage upcoming releases, trailers, and premium status.</p>
      </div>

      {/* Coming Soon System */}
      <section className="bg-[#1C1C1C] rounded-xl border border-white/5 overflow-hidden">
        <div className="p-6 border-b border-white/5 bg-[#262626] flex items-center">
           <Clock className="text-blue-500 mr-3" />
           <h2 className="text-xl font-bold">Coming Soon System</h2>
        </div>
        <div className="p-0">
          <table className="w-full text-left">
            <thead>
              <tr className="text-gray-500 text-xs uppercase tracking-wider border-b border-white/5">
                <th className="px-6 py-4">Movie</th>
                <th className="px-6 py-4">Trailer Status</th>
                <th className="px-6 py-4">Subscribers</th>
                <th className="px-6 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {comingSoon.length === 0 ? (
                <tr><td colSpan="4" className="px-6 py-10 text-center text-gray-500 italic">No upcoming movies scheduled.</td></tr>
              ) : comingSoon.map(movie => (
                <tr key={movie._id} className="hover:bg-white/[0.02]">
                  <td className="px-6 py-4 font-bold">{movie.title}</td>
                  <td className="px-6 py-4">
                    <span className="text-xs px-2 py-1 bg-green-500/10 text-green-500 rounded flex items-center w-fit">
                      <Play size={10} className="mr-1" /> Active Trailer
                    </span>
                  </td>
                  <td className="px-6 py-4 text-gray-400">{movie.notifyUsers?.length || 0} notified users</td>
                  <td className="px-6 py-4 text-right">
                    <button
                      onClick={() => setPublishModal(movie)}
                      className="bg-purple-600 hover:bg-purple-700 text-white text-xs font-bold px-4 py-2 rounded-lg transition-all flex items-center ml-auto"
                    >
                      <Send size={14} className="mr-2" /> PUBLISH NOW
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      {/* Premium & Trailer Status */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <section className="bg-[#1C1C1C] rounded-xl border border-white/5 p-6">
           <h3 className="text-lg font-bold mb-4 flex items-center">
             <Star className="text-yellow-500 mr-2" /> Premium Content ({premium.length})
           </h3>
           <div className="space-y-3">
              {premium.map(m => (
                <div key={m._id} className="p-3 bg-[#262626] rounded-lg flex justify-between items-center">
                  <span>{m.title}</span>
                  <span className="text-[10px] bg-yellow-500/20 text-yellow-500 px-2 py-1 rounded font-black uppercase">Premium</span>
                </div>
              ))}
           </div>
        </section>

        <section className="bg-[#1C1C1C] rounded-xl border border-white/5 p-6">
           <h3 className="text-lg font-bold mb-4 flex items-center">
             <Play className="text-purple-500 mr-2" /> Trailer Management
           </h3>
           <div className="space-y-3 max-h-60 overflow-y-auto custom-scrollbar">
              {hasTrailers.map(m => (
                <div key={m._id} className="p-3 bg-[#262626] rounded-lg">
                  <div className="flex justify-between items-center mb-1">
                    <span className="font-medium">{m.title}</span>
                    <a href={m.trailerUrl} target="_blank" rel="noreferrer" className="text-xs text-purple-400 hover:underline">View Trailer</a>
                  </div>
                  <p className="text-[10px] text-gray-500 truncate">{m.trailerUrl}</p>
                </div>
              ))}
           </div>
        </section>
      </div>

      {/* Publish Modal */}
      {publishModal && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4 z-50">
           <div className="bg-[#1C1C1C] max-w-md w-full rounded-2xl p-6 border border-white/10 shadow-2xl">
              <h2 className="text-xl font-bold mb-2">Publish "{publishModal.title}"</h2>
              <p className="text-gray-400 text-sm mb-6">Users who requested notification will be alerted immediately.</p>

              <div className="space-y-4">
                <div>
                  <label className="block text-xs text-gray-500 font-bold mb-1">FULL MOVIE VIDEO URL</label>
                  <input
                    className="w-full bg-[#262626] border border-white/10 rounded px-4 py-2 text-sm focus:border-purple-500 outline-none"
                    placeholder="Enter full MP4/HLS URL"
                    value={fullVideoUrl}
                    onChange={(e) => setFullVideoUrl(e.target.value)}
                  />
                </div>
                <div>
                   <label className="block text-xs text-gray-500 font-bold mb-1">AVAILABILITY TYPE</label>
                   <select
                    className="w-full bg-[#262626] border border-white/10 rounded px-4 py-2 text-sm focus:border-purple-500 outline-none"
                    value={publishType}
                    onChange={(e) => setPublishType(e.target.value)}
                   >
                     <option value="free">Free for all</option>
                     <option value="premium">Premium only</option>
                   </select>
                </div>
                <div className="pt-4 flex gap-3">
                   <button onClick={() => setPublishModal(null)} className="flex-1 py-3 text-sm font-bold text-gray-400 hover:text-white transition-colors">CANCEL</button>
                   <button onClick={handlePublish} className="flex-1 bg-purple-600 hover:bg-purple-700 py-3 rounded-lg text-sm font-black transition-all">CONFIRM PUBLISH</button>
                </div>
              </div>
           </div>
        </div>
      )}
    </div>
  );
};

export default Management;
