import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import {
  Plus,
  Search,
  Filter,
  MoreVertical,
  Trash2,
  CheckCircle,
  Star,
  Download,
  Share2,
  Edit,
  Eye,
  ChevronDown,
  LayoutGrid,
  List,
  CheckSquare,
  Square
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const Movies = ({ isTvShow = false }) => {
  const navigate = useNavigate();
  const [movies, setMovies] = useState([]);
  const [loading, setLoading] = useState(true);
  const [viewMode, setViewMode] = useState('grid');
  const [selectedMovies, setSelectedMovies] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');

  const fetchMovies = async () => {
    setLoading(true);
    try {
      const movieRes = await api.get(`/movies?isTvShow=${isTvShow}`);
      setMovies(movieRes.data);
    } catch (err) {
      console.error(err);
      // Mock data if API fails
      setMovies([
        { _id: '1', title: 'Inception', year: 2010, description: 'A thief who steals corporate secrets...', posterUrl: 'https://image.tmdb.org/t/p/w500/9gk7Fn9sVAsS9Te6B1MCOQ6wPM3.jpg', isPremium: true, status: 'Public' },
        { _id: '2', title: 'The Matrix', year: 1999, description: 'A computer hacker learns...', posterUrl: 'https://image.tmdb.org/t/p/w500/f89U3Y9L7dbptqyQej86Z9Sbsqz.jpg', isPremium: false, status: 'Public' },
        { _id: '3', title: 'Interstellar', year: 2014, description: 'A team of explorers travel through...', posterUrl: 'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6vCU67oYvBPXT.jpg', isPremium: true, status: 'Draft' },
      ]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMovies();
  }, []);

  const toggleSelectMovie = (id) => {
    setSelectedMovies(prev =>
      prev.includes(id) ? prev.filter(mid => mid !== id) : [...prev, id]
    );
  };

  const toggleSelectAll = () => {
    if (selectedMovies.length === movies.length) setSelectedMovies([]);
    else setSelectedMovies(movies.map(m => m._id));
  };

  const handleBulkAction = async (action) => {
    const actionMap = {
      'Publish': 'publish',
      'Mark Premium': 'mark-premium',
      'Delete': 'delete',
      'Add to Collection': 'add-to-collection'
    };

    const apiAction = actionMap[action];
    if (!apiAction) return;

    if (apiAction === 'delete' && !window.confirm(`Are you sure you want to delete ${selectedMovies.length} items?`)) {
      return;
    }

    try {
      await api.post('/movies/bulk', {
        action: apiAction,
        movieIds: selectedMovies,
        data: apiAction === 'add-to-collection' ? { collectionName: prompt('Enter collection name:') } : {}
      });

      alert(`Successfully performed ${action} on ${selectedMovies.length} items.`);
      setSelectedMovies([]);
      fetchMovies();
    } catch (err) {
      console.error(err);
      alert('Error performing bulk action: ' + (err.response?.data?.message || err.message));
    }
  };

  const filteredMovies = movies.filter(m =>
    m.title.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="p-8 pb-24">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-8">
        <div>
          <h1 className="text-3xl font-black text-white">{isTvShow ? 'TV Series' : 'Movie'} Management</h1>
          <p className="text-gray-400 mt-1">Manage and curate your {isTvShow ? 'series' : 'movie'} library.</p>
        </div>
        <button
          onClick={() => navigate(isTvShow ? '/series/add' : '/movies/add')}
          className="bg-[#0ea5e9] hover:bg-[#0284c7] text-white px-6 py-3 rounded-2xl font-black transition-all flex items-center shadow-lg shadow-[#0ea5e9]/20"
        >
          <Plus size={20} className="mr-2" /> ADD NEW {isTvShow ? 'SERIES' : 'MOVIE'}
        </button>
      </div>

      {/* Toolbar */}
      <div className="bg-[#1f2937] p-4 rounded-2xl border border-white/5 mb-8 flex flex-col md:flex-row gap-4 items-center">
        <div className="relative flex-1 w-full">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500" size={18} />
          <input
            type="text"
            placeholder="Search by title, genre, year..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-[#111827] border border-white/10 rounded-xl pl-12 pr-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#0ea5e9]"
          />
        </div>

        <div className="flex items-center space-x-2 w-full md:w-auto">
          <button className="flex-1 md:flex-none flex items-center justify-center space-x-2 bg-[#111827] border border-white/10 px-4 py-2.5 rounded-xl text-gray-400 hover:text-white transition-colors">
            <Filter size={18} />
            <span className="text-sm font-bold">Filter</span>
          </button>

          <div className="flex bg-[#111827] p-1 rounded-xl border border-white/10">
            <button
              onClick={() => setViewMode('grid')}
              className={`p-2 rounded-lg transition-all ${viewMode === 'grid' ? 'bg-[#374151] text-[#0ea5e9]' : 'text-gray-500 hover:text-gray-300'}`}
            >
              <LayoutGrid size={18} />
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={`p-2 rounded-lg transition-all ${viewMode === 'list' ? 'bg-[#374151] text-[#0ea5e9]' : 'text-gray-500 hover:text-gray-300'}`}
            >
              <List size={18} />
            </button>
          </div>
        </div>
      </div>

      {/* Bulk Actions Bar */}
      {selectedMovies.length > 0 && (
        <div className="bg-[#0ea5e9] p-4 rounded-2xl flex items-center justify-between mb-8 shadow-xl shadow-[#0ea5e9]/20 animate-in slide-in-from-top-4 duration-300">
           <div className="flex items-center space-x-4">
              <button onClick={toggleSelectAll} className="text-white">
                <CheckSquare size={20} />
              </button>
              <span className="text-white font-black uppercase text-xs tracking-widest">{selectedMovies.length} SELECTED</span>
           </div>
           <div className="flex items-center space-x-2">
              <button onClick={() => handleBulkAction('Publish')} className="bg-white/10 hover:bg-white/20 px-3 py-1.5 rounded-lg text-white text-[10px] font-black uppercase">Publish</button>
              <button onClick={() => handleBulkAction('Mark Premium')} className="bg-white/10 hover:bg-white/20 px-3 py-1.5 rounded-lg text-white text-[10px] font-black uppercase">Mark Premium</button>
              <button onClick={() => handleBulkAction('Export')} className="bg-white/10 hover:bg-white/20 px-3 py-1.5 rounded-lg text-white text-[10px] font-black uppercase">Export</button>
              <button onClick={() => handleBulkAction('Delete')} className="bg-rose-600 hover:bg-rose-700 px-3 py-1.5 rounded-lg text-white text-[10px] font-black uppercase flex items-center">
                <Trash2 size={12} className="mr-1" /> Delete
              </button>
           </div>
        </div>
      )}

      {loading ? (
        <div className="flex flex-col items-center justify-center py-32 space-y-4">
           <div className="w-12 h-12 border-4 border-[#0ea5e9] border-t-transparent rounded-full animate-spin"></div>
           <p className="text-gray-500 font-bold uppercase tracking-widest text-xs">Synchronizing Library...</p>
        </div>
      ) : (
        viewMode === 'grid' ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5 gap-6">
            {filteredMovies.map((movie) => (
              <div
                key={movie._id}
                className={`bg-[#1f2937] rounded-3xl overflow-hidden border transition-all group relative ${
                  selectedMovies.includes(movie._id) ? 'border-[#0ea5e9] ring-2 ring-[#0ea5e9]/20' : 'border-white/5 hover:border-white/10'
                }`}
              >
                {/* Selection Overlay */}
                <button
                  onClick={() => toggleSelectMovie(movie._id)}
                  className={`absolute top-4 left-4 z-10 w-6 h-6 rounded-lg flex items-center justify-center transition-all ${
                    selectedMovies.includes(movie._id) ? 'bg-[#0ea5e9] text-white' : 'bg-black/40 text-transparent border border-white/20 group-hover:border-white/50'
                  }`}
                >
                  <CheckSquare size={14} />
                </button>

                <div className="aspect-[2/3] overflow-hidden relative">
                  <img src={movie.posterUrl} className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110" />
                  <div className="absolute inset-0 bg-gradient-to-t from-[#111827] via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity">
                    <div className="absolute bottom-4 left-4 right-4 flex justify-between">
                       <button className="p-2 bg-white/10 backdrop-blur rounded-xl text-white hover:bg-[#0ea5e9] transition-colors"><Edit size={16} /></button>
                       <button className="p-2 bg-white/10 backdrop-blur rounded-xl text-white hover:bg-rose-600 transition-colors"><Trash2 size={16} /></button>
                    </div>
                  </div>
                  {movie.isPremium && (
                    <div className="absolute top-4 right-4 bg-amber-500 text-white p-1.5 rounded-xl shadow-lg">
                      <Star size={14} fill="currentColor" />
                    </div>
                  )}
                </div>
                <div className="p-5">
                  <div className="flex justify-between items-start mb-1">
                    <h3 className="font-bold text-white truncate pr-2">{movie.title}</h3>
                    <span className="text-[10px] font-black text-gray-500">{movie.year}</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className={`text-[8px] font-black px-2 py-0.5 rounded uppercase ${
                      movie.status === 'Public' ? 'bg-emerald-500/10 text-emerald-500' : 'bg-gray-500/10 text-gray-500'
                    }`}>{movie.status}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="bg-[#1f2937] rounded-3xl border border-white/5 overflow-hidden">
             <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-[#111827] text-gray-500 text-[10px] font-black uppercase tracking-widest border-b border-white/5">
                    <th className="px-6 py-4 w-12 text-center">
                      <button onClick={toggleSelectAll}>
                        {selectedMovies.length === movies.length ? <CheckSquare size={16} className="text-[#0ea5e9]" /> : <Square size={16} />}
                      </button>
                    </th>
                    <th className="px-6 py-4">Movie</th>
                    <th className="px-6 py-4">Year</th>
                    <th className="px-6 py-4">Status</th>
                    <th className="px-6 py-4">Tier</th>
                    <th className="px-6 py-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-white/5">
                  {filteredMovies.map(movie => (
                    <tr key={movie._id} className={`hover:bg-white/[0.02] transition-colors ${selectedMovies.includes(movie._id) ? 'bg-[#0ea5e9]/5' : ''}`}>
                      <td className="px-6 py-4 text-center">
                        <button onClick={() => toggleSelectMovie(movie._id)} className={selectedMovies.includes(movie._id) ? 'text-[#0ea5e9]' : 'text-gray-700'}>
                          {selectedMovies.includes(movie._id) ? <CheckSquare size={16} /> : <Square size={16} />}
                        </button>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center space-x-4">
                           <img src={movie.posterUrl} className="w-10 h-14 rounded-lg object-cover" />
                           <div>
                              <div className="font-bold text-white text-sm">{movie.title}</div>
                              <div className="text-[10px] text-gray-500 line-clamp-1 max-w-xs">{movie.description}</div>
                           </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-gray-400 text-sm font-medium">{movie.year}</td>
                      <td className="px-6 py-4">
                        <span className={`text-[10px] font-black px-2 py-1 rounded uppercase ${
                          movie.status === 'Public' ? 'bg-emerald-500/10 text-emerald-500' : 'bg-gray-500/10 text-gray-500'
                        }`}>{movie.status}</span>
                      </td>
                      <td className="px-6 py-4">
                        {movie.isPremium ? (
                          <span className="flex items-center text-amber-500 text-[10px] font-black uppercase">
                            <Star size={10} className="mr-1" fill="currentColor" /> Premium
                          </span>
                        ) : (
                          <span className="text-gray-500 text-[10px] font-black uppercase tracking-tighter">Free</span>
                        )}
                      </td>
                      <td className="px-6 py-4 text-right">
                         <div className="flex justify-end space-x-2">
                            <button className="p-2 text-gray-500 hover:text-[#0ea5e9] transition-colors"><Edit size={16} /></button>
                            <button className="p-2 text-gray-500 hover:text-rose-500 transition-colors"><Trash2 size={16} /></button>
                         </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
             </table>
          </div>
        )
      )}
    </div>
  );
};

export default Movies;
