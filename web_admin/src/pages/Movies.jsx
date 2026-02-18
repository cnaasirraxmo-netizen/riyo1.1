import React, { useState, useEffect } from 'react';
import api from '../utils/api';

const Movies = () => {
  const [movies, setMovies] = useState([]);
  const [r2Files, setR2Files] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [videoSource, setVideoSource] = useState('upload'); // upload, url, storage
  const [uploadProgress, setUploadProgress] = useState({ poster: 0, video: 0 });
  const [isUploading, setIsUploading] = useState(false);
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
    if (!window.confirm('Are you sure you want to delete this item?')) return;
    try {
      await api.delete(`/admin/movies/${id}`);
      fetchMovies();
    } catch (err) {
      alert('Delete failed');
    }
  };

  const handleFileUpload = async (file, type, extra) => {
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

      if (type === 'episodeVideo') {
        const { seasonIndex, episodeIndex } = extra;
        const newSeasons = [...formData.seasons];
        newSeasons[seasonIndex].episodes[episodeIndex].videoUrl = res.data.url;
        setFormData({ ...formData, seasons: newSeasons });
      } else {
        setFormData(prev => ({
          ...prev,
          [type === 'poster' ? 'posterUrl' : 'videoUrl']: res.data.url
        }));
      }
    } catch (err) {
      alert(`${type} upload failed: ${err.response?.data?.message || err.message}`);
    } finally {
      setIsUploading(false);
    }
  };

  const handleUploadFromUrl = async () => {
    if (!formData.posterUrl) return;
    try {
      setIsUploading(true);
      const res = await api.post('/upload/by-url', { url: formData.posterUrl });
      setFormData(prev => ({ ...prev, posterUrl: res.data.url }));
      alert('Poster fetched and saved to R2');
    } catch (err) {
      alert('URL fetch failed');
    } finally {
      setIsUploading(false);
    }
  };

  const addSeason = () => {
    setFormData(prev => ({
      ...prev,
      seasons: [...prev.seasons, {
        number: prev.seasons.length + 1,
        title: `Season ${prev.seasons.length + 1}`,
        episodes: []
      }]
    }));
  };

  const removeSeason = (index) => {
    const newSeasons = [...formData.seasons];
    newSeasons.splice(index, 1);
    setFormData({ ...formData, seasons: newSeasons });
  };

  const addEpisode = (seasonIndex) => {
    const newSeasons = [...formData.seasons];
    newSeasons[seasonIndex].episodes.push({
      number: newSeasons[seasonIndex].episodes.length + 1,
      title: '',
      duration: '',
      videoUrl: ''
    });
    setFormData({ ...formData, seasons: newSeasons });
  };

  const removeEpisode = (seasonIndex, episodeIndex) => {
    const newSeasons = [...formData.seasons];
    newSeasons[seasonIndex].episodes.splice(episodeIndex, 1);
    setFormData({ ...formData, seasons: newSeasons });
  };

  const updateEpisode = (seasonIndex, episodeIndex, field, value) => {
    const newSeasons = [...formData.seasons];
    newSeasons[seasonIndex].episodes[episodeIndex][field] = value;
    setFormData({ ...formData, seasons: newSeasons });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.posterUrl) {
      alert('Please upload poster first');
      return;
    }

    if (!formData.isTvShow && !formData.videoUrl) {
      alert('Please upload video for the movie');
      return;
    }

    const data = {
      ...formData,
      year: parseInt(formData.year) || new Date().getFullYear(),
      genre: typeof formData.genre === 'string' ? formData.genre.split(',').map(g => g.trim()) : formData.genre,
      isTrending: true
    };

    try {
      await api.post('/admin/movies', data);
      setIsModalOpen(false);
      setFormData({
        title: '', description: '', posterUrl: '',
        backdropUrl: '', videoUrl: '', year: '',
        duration: '', genre: '', contentRating: '',
        isTvShow: false, seasons: []
      });
      setUploadProgress({ poster: 0, video: 0 });
      fetchMovies();
    } catch (err) {
      alert('Content creation failed');
    }
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold">Content Library</h1>
          <p className="text-gray-400">Manage your movies and TV shows.</p>
        </div>
        <button
          onClick={() => setIsModalOpen(true)}
          className="bg-purple-600 hover:bg-purple-700 px-6 py-2 rounded-lg font-bold transition-colors"
        >
          Add New Content
        </button>
      </div>

      {loading ? (
        <div className="text-center py-20 text-gray-500 italic">Loading content...</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {movies.map((movie) => (
            <div key={movie._id} className="bg-[#1C1C1C] rounded-xl overflow-hidden border border-white/5 group">
              <div className="h-48 overflow-hidden relative">
                <img
                  src={movie.posterUrl}
                  alt={movie.title}
                  className="w-full h-full object-cover transition-transform group-hover:scale-105"
                  onError={(e) => { e.target.src = 'https://via.placeholder.com/300x450?text=No+Image' }}
                />
                <div className="absolute top-2 left-2 flex space-x-2">
                   <div className="px-2 py-1 bg-black/60 rounded text-[10px] font-bold uppercase">
                     {movie.isTvShow ? 'TV Series' : 'Movie'}
                   </div>
                   <button
                    onClick={() => handleDelete(movie._id)}
                    className="p-2 bg-red-600 rounded-full hover:bg-red-700 shadow-lg"
                   >
                    🗑️
                   </button>
                </div>
              </div>
              <div className="p-5">
                <h3 className="text-lg font-bold truncate">{movie.title}</h3>
                <p className="text-gray-500 text-sm mt-1 line-clamp-2">{movie.description}</p>
                <div className="mt-4 pt-4 border-t border-white/5 flex items-center justify-between text-xs text-gray-400 italic">
                  <span>{movie.year} • {movie.genre?.join(', ')}</span>
                  {movie.isTvShow && <span>{movie.seasons?.length} Seasons</span>}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Upload Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4 z-50">
          <div className="bg-[#1C1C1C] max-w-2xl w-full rounded-2xl border border-white/10 shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
            <div className="p-6 border-b border-white/5 flex justify-between items-center">
              <h2 className="text-xl font-bold">Upload New Content</h2>
              <button onClick={() => setIsModalOpen(false)} className="text-gray-500 hover:text-white">✕</button>
            </div>
            <form onSubmit={handleSubmit} className="p-6 space-y-6 overflow-y-auto custom-scrollbar">
              <div className="grid grid-cols-2 gap-4">
                <div className="col-span-2">
                  <label className="block text-sm font-medium text-gray-400 mb-1">Title</label>
                  <input
                    required
                    className="w-full bg-[#262626] border border-white/10 rounded px-4 py-2 focus:outline-none focus:border-purple-500"
                    value={formData.title}
                    onChange={(e) => setFormData({...formData, title: e.target.value})}
                  />
                </div>
                <div className="col-span-2">
                  <label className="block text-sm font-medium text-gray-400 mb-1">Description</label>
                  <textarea
                    required
                    rows="3"
                    className="w-full bg-[#262626] border border-white/10 rounded px-4 py-2 focus:outline-none focus:border-purple-500"
                    value={formData.description}
                    onChange={(e) => setFormData({...formData, description: e.target.value})}
                  />
                </div>
              </div>

              <div className="flex items-center space-x-4 bg-purple-600/10 p-4 rounded-xl border border-purple-500/20">
                <label className="flex items-center cursor-pointer">
                  <div className="relative">
                    <input
                      type="checkbox"
                      className="sr-only"
                      checked={formData.isTvShow}
                      onChange={(e) => setFormData({...formData, isTvShow: e.target.checked})}
                    />
                    <div className={`block w-10 h-6 rounded-full transition-colors ${formData.isTvShow ? 'bg-purple-600' : 'bg-gray-600'}`}></div>
                    <div className={`absolute left-1 top-1 bg-white w-4 h-4 rounded-full transition-transform ${formData.isTvShow ? 'translate-x-4' : ''}`}></div>
                  </div>
                  <div className="ml-3 text-white font-bold">This is a TV Series</div>
                </label>
              </div>

              {!formData.isTvShow && (
                <div className="bg-[#262626] p-4 rounded-xl border border-white/5">
                  <label className="block text-xs font-black text-gray-500 mb-3 uppercase tracking-widest">Movie Video Source</label>
                  <div className="flex space-x-2 mb-4">
                    {['upload', 'url', 'storage'].map(type => (
                      <button
                          key={type}
                          type="button"
                          onClick={() => setVideoSource(type)}
                          className={`flex-1 py-2 text-xs font-bold rounded-lg transition-all ${
                            videoSource === type ? 'bg-purple-600 text-white shadow-lg' : 'bg-white/5 text-gray-400 hover:bg-white/10'
                          }`}
                      >
                        {type.toUpperCase()}
                      </button>
                    ))}
                  </div>

                  {videoSource === 'upload' && (
                    <div>
                      <input
                        type="file"
                        accept="video/*"
                        className="w-full bg-[#141414] border border-white/10 rounded px-4 py-2 text-sm"
                        onChange={(e) => handleFileUpload(e.target.files[0], 'video')}
                      />
                      {uploadProgress.video > 0 && (
                        <div className="w-full bg-gray-700 h-1 mt-2 rounded-full overflow-hidden">
                          <div className="bg-blue-500 h-full" style={{ width: `${uploadProgress.video}%` }}></div>
                        </div>
                      )}
                    </div>
                  )}

                  {videoSource === 'url' && (
                    <input
                      placeholder="Paste direct MP4/HLS link"
                      className="w-full bg-[#141414] border border-white/10 rounded px-4 py-2 text-sm focus:border-purple-500"
                      value={formData.videoUrl}
                      onChange={(e) => setFormData({...formData, videoUrl: e.target.value})}
                    />
                  )}

                  {videoSource === 'storage' && (
                    <select
                      className="w-full bg-[#141414] border border-white/10 rounded px-4 py-2 text-sm outline-none focus:border-purple-500"
                      value={formData.videoUrl}
                      onChange={(e) => setFormData({...formData, videoUrl: e.target.value})}
                    >
                      <option value="">Select a file from R2 Storage</option>
                      {r2Files.filter(f => f.key.toLowerCase().endsWith('.mp4')).map(file => (
                        <option key={file.key} value={file.url}>{file.key} ({(file.size/1024/1024).toFixed(2)}MB)</option>
                      ))}
                    </select>
                  )}
                </div>
              )}

              {formData.isTvShow && (
                <div className="space-y-4">
                  <div className="flex justify-between items-center">
                    <h3 className="font-bold text-lg">Seasons & Episodes</h3>
                    <button
                      type="button"
                      onClick={addSeason}
                      className="bg-white/5 hover:bg-white/10 px-4 py-1 rounded text-xs font-bold transition-colors"
                    >
                      + Add Season
                    </button>
                  </div>

                  {formData.seasons.map((season, sIdx) => (
                    <div key={sIdx} className="bg-[#262626] rounded-xl border border-white/5 overflow-hidden">
                      <div className="p-4 bg-white/5 flex justify-between items-center">
                        <input
                          className="bg-transparent font-bold focus:outline-none border-b border-transparent focus:border-purple-500"
                          value={season.title}
                          onChange={(e) => {
                            const newSeasons = [...formData.seasons];
                            newSeasons[sIdx].title = e.target.value;
                            setFormData({...formData, seasons: newSeasons});
                          }}
                        />
                        <div className="flex space-x-2">
                          <button
                            type="button"
                            onClick={() => addEpisode(sIdx)}
                            className="text-purple-400 hover:text-purple-300 text-xs font-bold"
                          >
                            + Add Episode
                          </button>
                          <button
                            type="button"
                            onClick={() => removeSeason(sIdx)}
                            className="text-red-500 hover:text-red-400 text-xs"
                          >
                            Remove
                          </button>
                        </div>
                      </div>
                      <div className="p-4 space-y-4">
                        {season.episodes.map((episode, eIdx) => (
                          <div key={eIdx} className="bg-black/20 p-4 rounded-lg border border-white/5 space-y-3">
                            <div className="flex justify-between items-center">
                              <span className="text-[10px] font-black text-gray-500 uppercase">Episode {episode.number}</span>
                              <button
                                type="button"
                                onClick={() => removeEpisode(sIdx, eIdx)}
                                className="text-red-500/50 hover:text-red-500"
                              >
                                ✕
                              </button>
                            </div>
                            <div className="grid grid-cols-2 gap-3">
                              <input
                                placeholder="Episode Title"
                                className="col-span-2 bg-[#141414] border border-white/10 rounded px-3 py-1.5 text-xs outline-none focus:border-purple-500"
                                value={episode.title}
                                onChange={(e) => updateEpisode(sIdx, eIdx, 'title', e.target.value)}
                              />
                              <input
                                placeholder="Duration (e.g. 45m)"
                                className="bg-[#141414] border border-white/10 rounded px-3 py-1.5 text-xs outline-none focus:border-purple-500"
                                value={episode.duration}
                                onChange={(e) => updateEpisode(sIdx, eIdx, 'duration', e.target.value)}
                              />
                              <div className="flex space-x-2">
                                <input
                                  placeholder="Video URL"
                                  className="flex-1 bg-[#141414] border border-white/10 rounded px-3 py-1.5 text-xs outline-none focus:border-purple-500"
                                  value={episode.videoUrl}
                                  onChange={(e) => updateEpisode(sIdx, eIdx, 'videoUrl', e.target.value)}
                                />
                                <label className="bg-white/5 hover:bg-white/10 px-3 py-1.5 rounded cursor-pointer transition-colors flex items-center justify-center">
                                  <span className="text-[10px] font-bold">UPLOAD</span>
                                  <input
                                    type="file"
                                    className="hidden"
                                    accept="video/*"
                                    onChange={(e) => handleFileUpload(e.target.files[0], 'episodeVideo', { seasonIndex: sIdx, episodeIndex: eIdx })}
                                  />
                                </label>
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              )}

              <div className="grid grid-cols-1 gap-4 bg-[#262626] p-4 rounded-xl border border-white/5">
                <label className="block text-xs font-black text-gray-500 mb-1 uppercase tracking-widest">Poster & Visuals</label>
                <div>
                  <label className="block text-[10px] text-gray-400 mb-1 font-bold italic">OPTION 1: UPLOAD LOCAL FILE</label>
                  <input
                    type="file"
                    accept="image/*"
                    className="w-full bg-[#141414] border border-white/10 rounded px-4 py-2 text-sm"
                    onChange={(e) => handleFileUpload(e.target.files[0], 'poster')}
                  />
                  {uploadProgress.poster > 0 && (
                    <div className="w-full bg-gray-700 h-1 mt-2 rounded-full overflow-hidden">
                      <div className="bg-purple-500 h-full" style={{ width: `${uploadProgress.poster}%` }}></div>
                    </div>
                  )}
                </div>

                <div>
                  <label className="block text-[10px] text-gray-400 mb-1 font-bold italic">OPTION 2: FETCH FROM EXTERNAL URL</label>
                  <div className="flex space-x-2">
                    <input
                      placeholder="Paste image link here..."
                      className="flex-1 bg-[#141414] border border-white/10 rounded px-4 py-2 text-sm focus:border-purple-500 outline-none"
                      value={formData.posterUrl}
                      onChange={(e) => setFormData({...formData, posterUrl: e.target.value})}
                    />
                    <button
                      type="button"
                      onClick={handleUploadFromUrl}
                      className="bg-white/10 hover:bg-white/20 px-4 rounded text-[10px] font-black uppercase tracking-tighter"
                    >
                      Fetch
                    </button>
                  </div>
                </div>

                <div>
                  <label className="block text-[10px] text-gray-400 mb-1 font-bold uppercase">Backdrop URL (Optional)</label>
                  <input
                    className="w-full bg-[#141414] border border-white/10 rounded px-4 py-2 text-sm focus:border-purple-500 outline-none"
                    value={formData.backdropUrl}
                    onChange={(e) => setFormData({...formData, backdropUrl: e.target.value})}
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-400 mb-1">Year</label>
                  <input
                    type="number"
                    className="w-full bg-[#262626] border border-white/10 rounded px-4 py-2 focus:outline-none focus:border-purple-500"
                    value={formData.year}
                    onChange={(e) => setFormData({...formData, year: e.target.value})}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-400 mb-1">Duration/Seasons Info</label>
                  <input
                    className="w-full bg-[#262626] border border-white/10 rounded px-4 py-2 focus:outline-none focus:border-purple-500"
                    value={formData.duration}
                    placeholder={formData.isTvShow ? "e.g. 3 Seasons" : "e.g. 2h 10m"}
                    onChange={(e) => setFormData({...formData, duration: e.target.value})}
                  />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-400 mb-1">Genres (Comma separated)</label>
                  <input
                    className="w-full bg-[#262626] border border-white/10 rounded px-4 py-2 focus:outline-none focus:border-purple-500"
                    value={formData.genre}
                    onChange={(e) => setFormData({...formData, genre: e.target.value})}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-400 mb-1">Rating (e.g. 13+, R)</label>
                  <input
                    className="w-full bg-[#262626] border border-white/10 rounded px-4 py-2 focus:outline-none focus:border-purple-500"
                    value={formData.contentRating}
                    onChange={(e) => setFormData({...formData, contentRating: e.target.value})}
                  />
                </div>
              </div>
              <div className="pt-4 pb-10">
                <button
                  type="submit"
                  disabled={isUploading}
                  className="w-full bg-purple-600 hover:bg-purple-700 py-3 rounded-lg font-bold transition-all disabled:opacity-50"
                >
                  {isUploading ? 'Uploading Files...' : 'Confirm Upload'}
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
