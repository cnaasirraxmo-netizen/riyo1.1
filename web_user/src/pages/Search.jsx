import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../utils/api';
import { Search as SearchIcon, ArrowLeft } from 'lucide-react';
import { motion } from 'framer-motion';

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
    }, 500);

    return () => clearTimeout(delayDebounceFn);
  }, [query]);

  return (
    <div className="pt-32 min-h-screen bg-[#0a0a0a] px-6 md:px-20">
      <div className="max-w-4xl mx-auto mb-20">
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="relative"
        >
          <SearchIcon size={32} className="absolute left-6 top-1/2 -translate-y-1/2 text-purple-500" />
          <input
            autoFocus
            type="text"
            placeholder="Search by title, genre, or keyword..."
            className="w-full bg-white/5 border-2 border-white/10 rounded-[2rem] py-8 pl-20 pr-8 text-2xl font-black italic uppercase tracking-tighter focus:border-purple-600 focus:bg-white/10 outline-none transition-all placeholder:text-gray-700"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </motion.div>
      </div>

      {loading ? (
        <div className="flex flex-col items-center py-20 space-y-4">
             <div className="w-10 h-10 border-t-2 border-purple-600 rounded-full animate-spin"></div>
             <div className="text-gray-500 font-black uppercase tracking-widest text-xs italic">Scanning Database...</div>
        </div>
      ) : results.length > 0 ? (
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-10">
          {results.map((movie, idx) => (
            <motion.div
              key={movie._id || movie.id}
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: idx * 0.05 }}
              onClick={() => navigate(`/movie/${movie._id || movie.id}`)}
              className="relative aspect-[2/3] rounded-3xl overflow-hidden cursor-pointer group shadow-2xl border-2 border-transparent hover:border-purple-600 transition-all"
            >
              <img src={movie.posterUrl} className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110" alt={movie.title} />
              <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col justify-end p-6 backdrop-blur-sm">
                <h3 className="font-black text-white italic uppercase tracking-tighter text-lg leading-none">{movie.title}</h3>
                <span className="text-purple-500 text-[10px] font-black uppercase tracking-widest mt-2">{movie.year}</span>
              </div>
            </motion.div>
          ))}
        </div>
      ) : query && (
        <div className="text-center py-20">
           <div className="text-6xl font-black text-white/5 uppercase italic mb-4">No Results</div>
           <p className="text-gray-500 font-bold uppercase tracking-widest text-xs">No matches found for "{query}"</p>
        </div>
      )}
    </div>
  );
};

export default Search;
