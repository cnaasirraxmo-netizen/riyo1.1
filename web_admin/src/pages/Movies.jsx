import React, { useState, useEffect, useMemo } from 'react';
import {
  Plus,
  Search,
  X,
  Upload,
  Play,
  Film,
  Loader2,
  Settings,
  Link as LinkIcon,
  Trash2,
  Edit3,
  Eye,
  Check,
  AlertCircle,
  Clock,
  Calendar,
  Filter,
  ArrowUpDown,
  ChevronDown,
  Star
} from 'lucide-react';
import { movieService, api } from '../services/api';

const Movies = () => {
  const [movies, setMovies] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingMovieId, setEditingMovieId] = useState(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);

  // Filter & Sort State
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all'); // all, active, draft
  const [sortBy, setSortBy] = useState('newest'); // newest, title

  const initialMovieState = {
    title: '',
    description: '',
    year: new Date().getFullYear(),
    duration: '',
    genre: '',
    posterUrl: '',
    videoUrl: '',
    source_type: 'admin',
    is_scraped: false,
    status: 'Active', // Active or Draft
    isFeatured: false,
    isPublished: true,
    rating: 8.5
  };

  const [formData, setFormData] = useState(initialMovieState);

  // TMDB Search State
  const [tmdbResults, setTmdbResults] = useState([]);
  const [isSearchingTmdb, setIsSearchingTmdb] = useState(false);
  const [showTmdbDropdown, setShowTmdbDropdown] = useState(false);

  const searchTmdb = async (query) => {
    if (query.length < 3) {
      setTmdbResults([]);
      setShowTmdbDropdown(false);
      return;
    }

    setIsSearchingTmdb(true);
    try {
      const response = await api.get(`/admin/tmdb/search?query=${encodeURIComponent(query)}`);
      setTmdbResults(response.data || []);
      setShowTmdbDropdown(true);
    } catch (err) {
      console.error('TMDB Search failed:', err);
    } finally {
      setIsSearchingTmdb(false);
    }
  };

  const selectTmdbMovie = async (movie) => {
    setShowTmdbDropdown(false);
    setIsSearchingTmdb(true); // Re-use for loading state

    try {
      // Fetch full details
      const response = await api.get(`/admin/tmdb/movie/${movie.id}`);
      const details = response.data;

      setFormData({
        ...formData,
        title: details.title,
        description: details.overview,
        year: details.release_date ? new Date(details.release_date).getFullYear() : formData.year,
        duration: details.runtime ? `${details.runtime} min` : formData.duration,
        genre: details.genres?.map(g => g.name).join(', ') || '',
        posterUrl: details.poster_path ? `https://image.tmdb.org/t/p/w500${details.poster_path}` : formData.posterUrl,
        backdropUrl: details.backdrop_path ? `https://image.tmdb.org/t/p/original${details.backdrop_path}` : formData.backdropUrl,
        rating: details.vote_average || formData.rating
      });
    } catch (err) {
      console.error('Failed to fetch details:', err);
      // Fallback to basic info
      setFormData({
        ...formData,
        title: movie.title,
        description: movie.overview,
        year: movie.release_date ? new Date(movie.release_date).getFullYear() : formData.year,
        posterUrl: movie.poster_path ? `https://image.tmdb.org/t/p/w500${movie.poster_path}` : formData.posterUrl,
        rating: movie.vote_average || formData.rating
      });
    } finally {
      setIsSearchingTmdb(false);
    }
  };

  useEffect(() => {
    fetchMovies();
  }, []);

  const fetchMovies = async () => {
    setIsLoading(true);
    try {
      const data = await movieService.getAll();
      setMovies(data.movies || data || []);
    } catch (err) {
      console.error('Error fetching movies:', err);
    } finally {
      setIsLoading(false);
    }
  };

  // Standardized handle open modal
  const openModal = (movie = null) => {
    if (movie) {
      setEditingMovieId(movie._id);
      setFormData({
        title: movie.title || '',
        description: movie.description || '',
        year: movie.year || new Date().getFullYear(),
        duration: movie.duration || '',
        genre: movie.genre?.join(', ') || '',
        posterUrl: movie.posterUrl || '',
        videoUrl: movie.videoUrl || (movie.sources?.[0]?.url || ''),
        status: movie.isPublished ? 'Active' : 'Draft',
        isFeatured: movie.isFeatured || false,
        isPublished: movie.isPublished ?? true
      });
    } else {
      setEditingMovieId(null);
      setFormData(initialMovieState);
    }
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setEditingMovieId(null);
    setFormData(initialMovieState);
    setUploadProgress(0);
  };

  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    setIsUploading(true);
    setUploadProgress(0);
    const uploadFormData = new FormData();
    uploadFormData.append('file', file);

    try {
      const response = await api.post('/upload', uploadFormData, {
        headers: { 'Content-Type': 'multipart/form-data' },
        onUploadProgress: (progressEvent) => {
          const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total);
          setUploadProgress(progress);
        }
      });
      setFormData({ ...formData, videoUrl: response.data.url });
    } catch (err) {
      console.error('Upload failed:', err);
      alert('Upload failed: ' + (err.response?.data?.message || err.message));
    } finally {
      setIsUploading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.title || !formData.videoUrl) {
      alert('Title and Video Source are required');
      return;
    }

    setIsSubmitting(true);

    // Parse duration: handle both "120" and "120 min" formats
    const rawDuration = formData.duration?.toString() || "";
    const parsedDuration = parseInt(rawDuration.replace(/[^0-9]/g, "")) || 0;

    const submissionData = {
      ...formData,
      year: parseInt(formData.year) || new Date().getFullYear(),
      duration: parsedDuration,
      rating: parseFloat(formData.rating) || 0,
      isPublished: formData.status === 'Active',
      sourceType: formData.source_type || 'admin',
      isScraped: formData.is_scraped || false,
      directUrl: formData.videoUrl,
      genre: formData.genre.split(',').map(g => g.trim()).filter(g => g),
      sources: [
        {
          label: 'Primary',
          url: formData.videoUrl,
          type: formData.videoUrl.includes('.m3u8') ? 'hls' : 'direct',
          provider: 'local'
        }
      ]
    };

    try {
      if (editingMovieId) {
        await movieService.update(editingMovieId, submissionData);
      } else {
        await movieService.create(submissionData);
      }
      fetchMovies();
      closeModal();
    } catch (err) {
      console.error('Submission failed:', err);
      alert('Error: ' + (err.response?.data?.message || err.message));
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this movie?')) return;
    try {
      await movieService.delete(id);
      setMovies(movies.filter(m => m._id !== id));
    } catch (err) {
      console.error('Delete failed:', err);
    }
  };

  // Frontend Filtering & Sorting Logic
  const filteredMovies = useMemo(() => {
    let result = [...movies];

    // Search
    if (searchTerm) {
      result = result.filter(m => m.title?.toLowerCase().includes(searchTerm.toLowerCase()));
    }

    // Status Filter
    if (statusFilter !== 'all') {
      const isActive = statusFilter === 'active';
      result = result.filter(m => m.isPublished === isActive);
    }

    // Sort
    if (sortBy === 'title') {
      result.sort((a, b) => (a.title || '').localeCompare(b.title || ''));
    } else {
      // Default to newest (by createdAt or _id timestamp)
      result.sort((a, b) => (b._id || '').localeCompare(a._id || ''));
    }

    return result;
  }, [movies, searchTerm, statusFilter, sortBy]);

  return (
    <div className="space-y-6">
      {/* Header & Controls */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white dark:bg-[#1e1e1e] p-6 rounded-xl border border-[#dcdcde] dark:border-gray-800 shadow-sm">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1d2327] dark:text-white flex items-center gap-2">
            <Film className="text-blue-600" /> Movie Library
          </h1>
          <p className="text-sm text-gray-500 mt-1">Manage and curate your content catalogue</p>
        </div>
        <button onClick={() => openModal()} className="btn-primary py-3 px-6 rounded-full shadow-lg shadow-blue-500/20">
          <Plus size={20} /> Add New Movie
        </button>
      </div>

      {/* Advanced Filter Bar */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="relative md:col-span-2">
          <input
            type="text"
            placeholder="Instant title search..."
            className="input-field pl-11 w-full h-12 rounded-xl"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
          <Search size={20} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
        </div>

        <div className="relative">
          <select
            className="input-field w-full h-12 rounded-xl appearance-none pl-11 pr-10"
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="all">All Status</option>
            <option value="active">Active Only</option>
            <option value="draft">Draft Only</option>
          </select>
          <Filter size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
          <ChevronDown size={16} className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
        </div>

        <div className="relative">
          <select
            className="input-field w-full h-12 rounded-xl appearance-none pl-11 pr-10"
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value)}
          >
            <option value="newest">Newest First</option>
            <option value="title">By Title</option>
          </select>
          <ArrowUpDown size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" />
          <ChevronDown size={16} className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
        </div>
      </div>

      {/* Grid View */}
      {isLoading ? (
        <div className="p-20 flex justify-center"><Loader2 className="animate-spin text-blue-600" size={48} /></div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-6">
          {filteredMovies.map(movie => (
            <div key={movie._id} className="bg-white dark:bg-[#1e1e1e] border border-[#dcdcde] dark:border-gray-800 rounded-xl overflow-hidden group shadow-sm hover:shadow-xl transition-all duration-300">
              <div className="aspect-[2/3] relative overflow-hidden bg-gray-200 dark:bg-gray-800">
                <img
                  src={movie.posterUrl || 'https://via.placeholder.com/300x450?text=No+Poster'}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                  alt={movie.title}
                />
                <div className="absolute top-2 right-2">
                  <span className={`px-2 py-1 rounded text-[10px] font-bold uppercase tracking-wider ${
                    movie.isPublished ? 'bg-green-500 text-white shadow-lg' : 'bg-orange-500 text-white shadow-lg'
                  }`}>
                    {movie.isPublished ? 'Active' : 'Draft'}
                  </span>
                </div>
                {/* Quick Actions Overlay */}
                <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-3">
                  <button
                    onClick={() => {
                      const url = movie.videoUrl || (movie.sources?.[0]?.url);
                      if (url) window.open(url, '_blank');
                      else alert('No video source available for preview');
                    }}
                    className="p-3 bg-white text-blue-600 rounded-full hover:bg-blue-600 hover:text-white transition-colors"
                    title="Preview Video"
                  >
                    <Eye size={18} />
                  </button>
                  <button onClick={() => openModal(movie)} className="p-3 bg-white text-black rounded-full hover:bg-blue-600 hover:text-white transition-colors" title="Edit Movie">
                    <Edit3 size={18} />
                  </button>
                  <button onClick={() => handleDelete(movie._id)} className="p-3 bg-white text-red-600 rounded-full hover:bg-red-600 hover:text-white transition-colors" title="Delete Movie">
                    <Trash2 size={18} />
                  </button>
                </div>
              </div>
              <div className="p-4 space-y-2">
                <h3 className="font-bold text-sm truncate dark:text-white leading-tight">{movie.title}</h3>
                <div className="flex items-center justify-between text-[11px] font-medium text-gray-500">
                   <div className="flex items-center gap-1"><Calendar size={12}/> {movie.year}</div>
                   <div className="flex items-center gap-1 text-amber-500"><Star size={12} fill="currentColor"/> {movie.rating || 'N/A'}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {!isLoading && filteredMovies.length === 0 && (
        <div className="text-center py-20 bg-white dark:bg-[#1e1e1e] rounded-xl border border-dashed border-[#dcdcde] dark:border-gray-800">
          <Film className="mx-auto text-gray-300 mb-4" size={48} />
          <h2 className="text-lg font-bold text-gray-400">No movies found match your criteria</h2>
        </div>
      )}

      {/* Add / Edit Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black/80 z-[100] flex items-center justify-center p-4 backdrop-blur-md overflow-y-auto">
          <div className="bg-white dark:bg-[#1e1e1e] rounded-2xl shadow-2xl w-full max-w-4xl my-8">
            <div className="p-6 border-b border-[#dcdcde] dark:border-gray-800 flex items-center justify-between sticky top-0 bg-white dark:bg-[#1e1e1e] z-10 rounded-t-2xl">
              <h2 className="text-xl font-black dark:text-white flex items-center gap-2">
                {editingMovieId ? <Edit3 className="text-blue-500" /> : <Plus className="text-blue-500" />}
                {editingMovieId ? 'Edit Movie Details' : 'Create New Movie Entry'}
              </h2>
              <button onClick={closeModal} className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full transition-colors">
                <X size={24} />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="p-8">
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-10">
                {/* Basic Info Column */}
                <div className="space-y-6">
                  <div className="border-l-4 border-blue-500 pl-4 mb-8">
                     <h3 className="text-xs font-bold text-blue-500 uppercase tracking-widest">Basic Information</h3>
                  </div>

                  <div className="space-y-4">
                    <div className="relative">
                      <label className="block text-xs font-bold mb-1.5 uppercase text-gray-500">Movie Title *</label>
                      <div className="relative">
                        <input
                          type="text"
                          required
                          placeholder="Type title to auto-fetch..."
                          className="input-field w-full h-12 rounded-lg pr-10"
                          value={formData.title}
                          onChange={e => {
                            setFormData({...formData, title: e.target.value});
                            searchTmdb(e.target.value);
                          }}
                        />
                        {isSearchingTmdb && (
                          <div className="absolute right-3 top-1/2 -translate-y-1/2">
                            <Loader2 className="animate-spin text-blue-500" size={18} />
                          </div>
                        )}
                      </div>

                      {/* TMDB Search Dropdown */}
                      {showTmdbDropdown && tmdbResults.length > 0 && (
                        <div className="absolute z-[110] left-0 right-0 mt-1 bg-white dark:bg-[#2c3338] border border-[#dcdcde] dark:border-gray-700 rounded-xl shadow-2xl max-h-64 overflow-y-auto">
                          {tmdbResults.map(m => (
                            <button
                              key={m.id}
                              type="button"
                              onClick={() => selectTmdbMovie(m)}
                              className="w-full flex items-center gap-3 p-3 hover:bg-blue-50 dark:hover:bg-blue-900/20 text-left transition-colors border-b border-gray-50 dark:border-gray-800 last:border-none"
                            >
                              <img
                                src={m.poster_path ? `https://image.tmdb.org/t/p/w92${m.poster_path}` : 'https://via.placeholder.com/45x68'}
                                className="w-10 h-14 rounded object-cover shadow-sm"
                                alt=""
                              />
                              <div>
                                <p className="text-sm font-bold dark:text-white line-clamp-1">{m.title}</p>
                                <p className="text-[10px] text-gray-500 font-medium">{m.release_date ? m.release_date.split('-')[0] : 'N/A'}</p>
                              </div>
                            </button>
                          ))}
                        </div>
                      )}
                      {showTmdbDropdown && tmdbResults.length === 0 && !isSearchingTmdb && (
                        <div className="absolute z-[110] left-0 right-0 mt-1 bg-white dark:bg-[#2c3338] p-4 text-center border border-[#dcdcde] dark:border-gray-700 rounded-xl shadow-2xl">
                           <p className="text-xs font-bold text-gray-400">No matching movies found on TMDb</p>
                        </div>
                      )}
                    </div>
                    <div>
                      <label className="block text-xs font-bold mb-1.5 uppercase text-gray-500">Short Description</label>
                      <textarea
                        placeholder="Brief summary for list views"
                        className="input-field w-full h-24 rounded-lg resize-none"
                        value={formData.description}
                        onChange={e => setFormData({...formData, description: e.target.value})}
                      ></textarea>
                    </div>
                    <div className="grid grid-cols-3 gap-4">
                       <div>
                        <label className="block text-xs font-bold mb-1.5 uppercase text-gray-500">Release Year</label>
                        <input type="number" className="input-field w-full h-12 rounded-lg" value={formData.year} onChange={e => setFormData({...formData, year: e.target.value})} />
                       </div>
                       <div>
                        <label className="block text-xs font-bold mb-1.5 uppercase text-gray-500">Duration (min)</label>
                        <input type="text" placeholder="120 min" className="input-field w-full h-12 rounded-lg" value={formData.duration} onChange={e => setFormData({...formData, duration: e.target.value})} />
                       </div>
                       <div>
                        <label className="block text-xs font-bold mb-1.5 uppercase text-gray-500">Rating</label>
                        <input type="number" step="0.1" className="input-field w-full h-12 rounded-lg" value={formData.rating} onChange={e => setFormData({...formData, rating: e.target.value})} />
                       </div>
                    </div>
                    <div>
                      <label className="block text-xs font-bold mb-1.5 uppercase text-gray-500">Genres (Comma separated)</label>
                      <input type="text" placeholder="Action, Drama, Sci-Fi" className="input-field w-full h-12 rounded-lg" value={formData.genre} onChange={e => setFormData({...formData, genre: e.target.value})} />
                    </div>
                  </div>
                </div>

                {/* Media & Settings Column */}
                <div className="space-y-10">
                  {/* Media Section */}
                  <div className="space-y-6">
                    <div className="border-l-4 border-purple-500 pl-4 mb-4">
                      <h3 className="text-xs font-bold text-purple-500 uppercase tracking-widest">Media Assets</h3>
                    </div>
                    <div className="space-y-4">
                       <div>
                          <label className="block text-xs font-bold mb-1.5 uppercase text-gray-500">Poster Image URL</label>
                          <input
                            type="text"
                            placeholder="https://..."
                            className="input-field w-full h-12 rounded-lg"
                            value={formData.posterUrl}
                            onChange={e => setFormData({...formData, posterUrl: e.target.value})}
                          />
                       </div>

                       <div className="bg-gray-50 dark:bg-gray-800/50 p-6 rounded-2xl border-2 border-dashed border-gray-300 dark:border-gray-700">
                          <label className="block text-xs font-bold mb-4 uppercase text-gray-500">Video Source *</label>
                          <div className="flex flex-col gap-4">
                             <div className="relative h-12">
                                <input
                                  type="text"
                                  placeholder="Paste direct .mp4 or .m3u8 URL"
                                  className="input-field w-full h-full rounded-lg pr-12"
                                  value={formData.videoUrl}
                                  onChange={e => setFormData({...formData, videoUrl: e.target.value})}
                                />
                                <LinkIcon size={18} className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400" />
                             </div>

                             <div className="flex items-center gap-4">
                                <div className="h-px bg-gray-200 dark:bg-gray-700 flex-1"></div>
                                <span className="text-[10px] font-bold text-gray-400">OR UPLOAD FILE</span>
                                <div className="h-px bg-gray-200 dark:bg-gray-700 flex-1"></div>
                             </div>

                             <div className="relative">
                                <input type="file" accept="video/mp4" onChange={handleFileUpload} className="absolute inset-0 opacity-0 cursor-pointer z-20" />
                                <div className={`h-14 rounded-lg flex items-center justify-center gap-3 border transition-all ${isUploading ? 'bg-blue-50 border-blue-200 dark:bg-blue-900/10' : 'bg-white dark:bg-gray-900 hover:border-blue-400 border-gray-300 dark:border-gray-700'}`}>
                                   {isUploading ? (
                                      <div className="flex items-center gap-3 w-full px-4">
                                         <Loader2 className="animate-spin text-blue-600" size={20} />
                                         <div className="flex-1 h-2 bg-gray-200 rounded-full overflow-hidden">
                                            <div className="h-full bg-blue-600 transition-all duration-300" style={{ width: `${uploadProgress}%` }}></div>
                                         </div>
                                         <span className="text-xs font-bold text-blue-600">{uploadProgress}%</span>
                                      </div>
                                   ) : (
                                      <>
                                         <Upload size={20} className="text-gray-400" />
                                         <span className="text-sm font-bold text-gray-600 dark:text-gray-300">Choose MP4 Video File</span>
                                      </>
                                   )}
                                </div>
                             </div>
                          </div>
                       </div>
                    </div>
                  </div>

                  {/* Settings Section */}
                  <div className="space-y-6">
                    <div className="border-l-4 border-orange-500 pl-4 mb-4">
                      <h3 className="text-xs font-bold text-orange-500 uppercase tracking-widest">Configuration</h3>
                    </div>
                    <div className="grid grid-cols-2 gap-8 bg-gray-50 dark:bg-gray-800/30 p-6 rounded-2xl">
                        <div className="space-y-3">
                           <label className="block text-[10px] font-bold uppercase text-gray-400">Availability</label>
                           <div className="flex gap-2">
                              {['Active', 'Draft'].map(s => (
                                <button
                                  key={s}
                                  type="button"
                                  onClick={() => setFormData({...formData, status: s})}
                                  className={`flex-1 py-2 text-xs font-bold rounded-lg border transition-all ${formData.status === s ? 'bg-blue-600 border-blue-600 text-white' : 'bg-white dark:bg-gray-900 border-gray-300 dark:border-gray-700 text-gray-500'}`}
                                >
                                  {s}
                                </button>
                              ))}
                           </div>
                        </div>
                        <div className="space-y-3">
                           <label className="block text-[10px] font-bold uppercase text-gray-400">Promote</label>
                           <button
                             type="button"
                             onClick={() => setFormData({...formData, isFeatured: !formData.isFeatured})}
                             className={`w-full py-2 text-xs font-bold rounded-lg border transition-all flex items-center justify-center gap-2 ${formData.isFeatured ? 'bg-amber-500 border-amber-500 text-white' : 'bg-white dark:bg-gray-900 border-gray-300 dark:border-gray-700 text-gray-500'}`}
                           >
                             {formData.isFeatured ? <Check size={14}/> : null} Featured Content
                           </button>
                        </div>
                    </div>
                  </div>
                </div>
              </div>

              <div className="mt-12 flex justify-end gap-4 border-t border-[#dcdcde] dark:border-gray-800 pt-8">
                <button type="button" onClick={closeModal} className="px-8 py-3 font-bold text-gray-500 hover:text-gray-700">Cancel</button>
                <button
                  type="submit"
                  disabled={isSubmitting || isUploading}
                  className="btn-primary px-12 py-3 rounded-xl shadow-xl shadow-blue-500/20"
                >
                  {isSubmitting ? <Loader2 size={20} className="animate-spin" /> : editingMovieId ? 'Update Movie Entry' : 'Publish Movie'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Movies;
