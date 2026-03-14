import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../utils/api';
import { motion } from 'framer-motion';
import { Bookmark, Sparkles, Zap } from 'lucide-react';

const MyList = () => {
  const [movies, setMovies] = useState([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchWatchlist = async () => {
      try {
        const res = await api.get('/users/profile');
        setMovies(res.data.watchlist || []);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    fetchWatchlist();
  }, []);

  if (loading) return (
    <div className="h-screen bg-[#050505] p-24">
        <div className="grid grid-cols-5 gap-12">
            {[1, 2, 3, 4, 5].map(i => <div key={i} className="aspect-[2/3] skeleton rounded-[2rem]"></div>)}
        </div>
    </div>
  );

  return (
    <div className="pt-40 min-h-screen bg-[#050505] px-6 md:px-16 pb-32">
      <div className="max-w-[120rem] mx-auto">
        <div className="flex flex-col space-y-4 mb-24 border-l-[10px] border-purple-600 pl-10">
            <div className="flex items-center space-x-3 text-purple-500">
                <Bookmark size={20} fill="currentColor" />
                <span className="text-xs font-black uppercase tracking-[0.5em]">Curated Library</span>
            </div>
            <h1 className="text-7xl md:text-9xl font-black text-white italic uppercase tracking-tighter leading-[0.85]">Your<br/>Collections</h1>
        </div>

        {movies.length === 0 ? (
            <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                className="text-center py-40 bg-white/[0.02] rounded-[4rem] border-2 border-dashed border-white/5"
            >
                <Sparkles size={80} className="mx-auto text-slate-800 mb-10" />
                <div className="text-[6rem] font-black text-white/5 uppercase italic mb-6">Archive Empty</div>
                <p className="text-slate-500 font-black uppercase tracking-[0.4em] text-xs mb-16">Your private sanctuary is awaiting content</p>
                <button
                    onClick={() => navigate('/')}
                    className="bg-purple-600 text-white px-16 py-6 rounded-[2rem] font-black uppercase tracking-[0.3em] text-sm hover:bg-purple-700 transition-all shadow-[0_30px_100px_rgba(139,92,246,0.3)] hover:scale-105 active:scale-95"
                >
                    Explore Universe
                </button>
            </motion.div>
        ) : (
            <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-12">
            {movies.map((movie, idx) => (
                <motion.div
                key={movie._id || movie.id}
                initial={{ opacity: 0, y: 30 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: idx * 0.05 }}
                whileHover={{ y: -15 }}
                onClick={() => navigate(`/movie/${movie._id || movie.id}`)}
                className="relative aspect-[2/3] rounded-[2.5rem] overflow-hidden cursor-pointer group shadow-[0_40px_80px_rgba(0,0,0,0.6)] border border-white/5 hover:border-purple-600 transition-all duration-500"
                >
                <img src={movie.posterUrl} className="w-full h-full object-cover transition-transform duration-1000 group-hover:scale-110" alt="" />
                <div className="absolute inset-0 bg-gradient-to-t from-[#050505] via-[#050505]/20 to-transparent opacity-0 group-hover:opacity-100 transition-all duration-500 flex flex-col justify-end p-8 backdrop-blur-[4px]">
                    <div className="flex items-center space-x-2 mb-3">
                        <Zap size={14} className="text-purple-500 fill-purple-500" />
                        <span className="text-[10px] font-black uppercase tracking-widest text-purple-400">Archived</span>
                    </div>
                    <h3 className="font-black text-white italic uppercase tracking-tighter text-2xl leading-none mb-2">{movie.title}</h3>
                    <span className="text-slate-500 text-[10px] font-black uppercase tracking-[0.2em]">{movie.year} • Verified Source</span>
                </div>
                </motion.div>
            ))}
            </div>
        )}
      </div>
    </div>
  );
};

export default MyList;
