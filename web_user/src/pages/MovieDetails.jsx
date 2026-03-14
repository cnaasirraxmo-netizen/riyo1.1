import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../utils/api';
import { Play, Plus, ThumbsUp, X, Check } from 'lucide-react';

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
        setIsInWatchlist(profileRes.data.watchlist.some(m => m._id === id));
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

  if (loading) return <div className="h-screen flex items-center justify-center">
    <div className="w-12 h-12 border-4 border-purple-600 border-t-transparent rounded-full animate-spin"></div>
  </div>;

  if (!movie) return <div className="h-screen flex items-center justify-center">Movie not found</div>;

  return (
    <div className="pt-20 min-h-screen bg-[#141414]">
      <div className="max-w-6xl mx-auto px-4 py-8">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
          <div className="md:col-span-1">
            <img
              src={movie.posterUrl}
              alt={movie.title}
              className="w-full rounded-lg shadow-2xl border border-white/5"
            />
          </div>

          <div className="md:col-span-2">
            <h1 className="text-4xl md:text-6xl font-black mb-4 uppercase tracking-tighter">{movie.title}</h1>

            <div className="flex items-center space-x-4 mb-8 text-sm md:text-base font-medium">
              <span className="text-green-500 font-bold">98% Match</span>
              <span className="text-gray-400">{movie.year}</span>
              <span className="border border-white/40 px-2 rounded text-xs py-0.5 uppercase tracking-wider">{movie.contentRating || '13+'}</span>
              <span className="text-gray-400">{movie.duration}</span>
              <span className="bg-white/10 px-2 py-0.5 rounded text-[10px] font-bold">HD</span>
            </div>

            <div className="flex flex-wrap gap-4 mb-10">
              <button
                onClick={() => navigate(`/watch/${movie._id}`)}
                className="flex items-center space-x-3 bg-white text-black px-10 py-3 rounded hover:bg-white/90 transition-colors font-bold uppercase tracking-wider"
              >
                <Play fill="black" size={24} />
                <span>Play</span>
              </button>

              <button
                onClick={toggleWatchlist}
                className="p-3 border-2 border-white/30 rounded-full hover:border-white transition-colors"
                title="Add to My List"
              >
                {isInWatchlist ? <Check /> : <Plus />}
              </button>

              <button className="p-3 border-2 border-white/30 rounded-full hover:border-white transition-colors">
                <ThumbsUp />
              </button>
            </div>

            <p className="text-lg text-gray-200 leading-relaxed mb-10 font-medium">
              {movie.description}
            </p>

            {movie.isTvShow && movie.seasons && (
              <div className="mb-12">
                <div className="flex items-center justify-between mb-6">
                  <h2 className="text-2xl font-bold">Episodes</h2>
                  <select
                    className="bg-[#262626] border border-white/10 rounded px-4 py-2 text-sm focus:outline-none"
                    value={selectedSeason}
                    onChange={(e) => setSelectedSeason(parseInt(e.target.value))}
                  >
                    {movie.seasons.map((season, idx) => (
                      <option key={idx} value={idx}>{season.title}</option>
                    ))}
                  </select>
                </div>

                <div className="space-y-4">
                  {movie.seasons[selectedSeason]?.episodes.map((episode, idx) => (
                    <div
                      key={idx}
                      className="group bg-white/5 hover:bg-white/10 rounded-lg p-4 flex items-center cursor-pointer transition-colors"
                    onClick={() => navigate(`/watch/${movie._id}?s=${movie.seasons[selectedSeason].number}&e=${episode.number}`)}
                    >
                      <div className="w-10 text-gray-500 font-bold text-xl">{episode.number}</div>
                      <div className="flex-1">
                        <h4 className="font-bold group-hover:text-purple-400 transition-colors">{episode.title}</h4>
                        <p className="text-xs text-gray-500">{episode.duration}</p>
                      </div>
                      <div className="p-2 rounded-full bg-white/10 group-hover:bg-purple-600 transition-all opacity-0 group-hover:opacity-100">
                        <Play size={16} fill="white" />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8 pt-8 border-t border-white/10">
              <div>
                <span className="text-gray-500 block text-xs font-bold uppercase mb-2">Genres</span>
                <p className="text-sm font-medium">{movie.genre?.join(', ') || 'Action, Drama'}</p>
              </div>
              <div>
                <span className="text-gray-500 block text-xs font-bold uppercase mb-2">Audio</span>
                <p className="text-sm font-medium">English, Somali, Arabic</p>
              </div>
              <div>
                <span className="text-gray-500 block text-xs font-bold uppercase mb-2">Subtitles</span>
                <p className="text-sm font-medium">English, Arabic</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MovieDetails;
