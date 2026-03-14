import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../utils/api';
import { Search as SearchIcon, ArrowLeft, Zap, Sparkles } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const Search = () => {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    if (query.trim() === '') {
      setResults([]);
      return;
    }

    const delayDebounceFn = setTimeout(async () => {
      setLoading(true);
      try {
        const res = await api.get(`/api/v1/search?query=${query}`);
        setResults(res.data || []);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    }, 400);

    return () => clearTimeout(delayDebounceFn);
  }, [query]);

  return (
    <div className="pt-40 min-h-screen bg-[#050505] px-6 md:px-20 pb-20">
      <div className="max-w-5xl mx-auto mb-32">
        <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            className="relative"
        >
          <div className="absolute -inset-1 bg-gradient-to-r from-purple-600 to-pink-600 rounded-[2.5rem] blur opacity-25 group-focus-within:opacity-50 transition duration-1000"></div>
          <div className="relative flex items-center bg-[#0f0f0f] border border-white/5 rounded-[2.5rem] p-4 shadow-2xl focus-within:border-purple-500/50 transition-all">
            <SearchIcon size={32} className="ml-6 text-purple-500" />
            <input
                autoFocus
                type="text"
                placeholder="Search the RIYOBOX universe..."
                className="w-full bg-transparent border-none py-6 pl-6 pr-8 text-3xl font-black italic uppercase tracking-tighter focus:ring-0 outline-none text-white placeholder:text-slate-800"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
            />
            {query && (
                <button
                    onClick={() => setQuery('')}
                    className="mr-6 p-2 bg-white/5 rounded-full hover:bg-white/10 transition-colors"
                >
                    <Sparkles size={20} className="text-purple-500" />
                </button>
            )}
          </div>
        </motion.div>
      </div>

      <div className="max-w-[120rem] mx-auto">
        {loading ? (
            <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-12">
                {[1, 2, 3, 4, 5].map(i => <div key={i} className="aspect-[2/3] skeleton rounded-[2rem]"></div>)}
            </div>
        ) : results.length > 0 ? (
            <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-12">
            {results.map((movie, idx) => (
                <motion.div
                key={movie._id || movie.id}
                initial={{ opacity: 0, scale: 0.9, y: 20 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                transition={{ delay: idx * 0.05 }}
                onClick={() => navigate(`/movie/${movie._id || movie.id}`)}
                className="relative aspect-[2/3] rounded-[2rem] overflow-hidden cursor-pointer group shadow-[0_30px_60px_rgba(0,0,0,0.5)] border border-white/5 hover:border-purple-600 transition-all duration-500"
                >
                <img src={movie.posterUrl} className="w-full h-full object-cover transition-transform duration-1000 group-hover:scale-110 group-hover:rotate-1" alt="" />
                <div className="absolute inset-0 bg-gradient-to-t from-[#0a0a0a] via-[#0a0a0a]/40 to-transparent opacity-0 group-hover:opacity-100 transition-all duration-500 flex flex-col justify-end p-8 backdrop-blur-[2px]">
                    <div className="flex items-center space-x-2 mb-3">
                        <Zap size={14} className="text-purple-500 fill-purple-500" />
                        <span className="text-[10px] font-black uppercase tracking-[0.3em] text-purple-400">Available</span>
                    </div>
                    <h3 className="font-black text-white italic uppercase tracking-tighter text-2xl leading-none mb-2">{movie.title}</h3>
                    <span className="text-slate-500 text-[10px] font-black uppercase tracking-widest">{movie.year} • Master Quality</span>
                </div>
                </motion.div>
            ))}
            </div>
        ) : query && (
            <div className="text-center py-40">
                <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    className="text-[10rem] font-black text-white/[0.02] uppercase italic leading-none"
                >
                    Void
                </motion.div>
                <p className="text-slate-500 font-black uppercase tracking-[0.5em] text-xs -mt-10">No signals detected for "{query}"</p>
            </div>
        )}
      </div>
    </div>
  );
};

export default Search;
