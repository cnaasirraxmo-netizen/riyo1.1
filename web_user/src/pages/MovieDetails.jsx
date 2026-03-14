import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../utils/api';
import { Play, Plus, ThumbsUp, Check, Star, Clock, Calendar, Globe, User } from 'lucide-react';
import { motion } from 'framer-motion';

const MovieDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [movie, setMovie] = useState(null);
  const [loading, setLoading] = useState(true);
  const [isInWatchlist, setIsInWatchlist] = useState(false);
  const [selectedSeason, setSelectedSeason] = useState(0);

  useEffect(() => {
    const fetchMovie = async () => {
      try {
        const res = await api.get(`/movies/${id}`);
        setMovie(res.data);
        if (res.data.isTvShow && res.data.seasons?.length > 0) {
          setSelectedSeason(0);
        }

        // Check watchlist
        const profileRes = await api.get('/users/profile');
        setIsInWatchlist(profileRes.data.watchlist?.some(m => m._id === id) || false);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    fetchMovie();
  }, [id]);

  const toggleWatchlist = async () => {
    try {
      const res = await api.post(`/users/watchlist/${id}`);
      setIsInWatchlist(res.data.isAdded);
    } catch (err) {
      console.error(err);
    }
  };

  if (loading) return (
    <div className="h-screen flex items-center justify-center bg-[#0a0a0a]">
      <div className="w-16 h-16 border-t-4 border-purple-600 border-solid rounded-full animate-spin"></div>
    </div>
  );

  if (!movie) return <div className="h-screen flex items-center justify-center text-white font-black uppercase italic">Content Missing</div>;

  return (
    <div className="min-h-screen bg-[#0a0a0a] text-white pt-20">
      {/* Background Stretcher */}
      <div className="absolute top-0 left-0 w-full h-[70vh] overflow-hidden opacity-30 z-0">
         <img src={movie.backdropUrl || movie.posterUrl} className="w-full h-full object-cover blur-2xl scale-110" alt="" />
         <div className="absolute inset-0 bg-gradient-to-b from-[#0a0a0a] via-transparent to-[#0a0a0a]"></div>
      </div>

      <div className="max-w-7xl mx-auto px-6 py-12 relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-16">

          {/* Poster Section */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="lg:col-span-4"
          >
            <div className="sticky top-32">
                <img
                    src={movie.posterUrl}
                    alt={movie.title}
                    className="w-full rounded-[2rem] shadow-[0_0_80px_rgba(0,0,0,0.5)] border-2 border-white/5"
                />
                <div className="mt-8 grid grid-cols-2 gap-4">
                    <div className="bg-white/5 p-4 rounded-2xl border border-white/5 text-center">
                        <div className="text-purple-500 font-black text-2xl">{movie.rating?.toFixed(1) || '8.5'}</div>
                        <div className="text-gray-500 text-[10px] font-black uppercase tracking-widest">IMDb Score</div>
                    </div>
                    <div className="bg-white/5 p-4 rounded-2xl border border-white/5 text-center">
                        <div className="text-white font-black text-2xl uppercase italic">{movie.quality || '4K'}</div>
                        <div className="text-gray-500 text-[10px] font-black uppercase tracking-widest">Master Quality</div>
                    </div>
                </div>
            </div>
          </motion.div>

          {/* Content Info */}
          <motion.div
            initial={{ opacity: 0, x: 30 }}
            animate={{ opacity: 1, x: 0 }}
            className="lg:col-span-8"
          >
            <div className="flex items-center space-x-3 mb-6">
                <div className="bg-purple-600/20 text-purple-500 px-4 py-1.5 rounded-full text-xs font-black uppercase tracking-[0.2em] border border-purple-500/30">
                    {movie.isTvShow ? 'TV Series' : 'Blockbuster'}
                </div>
                {movie.genre?.map((g, i) => (
                    <span key={i} className="text-gray-400 text-xs font-bold uppercase tracking-widest">{g}</span>
                ))}
            </div>

            <h1 className="text-6xl md:text-8xl font-black mb-8 uppercase italic leading-none tracking-tighter">
                {movie.title}
            </h1>

            <div className="flex flex-wrap items-center gap-8 mb-12 text-sm font-black uppercase tracking-[0.15em] text-gray-400">
                <div className="flex items-center space-x-2">
                    <Calendar size={18} className="text-purple-500" />
                    <span>{movie.year}</span>
                </div>
                <div className="flex items-center space-x-2">
                    <Clock size={18} className="text-purple-500" />
                    <span>{movie.duration}</span>
                </div>
                <div className="flex items-center space-x-2 border-2 border-white/20 px-3 py-1 rounded-lg">
                    <span>{movie.ageRating || 'PG-13'}</span>
                </div>
            </div>

            <div className="flex flex-wrap gap-6 mb-16">
              <button
                onClick={() => navigate(`/watch/${movie._id}`)}
                className="flex items-center space-x-4 bg-purple-600 text-white px-12 py-5 rounded-2xl hover:bg-purple-700 transition-all duration-300 font-black uppercase tracking-[0.2em] shadow-[0_20px_50px_rgba(147,51,234,0.3)] hover:scale-105 active:scale-95"
              >
                <Play fill="currentColor" size={24} />
                <span>Stream Now</span>
              </button>

              <button
                onClick={toggleWatchlist}
                className={`p-5 rounded-2xl border-2 transition-all duration-300 hover:scale-110 ${isInWatchlist ? 'bg-white border-white text-black' : 'border-white/10 text-white hover:bg-white/5'}`}
              >
                {isInWatchlist ? <Check size={28} /> : <Plus size={28} />}
              </button>

              <button className="p-5 rounded-2xl border-2 border-white/10 text-white hover:bg-white/5 hover:scale-110 transition-all">
                <ThumbsUp size={28} />
              </button>
            </div>

            <div className="space-y-8 mb-20">
                <h3 className="text-2xl font-black uppercase italic tracking-widest text-purple-500">Storyline</h3>
                <p className="text-xl text-gray-300 leading-relaxed font-medium">
                  {movie.description}
                </p>
            </div>

            {/* Episodes System */}
            {movie.isTvShow && movie.seasons && (
              <div className="mb-20 bg-white/5 p-10 rounded-[3rem] border border-white/5 backdrop-blur-md">
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-6 mb-10">
                  <h2 className="text-4xl font-black uppercase italic tracking-tighter">Episodes</h2>
                  <div className="flex bg-black/50 p-2 rounded-2xl">
                    {movie.seasons.map((season, idx) => (
                        <button
                            key={idx}
                            onClick={() => setSelectedSeason(idx)}
                            className={`px-8 py-3 rounded-xl font-black uppercase tracking-widest text-xs transition-all ${selectedSeason === idx ? 'bg-purple-600 text-white shadow-lg' : 'text-gray-500 hover:text-white'}`}
                        >
                            Season {season.number}
                        </button>
                    ))}
                  </div>
                </div>

                <div className="grid grid-cols-1 gap-4">
                  {movie.seasons[selectedSeason]?.episodes.map((episode, idx) => (
                    <motion.div
                      key={idx}
                      whileHover={{ x: 10 }}
                      className="group bg-black/30 hover:bg-purple-600/20 rounded-2xl p-6 flex items-center justify-between cursor-pointer transition-all border border-white/5 hover:border-purple-500/50"
                      onClick={() => navigate(`/watch/${movie._id}?s=${movie.seasons[selectedSeason].number}&e=${episode.number}`)}
                    >
                      <div className="flex items-center space-x-8">
                        <div className="text-3xl font-black italic text-gray-700 group-hover:text-purple-500 transition-colors w-12">{episode.number < 10 ? `0${episode.number}` : episode.number}</div>
                        <div>
                            <h4 className="text-xl font-black uppercase tracking-tight group-hover:text-white transition-colors">{episode.title}</h4>
                            <div className="flex items-center space-x-3 text-xs font-bold text-gray-500 uppercase mt-1">
                                <span>{episode.duration}</span>
                                <span className="w-1 h-1 bg-gray-700 rounded-full"></span>
                                <span className="text-purple-500/50">Available in HD</span>
                            </div>
                        </div>
                      </div>
                      <div className="w-12 h-12 rounded-full bg-white/5 flex items-center justify-center group-hover:bg-purple-600 group-hover:rotate-[360deg] transition-all duration-700">
                        <Play size={20} fill="currentColor" className="ml-1" />
                      </div>
                    </motion.div>
                  ))}
                </div>
              </div>
            )}

            {/* Meta Metadata */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-12 pt-16 border-t border-white/5">
              <MetaBlock icon={<Globe size={20} />} label="Country" value={movie.country || 'USA, Canada'} />
              <MetaBlock icon={<User size={20} />} label="Director" value={movie.director || 'Christopher Nolan'} />
              <MetaBlock icon={<Globe size={20} />} label="Language" value={movie.language || 'English, French'} />
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  );
};

const MetaBlock = ({ icon, label, value }) => (
    <div className="space-y-3">
        <div className="flex items-center space-x-2 text-purple-500">
            {icon}
            <span className="text-xs font-black uppercase tracking-[0.3em]">{label}</span>
        </div>
        <p className="text-sm font-bold text-gray-400">{value}</p>
    </div>
);

export default MovieDetails;
