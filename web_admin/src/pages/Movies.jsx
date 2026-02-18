import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import { Film, Tv, Plus, Trash2, Bell, Search, Edit2, Play, ChevronRight, X } from 'lucide-react';

const Movies = () => {
  const [movies, setMovies] = useState([]);
  const [r2Files, setR2Files] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [contentType, setContentType] = useState('movie'); // movie, tv
  const [videoSource, setVideoSource] = useState('upload'); // upload, url, storage
  const [uploadProgress, setUploadProgress] = useState({ poster: 0, video: 0 });
  const [isUploading, setIsUploading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  const [formData, setFormData] = useState({
    title: '',
    description: '',
    posterUrl: '',
    backdropUrl: '',
    videoUrl: '',
    year: '',
    duration: '',
    genre: '',
    contentRating: '',
    isTvShow: false,
    seasons: []
  });

  const fetchMovies = async () => {
    setLoading(true);
    try {
      const [movieRes, r2Res] = await Promise.all([
        api.get('/admin/movies'),
        api.get('/upload')
      ]);
      setMovies(movieRes.data);
      setR2Files(r2Res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMovies();
  }, []);

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this content?')) return;
    try {
      await api.delete(`/admin/movies/${id}`);
      fetchMovies();
    } catch (err) {
      alert('Delete failed');
    }
  };

  const handleFileUpload = async (file, type) => {
    const data = new FormData();
    data.append('file', file);

    try {
      setIsUploading(true);
      const res = await api.post('/upload', data, {
        onUploadProgress: (progressEvent) => {
          const progress = Math.round((progressEvent.loaded * 100) / progressEvent.total);
          setUploadProgress(prev => ({ ...prev, [type]: progress }));
        }
      });

      setFormData(prev => ({
        ...prev,
        [type === 'poster' ? 'posterUrl' : 'videoUrl']: res.data.url
      }));
    } catch (err) {
      alert(`${type} upload failed: ${err.response?.data?.message || err.message}`);
    } finally {
      setIsUploading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.posterUrl || (contentType === 'movie' && !formData.videoUrl)) {
      alert('Please fill in required fields and upload media');
      return;
    }

    const data = {
      ...formData,
      isTvShow: contentType === 'tv',
      year: parseInt(formData.year) || new Date().getFullYear(),
      genre: Array.isArray(formData.genre) ? formData.genre : formData.genre.split(',').map(g => g.trim()),
      isTrending: true
    };

    try {
      if (editingId) {
        await api.put(`/admin/movies/${editingId}`, data);
      } else {
        await api.post('/admin/movies', data);
      }
      setIsModalOpen(false);
      resetForm();
      fetchMovies();
    } catch (err) {
      alert('Operation failed');
    }
  };

  const handleEdit = (movie) => {
    setEditingId(movie._id);
    setFormData({
      ...movie,
      genre: movie.genre.join(', ')
    });
    setContentType(movie.isTvShow ? 'tv' : 'movie');
    setVideoSource('url');
    setIsModalOpen(true);
  };

  const resetForm = () => {
    setEditingId(null);
    setFormData({
      title: '', description: '', posterUrl: '',
      backdropUrl: '', videoUrl: '', year: '',
      duration: '', genre: '', contentRating: '',
      isTvShow: false, seasons: []
    });
    setUploadProgress({ poster: 0, video: 0 });
  };

  const filteredMovies = movies.filter(m =>
    m.title.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h1 className="text-4xl font-black text-white tracking-tight">Content Library</h1>
          <p className="text-gray-400 text-lg mt-1">Manage your movies and TV shows.</p>
        </div>
        <div className="flex items-center gap-4">
          <div className="relative group">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 group-focus-within:text-purple-500 transition-colors" size={20} />
            <input
              type="text"
              placeholder="Search content..."
              className="bg-[#1C1C1C] border border-white/5 rounded-2xl pl-12 pr-6 py-3 text-sm focus:outline-none focus:border-purple-500 transition-all w-64"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          <button
            onClick={() => setIsModalOpen(true)}
            className="bg-purple-600 hover:bg-purple-700 text-white px-8 py-3 rounded-2xl font-black text-sm transition-all shadow-xl shadow-purple-600/20 active:scale-95 flex items-center gap-2"
          >
            <Plus size={20} />
            ADD CONTENT
          </button>
        </div>
      </div>

      {loading ? (
        <div className="flex flex-col items-center justify-center py-32 space-y-4">
          <div className="w-12 h-12 border-4 border-purple-600 border-t-transparent rounded-full animate-spin"></div>
          <p className="text-gray-500 font-bold uppercase tracking-widest text-xs">Synchronizing Library...</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4 gap-8">
          {filteredMovies.map((movie) => (
            <div key={movie._id} className="bg-[#1C1C1C] rounded-3xl overflow-hidden border border-white/5 group hover:border-purple-500/30 transition-all shadow-2xl relative">
              <div className="h-64 overflow-hidden relative">
                <img
                  src={movie.posterUrl}
                  alt={movie.title}
                  className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
                  onError={(e) => { e.target.src = 'https://via.placeholder.com/300x450?text=No+Image' }}
                />
                <div className="absolute inset-0 bg-gradient-to-t from-[#1C1C1C] via-transparent to-transparent opacity-60"></div>

                <div className="absolute top-4 left-4">
                  <span className={`px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest ${movie.isTvShow ? 'bg-blue-600' : 'bg-purple-600'} text-white shadow-lg`}>
                    {movie.isTvShow ? 'TV Series' : 'Movie'}
                  </span>
                </div>

                <div className="absolute top-4 right-4 flex flex-col gap-2 transform translate-x-12 group-hover:translate-x-0 transition-transform duration-300">
                   <button
                    onClick={() => {
                      if (window.confirm(`Broadcast notification for "${movie.title}"?`)) {
                        api.post('/admin/notify', {
                          title: 'Available Now! 🎬',
                          body: `"${movie.title}" is ready to stream. Watch it now!`,
                          data: { movieId: movie._id }
                        }).then(() => alert('Notification sent!')).catch(() => alert('Failed to send'));
                      }
                    }}
                    className="p-3 bg-white/10 backdrop-blur-md rounded-2xl hover:bg-purple-600 text-white transition-colors"
                   >
                    <Bell size={18} />
                   </button>
                   <button
                    onClick={() => handleDelete(movie._id)}
                    className="p-3 bg-white/10 backdrop-blur-md rounded-2xl hover:bg-red-600 text-white transition-colors"
                   >
                    <Trash2 size={18} />
                   </button>
                </div>
              </div>

              <div className="p-6">
                <div className="flex items-center justify-between mb-2">
                  <h3 className="text-xl font-bold text-white truncate pr-4">{movie.title}</h3>
                  <span className="text-xs text-gray-500 font-black">{movie.year}</span>
                </div>
                <p className="text-gray-500 text-sm line-clamp-2 h-10 leading-relaxed font-medium">{movie.description}</p>

                <div className="mt-6 flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="flex items-center gap-1 text-gray-400">
                      <Play size={14} className="text-purple-500" />
                      <span className="text-[10px] font-black uppercase tracking-tighter">{movie.isTvShow ? 'Manage' : 'Watch'}</span>
                    </div>
                  </div>
                  <button
                    onClick={() => handleEdit(movie)}
                    className="text-gray-400 hover:text-white transition-colors"
                  >
                    <Edit2 size={18} />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Upload Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black/90 backdrop-blur-xl flex items-center justify-center p-4 z-50 animate-in fade-in duration-300">
          <div className="bg-[#1C1C1C] max-w-2xl w-full rounded-[40px] border border-white/10 shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
            <div className="p-8 border-b border-white/5 flex justify-between items-center">
              <div>
                <h2 className="text-2xl font-black uppercase tracking-tighter">{editingId ? 'Edit Content' : 'Add New Content'}</h2>
                <p className="text-gray-500 text-sm font-medium mt-1">
                  {editingId ? `Modifying "${formData.title}"` : 'Fill in the details to expand your library.'}
                </p>
              </div>
              <button onClick={() => setIsModalOpen(false)} className="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center text-gray-500 hover:text-white hover:bg-white/10 transition-all">
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="p-8 space-y-8 overflow-y-auto custom-scrollbar flex-1">
              {/* Type Switcher */}
              <div className="flex p-1.5 bg-black/40 rounded-3xl border border-white/5">
                <button
                  type="button"
                  onClick={() => setContentType('movie')}
                  className={`flex-1 flex items-center justify-center gap-2 py-4 rounded-[22px] text-xs font-black transition-all ${contentType === 'movie' ? 'bg-purple-600 text-white shadow-xl shadow-purple-600/20' : 'text-gray-500 hover:text-gray-300'}`}
                >
                  <Film size={18} />
                  MOVIE
                </button>
                <button
                  type="button"
                  onClick={() => setContentType('tv')}
                  className={`flex-1 flex items-center justify-center gap-2 py-4 rounded-[22px] text-xs font-black transition-all ${contentType === 'tv' ? 'bg-blue-600 text-white shadow-xl shadow-blue-600/20' : 'text-gray-500 hover:text-gray-300'}`}
                >
                  <Tv size={18} />
                  TV SERIES
                </button>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <label className="text-[10px] font-black text-gray-500 uppercase tracking-widest ml-1">Content Title</label>
                  <input
                    required
                    className="w-full bg-black/40 border border-white/5 rounded-2xl px-6 py-4 text-sm text-white focus:outline-none focus:border-purple-500 transition-all"
                    placeholder="Enter title..."
                    value={formData.title}
                    onChange={(e) => setFormData({...formData, title: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-[10px] font-black text-gray-500 uppercase tracking-widest ml-1">Year of Release</label>
                  <input
                    required
                    type="number"
                    className="w-full bg-black/40 border border-white/5 rounded-2xl px-6 py-4 text-sm text-white focus:outline-none focus:border-purple-500 transition-all"
                    placeholder="e.g. 2024"
                    value={formData.year}
                    onChange={(e) => setFormData({...formData, year: e.target.value})}
                  />
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-[10px] font-black text-gray-500 uppercase tracking-widest ml-1">Synopsis / Description</label>
                <textarea
                  required
                  rows="3"
                  className="w-full bg-black/40 border border-white/5 rounded-2xl px-6 py-4 text-sm text-white focus:outline-none focus:border-purple-500 transition-all resize-none"
                  placeholder="Enter content description..."
                  value={formData.description}
                  onChange={(e) => setFormData({...formData, description: e.target.value})}
                />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <label className="text-[10px] font-black text-gray-500 uppercase tracking-widest ml-1">Genres (Comma Sep)</label>
                  <input
                    className="w-full bg-black/40 border border-white/5 rounded-2xl px-6 py-4 text-sm text-white focus:outline-none focus:border-purple-500 transition-all"
                    placeholder="Action, Thriller, Sci-Fi"
                    value={formData.genre}
                    onChange={(e) => setFormData({...formData, genre: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-[10px] font-black text-gray-500 uppercase tracking-widest ml-1">Rating</label>
                  <input
                    className="w-full bg-black/40 border border-white/5 rounded-2xl px-6 py-4 text-sm text-white focus:outline-none focus:border-purple-500 transition-all"
                    placeholder="e.g. 13+, R, PG"
                    value={formData.contentRating}
                    onChange={(e) => setFormData({...formData, contentRating: e.target.value})}
                  />
                </div>
              </div>

              {contentType === 'movie' && (
                <div className="p-8 bg-black/40 rounded-[32px] border border-white/5 space-y-6">
                  <div className="flex items-center justify-between">
                    <h3 className="text-xs font-black uppercase tracking-widest text-purple-500">Video Source</h3>
                    <div className="flex gap-2">
                       {['upload', 'url', 'storage'].map(type => (
                         <button
                            key={type}
                            type="button"
                            onClick={() => setVideoSource(type)}
                            className={`px-4 py-1.5 text-[9px] font-black rounded-full transition-all border ${
                              videoSource === type ? 'bg-purple-600 border-purple-600 text-white' : 'border-white/10 text-gray-500'
                            }`}
                         >
                           {type.toUpperCase()}
                         </button>
                       ))}
                    </div>
                  </div>

                  {videoSource === 'upload' && (
                    <div className="relative">
                      <input
                        type="file"
                        accept="video/*"
                        className="w-full bg-black/20 border-2 border-dashed border-white/10 rounded-2xl p-8 text-sm text-gray-500 text-center cursor-pointer hover:border-purple-500/50 transition-all"
                        onChange={(e) => handleFileUpload(e.target.files[0], 'video')}
                      />
                      {uploadProgress.video > 0 && (
                        <div className="absolute bottom-0 left-0 h-1 bg-purple-600 transition-all rounded-full" style={{ width: `${uploadProgress.video}%` }}></div>
                      )}
                    </div>
                  )}

                  {videoSource === 'url' && (
                    <input
                      placeholder="Paste HLS (.m3u8) or MP4 link..."
                      className="w-full bg-black/20 border border-white/10 rounded-2xl px-6 py-4 text-sm text-white focus:border-purple-500 outline-none"
                      value={formData.videoUrl}
                      onChange={(e) => setFormData({...formData, videoUrl: e.target.value})}
                    />
                  )}

                  {videoSource === 'storage' && (
                    <select
                      className="w-full bg-black/20 border border-white/10 rounded-2xl px-6 py-4 text-sm text-white outline-none focus:border-purple-500 transition-all appearance-none"
                      value={formData.videoUrl}
                      onChange={(e) => setFormData({...formData, videoUrl: e.target.value})}
                    >
                      <option value="">Choose from Cloudflare R2...</option>
                      {r2Files.filter(f => f.key.toLowerCase().endsWith('.mp4')).map(file => (
                        <option key={file.key} value={file.url}>{file.key}</option>
                      ))}
                    </select>
                  )}
                </div>
              )}

              <div className="p-8 bg-black/40 rounded-[32px] border border-white/5 space-y-6">
                <h3 className="text-xs font-black uppercase tracking-widest text-purple-500">Visual Assets</h3>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-4">
                    <label className="text-[10px] font-bold text-gray-500 uppercase ml-1 tracking-tighter italic">Poster Artwork (2:3)</label>
                    <div className="flex gap-4">
                      <div className="w-24 h-36 bg-black/20 rounded-xl flex items-center justify-center border border-white/5 overflow-hidden">
                        {formData.posterUrl ? <img src={formData.posterUrl} className="w-full h-full object-cover" /> : <Plus size={24} className="text-gray-700" />}
                      </div>
                      <div className="flex-1 space-y-2">
                        <input
                          type="file"
                          accept="image/*"
                          className="hidden"
                          id="poster-upload"
                          onChange={(e) => handleFileUpload(e.target.files[0], 'poster')}
                        />
                        <label htmlFor="poster-upload" className="block w-full text-center bg-white/5 hover:bg-white/10 py-3 rounded-xl text-[10px] font-black uppercase cursor-pointer transition-all">Upload</label>
                        <input
                          placeholder="Or paste image URL..."
                          className="w-full bg-black/20 border border-white/10 rounded-xl px-4 py-2 text-[10px] text-white focus:border-purple-500 outline-none"
                          value={formData.posterUrl}
                          onChange={(e) => setFormData({...formData, posterUrl: e.target.value})}
                        />
                      </div>
                    </div>
                  </div>

                  <div className="space-y-4">
                    <label className="text-[10px] font-bold text-gray-500 uppercase ml-1 tracking-tighter italic">Backdrop Image (16:9)</label>
                    <div className="space-y-2">
                      <div className="w-full h-24 bg-black/20 rounded-xl flex items-center justify-center border border-white/5 overflow-hidden">
                        {formData.backdropUrl ? <img src={formData.backdropUrl} className="w-full h-full object-cover" /> : <Plus size={24} className="text-gray-700" />}
                      </div>
                      <input
                        placeholder="Paste backdrop URL..."
                        className="w-full bg-black/20 border border-white/10 rounded-xl px-4 py-2 text-[10px] text-white focus:border-purple-500 outline-none"
                        value={formData.backdropUrl}
                        onChange={(e) => setFormData({...formData, backdropUrl: e.target.value})}
                      />
                    </div>
                  </div>
                </div>
              </div>

              <div className="pt-8">
                <button
                  type="submit"
                  disabled={isUploading}
                  className="w-full bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-700 hover:to-indigo-700 text-white py-5 rounded-3xl font-black text-sm uppercase tracking-widest transition-all shadow-2xl shadow-purple-600/30 active:scale-[0.98] disabled:opacity-50"
                >
                  {isUploading ? 'SYNCHRONIZING ASSETS...' : 'CONFIRM & ADD TO LIBRARY'}
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
