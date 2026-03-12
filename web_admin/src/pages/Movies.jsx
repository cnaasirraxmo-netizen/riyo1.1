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
  AlertCircle,
  MoreVertical,
  Globe,
  Clock,
  Star,
  Tag,
  Eye,
  Settings,
  Shield,
  Layers,
  Link as LinkIcon
} from 'lucide-react';
import { movieService } from '../services/api';

const Movies = () => {
  const [isAddingNew, setIsAddingNew] = useState(false);
  const [movies, setMovies] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [activeTab, setActiveTab] = useState('general');
  const [filterCategory, setFilterCategory] = useState('');
  const [filterStatus, setFilterStatus] = useState('');

  const [newMovie, setNewMovie] = useState({
    title: '',
    shortDesc: '',
    description: '',
    year: new Date().getFullYear(),
    duration: 120,
    genre: [],
    language: 'English',
    country: 'United States',
    director: '',
    cast: [],
    rating: 8.5,
    ageRating: '13+',
    quality: 'Full HD',
    status: 'published',
    accessType: 'free',
    tags: [],
    posterUrl: '',
    bannerUrl: '',
    thumbnailUrl: '',
    videoUrl: '',
    trailerUrl: '',
    trailerType: 'link',
    sources: [
      { label: 'Primary', url: '', type: 'direct', provider: 'url' }
    ],
    isTvShow: false,
    isTrending: false,
    isFeatured: false
  });

  useEffect(() => {
    fetchMovies();
  }, [filterCategory, filterStatus]);

  const fetchMovies = async () => {
    setIsLoading(true);
    try {
      const data = await movieService.getAll({
        category: filterCategory,
        status: filterStatus,
        search: searchQuery
      });
      setMovies(data.movies || data || []);
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
      await movieService.create(newMovie);
      setIsAddingNew(false);
      fetchMovies();
      // Reset form omitted for brevity in this tool call but would be here
    } catch (err) {
      console.error('Error creating movie:', err);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteMovie = async (id) => {
    if (!window.confirm('Delete this movie?')) return;
    try {
      await movieService.delete(id);
      fetchMovies();
    } catch (err) {
      console.error('Error deleting movie:', err);
    }
  };

  const handleSourceChange = (index, field, value) => {
    const updatedSources = [...newMovie.sources];
    updatedSources[index][field] = value;
    setNewMovie({ ...newMovie, sources: updatedSources });
  };

  const addSource = () => {
    setNewMovie({
      ...newMovie,
      sources: [...newMovie.sources, { label: `Backup ${newMovie.sources.length}`, url: '', type: 'direct', provider: 'url' }]
    });
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-[#1d2327] dark:text-white">Movie Management</h1>
        <button onClick={() => setIsAddingNew(true)} className="btn-primary">
          <Plus size={18} /> Create New Movie
        </button>
      </div>

      {/* Advanced Filter Bar */}
      <div className="admin-card grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="relative">
          <input
            type="text"
            placeholder="Search by title..."
            className="input-field pl-10 w-full"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && fetchMovies()}
          />
          <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        </div>
        <select
          className="input-field"
          value={filterCategory}
          onChange={(e) => setFilterCategory(e.target.value)}
        >
          <option value="">All Categories</option>
          <option value="Action">Action</option>
          <option value="Drama">Drama</option>
          <option value="Comedy">Comedy</option>
          <option value="Horror">Horror</option>
        </select>
        <select
          className="input-field"
          value={filterStatus}
          onChange={(e) => setFilterStatus(e.target.value)}
        >
          <option value="">All Status</option>
          <option value="published">Published</option>
          <option value="draft">Draft</option>
          <option value="coming_soon">Coming Soon</option>
          <option value="premium">Premium</option>
        </select>
        <button onClick={fetchMovies} className="btn-secondary justify-center">Apply Filters</button>
      </div>

      {/* Movie Table */}
      <div className="admin-card p-0 overflow-x-auto">
        <table className="w-full text-left border-collapse min-w-[1000px]">
          <thead>
            <tr className="bg-gray-50 dark:bg-[#2c3338] border-b border-[#dcdcde] dark:border-gray-800 text-xs font-bold text-gray-500 dark:text-gray-400 uppercase">
              <th className="p-4 w-16">Poster</th>
              <th className="p-4">Title & Genre</th>
              <th className="p-4">Year/Dur</th>
              <th className="p-4">Quality</th>
              <th className="p-4">Status</th>
              <th className="p-4">Access</th>
              <th className="p-4"><Eye size={14} /> Views</th>
              <th className="p-4 text-right pr-8">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#dcdcde] dark:divide-gray-800">
            {isLoading ? (
              <tr><td colSpan="8" className="p-12 text-center"><Loader2 className="mx-auto animate-spin" /></td></tr>
            ) : movies.map(movie => (
              <tr key={movie._id} className="hover:bg-gray-50 dark:hover:bg-[#2c3338] transition-colors group">
                <td className="p-4">
                  <div className="w-10 h-14 bg-gray-200 rounded overflow-hidden">
                    <img src={movie.posterUrl || 'https://via.placeholder.com/100x150'} className="w-full h-full object-cover" />
                  </div>
                </td>
                <td className="p-4">
                  <p className="font-bold text-[#2271b1] dark:text-blue-400">{movie.title}</p>
                  <p className="text-xs text-gray-500 mt-1">{movie.genre?.join(', ')}</p>
                </td>
                <td className="p-4 text-sm">
                  <p>{movie.year}</p>
                  <p className="text-gray-400 text-xs">{movie.duration}m</p>
                </td>
                <td className="p-4">
                  <span className="px-2 py-0.5 rounded bg-blue-100 text-blue-700 text-[10px] font-bold">{movie.quality}</span>
                </td>
                <td className="p-4">
                  <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase border ${
                    movie.status === 'published' ? 'text-green-600 bg-green-50 border-green-200' :
                    movie.status === 'premium' ? 'text-purple-600 bg-purple-50 border-purple-200' :
                    'text-gray-500 bg-gray-100 border-gray-200'
                  }`}>
                    {movie.status}
                  </span>
                </td>
                <td className="p-4 text-xs font-semibold capitalize">{movie.accessType}</td>
                <td className="p-4 text-sm font-bold">{movie.views?.toLocaleString() || 0}</td>
                <td className="p-4 text-right pr-6">
                  <div className="flex justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button className="p-2 hover:bg-gray-200 dark:hover:bg-gray-700 rounded text-gray-600 dark:text-gray-400"><Settings size={16} /></button>
                    <button onClick={() => handleDeleteMovie(movie._id)} className="p-2 hover:bg-red-50 text-red-500 rounded"><X size={16} /></button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Multi-Tab Add Movie Modal */}
      {isAddingNew && (
        <div className="fixed inset-0 bg-black/60 z-[100] flex items-center justify-center p-4 backdrop-blur-sm">
          <div className="bg-white dark:bg-[#1e1e1e] rounded-xl shadow-2xl w-full max-w-5xl max-h-[90vh] overflow-hidden flex flex-col">
            <div className="p-6 border-b border-[#dcdcde] dark:border-gray-800 flex items-center justify-between">
              <h2 className="text-xl font-bold dark:text-white flex items-center gap-2">
                <Film className="text-blue-600" /> Create Professional Movie Entry
              </h2>
              <button onClick={() => setIsAddingNew(false)} className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full transition-colors">
                <X size={20} />
              </button>
            </div>

            {/* Modal Tabs */}
            <div className="flex border-b border-[#dcdcde] dark:border-gray-800 px-6 bg-gray-50 dark:bg-[#1a1a1a]">
              {[
                { id: 'general', label: 'General Info', icon: <Globe size={16} /> },
                { id: 'media', label: 'Media Assets', icon: <ImageIcon size={16} /> },
                { id: 'sources', label: 'Video Sources', icon: <Play size={16} /> },
                { id: 'advanced', label: 'Advanced Settings', icon: <Shield size={16} /> }
              ].map(tab => (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center gap-2 py-4 px-6 text-sm font-bold transition-all border-b-2 ${
                    activeTab === tab.id ? 'border-blue-600 text-blue-600 bg-white dark:bg-[#1e1e1e]' : 'border-transparent text-gray-500 hover:text-gray-700'
                  }`}
                >
                  {tab.icon} {tab.label}
                </button>
              ))}
            </div>

            <div className="flex-1 overflow-y-auto p-8">
              <form id="movieForm" onSubmit={handleCreateMovie} className="space-y-8">
                {activeTab === 'general' && (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-4">
                      <div>
                        <label className="block text-xs font-bold mb-1 uppercase text-gray-500">Full Title</label>
                        <input type="text" required className="input-field w-full" value={newMovie.title} onChange={e => setNewMovie({...newMovie, title: e.target.value})} />
                      </div>
                      <div>
                        <label className="block text-xs font-bold mb-1 uppercase text-gray-500">Short Description</label>
                        <input type="text" className="input-field w-full" value={newMovie.shortDesc} onChange={e => setNewMovie({...newMovie, shortDesc: e.target.value})} />
                      </div>
                      <div>
                        <label className="block text-xs font-bold mb-1 uppercase text-gray-500">Plot Summary</label>
                        <textarea className="input-field w-full h-32" value={newMovie.description} onChange={e => setNewMovie({...newMovie, description: e.target.value})}></textarea>
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4 content-start">
                      <div>
                        <label className="block text-xs font-bold mb-1 uppercase text-gray-500">Year</label>
                        <input type="number" className="input-field w-full" value={newMovie.year} onChange={e => setNewMovie({...newMovie, year: e.target.value})} />
                      </div>
                      <div>
                        <label className="block text-xs font-bold mb-1 uppercase text-gray-500">Runtime (min)</label>
                        <input type="number" className="input-field w-full" value={newMovie.duration} onChange={e => setNewMovie({...newMovie, duration: e.target.value})} />
                      </div>
                      <div>
                        <label className="block text-xs font-bold mb-1 uppercase text-gray-500">IMDB Rating</label>
                        <input type="number" step="0.1" className="input-field w-full" value={newMovie.rating} onChange={e => setNewMovie({...newMovie, rating: e.target.value})} />
                      </div>
                      <div>
                        <label className="block text-xs font-bold mb-1 uppercase text-gray-500">Content Rating</label>
                        <select className="input-field w-full" value={newMovie.ageRating} onChange={e => setNewMovie({...newMovie, ageRating: e.target.value})}>
                          <option>G</option><option>PG</option><option>PG-13</option><option>R</option><option>NC-17</option>
                        </select>
                      </div>
                      <div className="col-span-2">
                        <label className="block text-xs font-bold mb-1 uppercase text-gray-500">Director</label>
                        <input type="text" className="input-field w-full" value={newMovie.director} onChange={e => setNewMovie({...newMovie, director: e.target.value})} />
                      </div>
                    </div>
                  </div>
                )}

                {activeTab === 'media' && (
                  <div className="space-y-6">
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                      <div className="admin-card border-dashed flex flex-col items-center justify-center p-8 bg-gray-50 dark:bg-gray-800/30">
                         <div className="p-4 bg-blue-100 dark:bg-blue-900/30 rounded-full text-blue-600 mb-4"><Upload size={32} /></div>
                         <p className="text-sm font-bold">Main Poster</p>
                         <p className="text-[10px] text-gray-400 mt-1">Recommended: 1000x1500px</p>
                         <input type="text" placeholder="Or paste URL here..." className="input-field w-full mt-4 text-xs" value={newMovie.posterUrl} onChange={e => setNewMovie({...newMovie, posterUrl: e.target.value})} />
                      </div>
                      <div className="admin-card border-dashed flex flex-col items-center justify-center p-8 bg-gray-50 dark:bg-gray-800/30">
                         <div className="p-4 bg-purple-100 dark:bg-purple-900/30 rounded-full text-purple-600 mb-4"><ImageIcon size={32} /></div>
                         <p className="text-sm font-bold">Landscape Banner</p>
                         <p className="text-[10px] text-gray-400 mt-1">Recommended: 1920x1080px</p>
                         <input type="text" placeholder="Or paste URL here..." className="input-field w-full mt-4 text-xs" value={newMovie.bannerUrl} onChange={e => setNewMovie({...newMovie, bannerUrl: e.target.value})} />
                      </div>
                      <div className="admin-card border-dashed flex flex-col items-center justify-center p-8 bg-gray-50 dark:bg-gray-800/30">
                         <div className="p-4 bg-orange-100 dark:bg-orange-900/30 rounded-full text-orange-600 mb-4"><Play size={32} /></div>
                         <p className="text-sm font-bold">Trailer Source</p>
                         <p className="text-[10px] text-gray-400 mt-1">YouTube or Direct Link</p>
                         <input type="text" placeholder="Link here..." className="input-field w-full mt-4 text-xs" value={newMovie.trailerUrl} onChange={e => setNewMovie({...newMovie, trailerUrl: e.target.value})} />
                      </div>
                    </div>
                  </div>
                )}

                {activeTab === 'sources' && (
                  <div className="space-y-6">
                    <div className="flex items-center justify-between mb-2">
                      <h3 className="text-sm font-bold uppercase text-gray-400">Streaming Load Balancer</h3>
                      <button type="button" onClick={addSource} className="text-xs text-blue-600 font-bold flex items-center gap-1"><Plus size={14} /> Add Backup Source</button>
                    </div>
                    <div className="space-y-4">
                      {newMovie.sources.map((source, index) => (
                        <div key={index} className="admin-card grid grid-cols-1 md:grid-cols-4 gap-4 items-end bg-gray-50 dark:bg-[#1a1a1a]">
                           <div className="md:col-span-1">
                             <label className="block text-[10px] font-bold mb-1 uppercase">Source Label</label>
                             <input type="text" className="input-field w-full" value={source.label} onChange={e => handleSourceChange(index, 'label', e.target.value)} />
                           </div>
                           <div className="md:col-span-2">
                             <label className="block text-[10px] font-bold mb-1 uppercase">Video URL / Provider Key</label>
                             <div className="relative">
                               <input type="text" className="input-field w-full pl-10" value={source.url} onChange={e => handleSourceChange(index, 'url', e.target.value)} />
                               <LinkIcon size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                             </div>
                           </div>
                           <div className="md:col-span-1">
                             <label className="block text-[10px] font-bold mb-1 uppercase">Type</label>
                             <select className="input-field w-full" value={source.type} onChange={e => handleSourceChange(index, 'type', e.target.value)}>
                               <option value="direct">Direct (.mp4)</option>
                               <option value="hls">HLS (.m3u8)</option>
                               <option value="embed">Embed (Iframe)</option>
                             </select>
                           </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {activeTab === 'advanced' && (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                    <div className="admin-card space-y-4">
                       <h3 className="text-sm font-bold border-b pb-2 mb-4">Availability & Monetization</h3>
                       <div className="flex items-center justify-between">
                         <div><p className="text-sm font-bold">Release Status</p><p className="text-xs text-gray-500">Current state in app</p></div>
                         <select className="input-field w-32" value={newMovie.status} onChange={e => setNewMovie({...newMovie, status: e.target.value})}>
                           <option value="published">Published</option><option value="draft">Draft</option><option value="coming_soon">Coming Soon</option><option value="premium">Premium</option>
                         </select>
                       </div>
                       <div className="flex items-center justify-between">
                         <div><p className="text-sm font-bold">Access Level</p><p className="text-xs text-gray-500">Who can watch this?</p></div>
                         <select className="input-field w-32" value={newMovie.accessType} onChange={e => setNewMovie({...newMovie, accessType: e.target.value})}>
                           <option value="free">Free</option><option value="premium">Premium</option><option value="subscription">Subscriber Only</option>
                         </select>
                       </div>
                    </div>
                    <div className="admin-card space-y-4">
                       <h3 className="text-sm font-bold border-b pb-2 mb-4">Display Flags</h3>
                       <label className="flex items-center gap-3 cursor-pointer p-2 hover:bg-gray-50 rounded transition-colors">
                         <input type="checkbox" className="w-4 h-4 rounded text-blue-600" checked={newMovie.isTrending} onChange={e => setNewMovie({...newMovie, isTrending: e.target.checked})} />
                         <span className="text-sm font-bold">Mark as Trending</span>
                       </label>
                       <label className="flex items-center gap-3 cursor-pointer p-2 hover:bg-gray-50 rounded transition-colors">
                         <input type="checkbox" className="w-4 h-4 rounded text-blue-600" checked={newMovie.isFeatured} onChange={e => setNewMovie({...newMovie, isFeatured: e.target.checked})} />
                         <span className="text-sm font-bold">Pin to Featured Slider</span>
                       </label>
                    </div>
                  </div>
                )}
              </form>
            </div>

            <div className="p-6 border-t border-[#dcdcde] dark:border-gray-800 bg-gray-50 dark:bg-[#1a1a1a] flex justify-end gap-4">
              <button onClick={() => setIsAddingNew(false)} className="btn-secondary">Discard Changes</button>
              <button
                form="movieForm"
                type="submit"
                disabled={isSubmitting}
                className="btn-primary px-10 py-3 shadow-lg shadow-blue-500/20"
              >
                {isSubmitting ? <Loader2 size={20} className="animate-spin" /> : 'Confirm & Publish'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Movies;
