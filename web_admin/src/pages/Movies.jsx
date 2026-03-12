import React, { useState, useEffect } from 'react';
import {
  Plus,
  Search,
  X,
  Upload,
  Calendar,
  Image as ImageIcon,
  Play,
  Film,
  Loader2,
  CheckCircle2,
  AlertCircle
} from 'lucide-react';
import { movieService, uploadService } from '../services/api';

const Movies = () => {
  const [isAddingNew, setIsAddingNew] = useState(false);
  const [movies, setMovies] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  const [newMovie, setNewMovie] = useState({
    title: '',
    description: '',
    year: new Date().getFullYear(),
    duration: '',
    genre: ['Action'],
    posterUrl: '',
    videoUrl: '',
    trailerUrl: '',
    isTvShow: false,
    contentRating: '13+'
  });

  useEffect(() => {
    fetchMovies();
  }, []);

  const fetchMovies = async () => {
    setIsLoading(true);
    try {
      const data = await movieService.getAll();
      setMovies(data || []);
    } catch (err) {
      console.error('Error fetching movies:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreateMovie = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    try {
      await movieService.create({
        ...newMovie,
        year: parseInt(newMovie.year),
      });
      setIsAddingNew(false);
      fetchMovies();
      // Reset form
      setNewMovie({
        title: '',
        description: '',
        year: new Date().getFullYear(),
        duration: '',
        genre: ['Action'],
        posterUrl: '',
        videoUrl: '',
        trailerUrl: '',
        isTvShow: false,
        contentRating: '13+'
      });
    } catch (err) {
      console.error('Error creating movie:', err);
      alert('Failed to create movie');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteMovie = async (id) => {
    if (!window.confirm('Are you sure you want to delete this movie?')) return;
    try {
      await movieService.delete(id);
      fetchMovies();
    } catch (err) {
      console.error('Error deleting movie:', err);
    }
  };

  const handleTogglePublish = async (id, currentStatus) => {
    try {
      await movieService.publish(id, !currentStatus);
      fetchMovies();
    } catch (err) {
      console.error('Error updating status:', err);
    }
  };

  const filteredMovies = movies.filter(m =>
    m.title.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6 relative">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-[#1d2327]">Movies</h1>
        <button onClick={() => setIsAddingNew(true)} className="btn-primary">
          <Plus size={18} /> Add New Movie
        </button>
      </div>

      {/* Adding New Movie Modal */}
      {isAddingNew && (
        <div className="fixed inset-0 bg-black/50 z-[100] flex items-center justify-center p-4">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-[#dcdcde] flex items-center justify-between sticky top-0 bg-white z-10">
              <h2 className="text-xl font-bold">Add New Movie</h2>
              <button onClick={() => setIsAddingNew(false)} className="p-2 hover:bg-gray-100 rounded-full transition-colors">
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleCreateMovie} className="p-8 grid grid-cols-1 md:grid-cols-2 gap-8">
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-bold mb-1">Movie Title</label>
                  <input
                    type="text"
                    required
                    className="input-field w-full"
                    placeholder="Enter title"
                    value={newMovie.title}
                    onChange={(e) => setNewMovie({...newMovie, title: e.target.value})}
                  />
                </div>
                <div>
                  <label className="block text-sm font-bold mb-1">Overview / Synopsis</label>
                  <textarea
                    required
                    className="input-field w-full h-32 resize-none"
                    placeholder="Enter movie description"
                    value={newMovie.description}
                    onChange={(e) => setNewMovie({...newMovie, description: e.target.value})}
                  ></textarea>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-bold mb-1">Release Year</label>
                    <input
                      type="number"
                      className="input-field w-full"
                      placeholder="2024"
                      value={newMovie.year}
                      onChange={(e) => setNewMovie({...newMovie, year: e.target.value})}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-bold mb-1">Duration (min)</label>
                    <input
                      type="text"
                      className="input-field w-full"
                      placeholder="120"
                      value={newMovie.duration}
                      onChange={(e) => setNewMovie({...newMovie, duration: e.target.value})}
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-bold mb-1">Genre</label>
                  <select
                    className="input-field w-full"
                    onChange={(e) => setNewMovie({...newMovie, genre: [e.target.value]})}
                  >
                    <option>Action</option>
                    <option>Sci-Fi</option>
                    <option>Drama</option>
                    <option>Horror</option>
                    <option>Comedy</option>
                  </select>
                </div>
              </div>

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-bold mb-1">Poster URL</label>
                  <input
                    type="text"
                    className="input-field w-full"
                    placeholder="https://..."
                    value={newMovie.posterUrl}
                    onChange={(e) => setNewMovie({...newMovie, posterUrl: e.target.value})}
                  />
                </div>
                <div>
                  <label className="block text-sm font-bold mb-1">Video URL (m3u8/mp4)</label>
                  <input
                    type="text"
                    required
                    className="input-field w-full"
                    placeholder="https://..."
                    value={newMovie.videoUrl}
                    onChange={(e) => setNewMovie({...newMovie, videoUrl: e.target.value})}
                  />
                </div>
                <div>
                  <label className="block text-sm font-bold mb-1">Trailer URL</label>
                  <input
                    type="text"
                    className="input-field w-full"
                    placeholder="https://..."
                    value={newMovie.trailerUrl}
                    onChange={(e) => setNewMovie({...newMovie, trailerUrl: e.target.value})}
                  />
                </div>
                <div className="bg-blue-50 border border-blue-100 rounded-lg p-4 mt-4">
                  <div className="flex items-center gap-3 mb-2">
                    <AlertCircle size={16} className="text-blue-600" />
                    <span className="text-xs font-bold text-blue-800 uppercase">Pro Tip</span>
                  </div>
                  <p className="text-[11px] text-blue-700 leading-relaxed">
                    Use high-quality HLS (.m3u8) links for the best streaming experience across all devices.
                  </p>
                </div>
              </div>

              <div className="md:col-span-2 flex justify-end gap-4 border-t border-[#dcdcde] pt-6">
                <button type="button" onClick={() => setIsAddingNew(false)} className="btn-secondary">Cancel</button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="btn-primary px-8"
                >
                  {isSubmitting ? <Loader2 size={18} className="animate-spin" /> : 'Publish Movie'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Filters Bar */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          <select className="input-field text-sm py-1">
            <option>All Genres</option>
          </select>
          <select className="input-field text-sm py-1">
            <option>All Status</option>
          </select>
        </div>

        <div className="relative">
          <input
            type="text"
            placeholder="Search movies..."
            className="input-field pl-10 text-sm"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
          <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        </div>
      </div>

      {/* Movies Table */}
      <div className="admin-card overflow-hidden p-0">
        {isLoading ? (
          <div className="p-12 flex justify-center">
            <Loader2 size={32} className="animate-spin text-[#2271b1]" />
          </div>
        ) : (
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 border-b border-[#dcdcde] text-xs font-bold text-gray-500 uppercase">
                <th className="p-4 w-12"><input type="checkbox" /></th>
                <th className="p-4 w-20">Poster</th>
                <th className="p-4">Title</th>
                <th className="p-4 text-center">Status</th>
                <th className="p-4">Year</th>
                <th className="p-4 text-right pr-8">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#dcdcde]">
              {filteredMovies.map((movie) => (
                <tr key={movie._id} className="hover:bg-gray-50 group">
                  <td className="p-4"><input type="checkbox" /></td>
                  <td className="p-4">
                    <div className="w-10 h-14 bg-gray-200 rounded overflow-hidden shadow-sm">
                      <img
                        src={movie.posterUrl || 'https://via.placeholder.com/100x150'}
                        alt={movie.title}
                        className="w-full h-full object-cover"
                      />
                    </div>
                  </td>
                  <td className="p-4">
                    <div>
                      <p className="font-bold text-[#2271b1] hover:underline cursor-pointer">{movie.title}</p>
                      <p className="text-xs text-gray-500 mt-1">{movie.genre?.join(', ')} • {movie.duration}</p>
                    </div>
                  </td>
                  <td className="p-4 text-center">
                    <button
                      onClick={() => handleTogglePublish(movie._id, movie.isPublished)}
                      className={`px-2 py-0.5 rounded-full text-[10px] font-bold border uppercase transition-colors ${
                        movie.isPublished
                        ? 'text-green-600 bg-green-50 border-green-200 hover:bg-green-100'
                        : 'text-gray-600 bg-gray-50 border-gray-200 hover:bg-gray-100'
                      }`}
                    >
                      {movie.isPublished ? 'Published' : 'Draft'}
                    </button>
                  </td>
                  <td className="p-4 text-sm text-gray-600">{movie.year}</td>
                  <td className="p-4">
                    <div className="flex items-center justify-end gap-2 pr-4">
                      <button className="p-2 hover:bg-gray-100 rounded text-blue-600 transition-colors">
                        <Film size={16} />
                      </button>
                      <button
                        onClick={() => handleDeleteMovie(movie._id)}
                        className="p-2 hover:bg-red-50 rounded text-red-500 transition-colors"
                      >
                        <X size={16} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {filteredMovies.length === 0 && (
                <tr>
                  <td colSpan="6" className="p-12 text-center text-gray-500">
                    No movies found. Add your first movie to get started!
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default Movies;
