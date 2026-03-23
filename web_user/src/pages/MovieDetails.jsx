import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../utils/api';
import { Play, Plus, ThumbsUp, Check, Star, Clock, Calendar, Globe, User, Shield, Share2, Zap } from 'lucide-react';
import { motion } from 'framer-motion';

const MovieDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [movie, setMovie] = useState(null);
  const [loading, setLoading] = useState(true);
  const [isInWatchlist, setIsInWatchlist] = useState(false);
  const [selectedSeason, setSelectedSeason] = useState(0);
  const [sources, setSources] = useState([]);
  const [isLoadingSources, setIsLoadingSources] = useState(false);

  useEffect(() => {
    const fetchMovie = async () => {
      try {
        const res = await api.get(`/movies/${id}`);
        setMovie(res.data);
        if (res.data.isTvShow && res.data.seasons?.length > 0) {
          setSelectedSeason(0);
        }

        const profileRes = await api.get('/users/profile');
        setIsInWatchlist(profileRes.data.watchlist?.some(m => m._id === id) || false);

        if (res.data.sourceType !== 'admin') {
          fetchSources();
        }
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    fetchMovie();
  }, [id]);

  const fetchSources = async () => {
    setIsLoadingSources(true);
    try {
      const response = await api.get(`/api/v1/movie/${id}/sources`);
      setSources(response.data.sources || []);
    } catch (err) {
      console.error(err);
    } finally {
      setIsLoadingSources(false);
    }
  };

  const toggleWatchlist = async () => {
    try {
      const res = await api.post(`/users/watchlist/${id}`);
      setIsInWatchlist(res.data.isAdded);
    } catch (err) {
      console.error(err);
    }
  };

  if (loading) return <div className="h-screen bg-[#050505] flex items-center justify-center"><div className="w-16 h-16 skeleton rounded-full"></div></div>;

  if (!movie) return <div className="h-screen flex items-center justify-center text-white font-black uppercase italic">Content Unavailable</div>;

  return (
    <div className="min-h-screen bg-[#050505] text-white">
      {/* Dynamic Backdrop */}
      <div className="fixed inset-0 z-0 h-[60vh] w-full overflow-hidden opacity-40">
         <img src={movie.backdropUrl || movie.posterUrl} className="w-full h-full object-cover blur-3xl scale-125" alt="" />
         <div className="absolute inset-0 bg-gradient-to-b from-transparent via-[#050505]/80 to-[#050505]"></div>
      </div>

      <div className="relative z-10 max-w-7xl mx-auto px-6 py-24 md:py-32">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-16 md:gap-24">

          {/* Visual Content */}
          <motion.div
            initial={{ opacity: 0, y: 50 }}
            animate={{ opacity: 1, y: 0 }}
            className="lg:col-span-4"
          >
            <div className="sticky top-32">
                <div className="relative group">
                    <img
                        src={movie.posterUrl}
                        alt={movie.title}
                        className="w-full rounded-[2.5rem] shadow-[0_40px_100px_rgba(0,0,0,0.8)] border border-white/10 group-hover:scale-[1.02] transition-transform duration-700"
                    />
                    <div className="absolute inset-0 rounded-[2.5rem] bg-gradient-to-t from-purple-900/40 to-transparent opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none"></div>
                </div>

                <div className="mt-10 grid grid-cols-1 gap-4">
                    <div className="glass p-6 rounded-[1.5rem] flex items-center justify-between">
                        <div className="flex items-center space-x-3">
                            <div className="w-10 h-10 rounded-full bg-yellow-400/10 flex items-center justify-center text-yellow-400">
                                <Star size={20} fill="currentColor" />
                            </div>
                            <span className="text-[10px] font-black uppercase tracking-widest text-slate-500">Global Score</span>
                        </div>
                        <div className="text-2xl font-black">{movie.rating?.toFixed(1) || '8.5'}</div>
                    </div>
                </div>
            </div>
          </motion.div>

          {/* Metadata & Actions */}
          <motion.div
            initial={{ opacity: 0, x: 50 }}
            animate={{ opacity: 1, x: 0 }}
            className="lg:col-span-8 pt-8"
          >
            <div className="flex flex-wrap items-center gap-3 mb-8">
                <div className="bg-purple-600 px-4 py-1.5 rounded-full text-[9px] font-black uppercase tracking-[0.25em]">
                    {movie.isTvShow ? 'Premium Series' : 'Cinema Original'}
                </div>
                {movie.genre?.map((g, i) => (
                    <span key={i} className="bg-white/5 border border-white/10 px-4 py-1.5 rounded-full text-[9px] font-black uppercase tracking-widest text-slate-400">{g}</span>
                ))}
            </div>

            <h1 className="text-6xl md:text-8xl font-black mb-8 leading-[0.9] tracking-tighter uppercase italic">
                {movie.title}
            </h1>

            <div className="flex flex-wrap items-center gap-10 mb-16 text-[11px] font-black uppercase tracking-[0.2em] text-slate-500">
                <div className="flex items-center space-x-2">
                    <Calendar size={16} className="text-purple-500" />
                    <span>{movie.year}</span>
                </div>
                <div className="flex items-center space-x-2">
                    <Clock size={16} className="text-purple-500" />
                    <span>{movie.duration}</span>
                </div>
                <div className="flex items-center space-x-2 border border-white/20 px-3 py-1 rounded-md">
                    <span>{movie.ageRating || 'PG-13'}</span>
                </div>
                <div className="flex items-center space-x-2">
                    <Shield size={16} className="text-green-500" />
                    <span className="text-green-500">Licensed</span>
                </div>
            </div>

            <div className="flex flex-wrap items-center gap-6 mb-20">
              <button
                onClick={() => navigate(`/watch/${movie._id}`)}
                className="flex items-center space-x-4 bg-purple-600 text-white px-14 py-6 rounded-2xl hover:bg-purple-700 transition-all duration-300 font-black uppercase tracking-[0.3em] text-sm shadow-[0_20px_50px_rgba(139,92,246,0.3)] hover:scale-105 active:scale-95"
              >
                <Play fill="currentColor" size={24} />
                <span>Play Now</span>
              </button>

              <button
                onClick={toggleWatchlist}
                className={`p-6 rounded-2xl border border-white/10 transition-all duration-300 hover:scale-110 ${isInWatchlist ? 'bg-white text-black border-white' : 'glass text-white hover:bg-white/10'}`}
              >
                {isInWatchlist ? <Check size={28} /> : <Plus size={28} />}
              </button>

              <button className="p-6 rounded-2xl border border-white/10 glass text-white hover:scale-110 transition-all">
                <Share2 size={24} />
              </button>
            </div>

            <div className="space-y-6 mb-20">
                <div className="flex items-center space-x-4">
                    <div className="h-[2px] w-12 bg-purple-600"></div>
                    <h3 className="text-xs font-black uppercase tracking-[0.4em] text-purple-500">Overview</h3>
                </div>
                <p className="text-xl md:text-2xl text-slate-300 leading-relaxed font-light">
                  {movie.description}
                </p>
            </div>

            {/* Streaming Sources */}
            {!movie.isTvShow && movie.sourceType !== 'admin' && (
              <div className="mb-20">
                <div className="flex items-center space-x-4 mb-8">
                    <div className="h-[2px] w-12 bg-purple-600"></div>
                    <h3 className="text-xs font-black uppercase tracking-[0.4em] text-purple-500">Available Servers</h3>
                </div>
                <div className="flex flex-wrap gap-4">
                  {isLoadingSources ? (
                    <div className="text-slate-500 font-bold uppercase text-[10px] tracking-widest animate-pulse">Searching for best mirrors...</div>
                  ) : sources.length > 0 ? (
                    sources.map((source, idx) => (
                      <button
                        key={idx}
                        onClick={() => navigate(`/watch/${movie._id}?url=${encodeURIComponent(source.url)}`)}
                        className="glass px-6 py-3 rounded-xl border border-white/10 hover:border-purple-600 transition-all text-white group flex items-center space-x-3"
                      >
                        <Zap size={14} className="text-purple-500" />
                        <div className="flex flex-col items-start leading-none">
                            <span className="text-[8px] font-black uppercase tracking-widest text-slate-500 mb-1">{source.provider}</span>
                            <span className="text-xs font-black uppercase tracking-widest">{source.label} ({source.quality})</span>
                        </div>
                      </button>
                    ))
                  ) : (
                    <div className="text-slate-500 font-bold uppercase text-[10px] tracking-widest">No direct sources found.</div>
                  )}
                </div>
              </div>
            )}

            {/* Premium Episode List */}
            {movie.isTvShow && movie.seasons && (
              <div className="mb-24">
                <div className="flex flex-col md:flex-row md:items-end justify-between gap-8 mb-12">
                  <div>
                      <h2 className="text-4xl font-black uppercase italic tracking-tighter mb-2">Seasons</h2>
                      <p className="text-slate-500 font-bold uppercase text-[10px] tracking-widest">Select chapter to browse episodes</p>
                  </div>
                  <div className="flex bg-white/5 p-1.5 rounded-2xl border border-white/5">
                    {movie.seasons.map((season, idx) => (
                        <button
                            key={idx}
                            onClick={() => setSelectedSeason(idx)}
                            className={`px-8 py-3 rounded-xl font-black uppercase tracking-widest text-[10px] transition-all ${selectedSeason === idx ? 'bg-purple-600 text-white shadow-xl' : 'text-slate-500 hover:text-white'}`}
                        >
                            S{season.number}
                        </button>
                    ))}
                  </div>
                </div>

                <div className="grid grid-cols-1 gap-4">
                  {movie.seasons[selectedSeason]?.episodes.map((episode, idx) => (
                    <motion.div
                      key={idx}
                      whileHover={{ x: 15 }}
                      className="group glass-dark hover:bg-purple-600/10 rounded-[1.5rem] p-8 flex items-center justify-between cursor-pointer transition-all border border-white/5 hover:border-purple-500/50"
                      onClick={() => navigate(`/watch/${movie._id}?s=${movie.seasons[selectedSeason].number}&e=${episode.number}`)}
                    >
                      <div className="flex items-center space-x-10">
                        <div className="text-4xl font-black italic text-slate-800 group-hover:text-purple-600 transition-colors">{episode.number < 10 ? `0${episode.number}` : episode.number}</div>
                        <div>
                            <h4 className="text-xl font-extrabold uppercase tracking-tight group-hover:text-white transition-colors mb-1">{episode.title}</h4>
                            <div className="flex items-center space-x-4 text-[9px] font-black text-slate-500 uppercase tracking-widest">
                                <span>{episode.duration}</span>
                                <div className="w-1.5 h-1.5 bg-slate-800 rounded-full"></div>
                                <span className="text-purple-500/80">Premium Access</span>
                            </div>
                        </div>
                      </div>
                      <div className="w-14 h-14 rounded-2xl bg-white/5 flex items-center justify-center group-hover:bg-purple-600 group-hover:rotate-[15deg] transition-all duration-500 shadow-2xl">
                        <Play size={20} fill="currentColor" className="ml-1 text-white" />
                      </div>
                    </motion.div>
                  ))}
                </div>
              </div>
            )}

            {/* Technical Specs */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-16 pt-16 border-t border-white/5">
              <Spec icon={<Globe size={20} />} label="Production" value={movie.country || 'Global'} />
              <Spec icon={<User size={20} />} label="Direction" value={movie.director || 'Studio'} />
              <Spec icon={<Globe size={20} />} label="Language" value={movie.language || 'English'} />
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  );
};

const Spec = ({ icon, label, value }) => (
    <div className="space-y-4">
        <div className="flex items-center space-x-3 text-purple-600">
            {icon}
            <span className="text-[10px] font-black uppercase tracking-[0.4em]">{label}</span>
        </div>
        <p className="text-sm font-extrabold text-slate-400">{value}</p>
    </div>
);

export default MovieDetails;
