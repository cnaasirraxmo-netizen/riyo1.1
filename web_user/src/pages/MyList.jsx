import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../utils/api';
import { motion } from 'framer-motion';

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
    <div className="h-screen flex items-center justify-center bg-[#0a0a0a]">
      <div className="w-16 h-16 border-t-4 border-purple-600 border-solid rounded-full animate-spin"></div>
    </div>
  );

  return (
    <div className="pt-32 min-h-screen bg-[#0a0a0a] px-6 md:px-20 pb-20">
      <div className="flex flex-col space-y-2 mb-16 border-l-8 border-purple-600 pl-8">
        <h1 className="text-6xl font-black text-white italic uppercase tracking-tighter leading-none">Your Library</h1>
        <p className="text-gray-500 font-bold uppercase tracking-widest text-xs">Saved titles and collections</p>
      </div>

      {movies.length === 0 ? (
        <div className="text-center py-32 bg-white/5 rounded-[3rem] border-2 border-dashed border-white/10">
           <div className="text-8xl font-black text-white/5 uppercase italic mb-8">Empty List</div>
           <p className="text-gray-500 font-black uppercase tracking-[0.3em] text-xs mb-12">Start adding your favorite movies and series</p>
           <button
                onClick={() => navigate('/')}
                className="bg-purple-600 text-white px-12 py-4 rounded-2xl font-black uppercase tracking-widest hover:bg-purple-700 transition-all shadow-[0_20px_50px_rgba(147,51,234,0.3)] hover:scale-105"
            >
                Discover Content
            </button>
        </div>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-10">
          {movies.map((movie, idx) => (
            <motion.div
              key={movie._id || movie.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: idx * 0.05 }}
              onClick={() => navigate(`/movie/${movie._id || movie.id}`)}
              className="relative aspect-[2/3] rounded-3xl overflow-hidden cursor-pointer group shadow-2xl border-2 border-transparent hover:border-purple-600 transition-all"
            >
              <img src={movie.posterUrl} className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110" alt={movie.title} />
              <div className="absolute inset-0 bg-black/80 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col justify-end p-6 backdrop-blur-sm">
                 <h3 className="font-black text-white italic uppercase tracking-tighter text-lg leading-none">{movie.title}</h3>
                 <span className="text-purple-500 text-[10px] font-black uppercase tracking-widest mt-2">{movie.year}</span>
              </div>
            </motion.div>
          ))}
        </div>
      )}
    </div>
  );
};

export default MyList;
