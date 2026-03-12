import React, { useState } from 'react';
import {
  Plus,
  Search,
  X,
  Upload,
  Calendar,
  Image as ImageIcon,
  Play,
  Film
} from 'lucide-react';

const Movies = () => {
  const [isAddingNew, setIsAddingNew] = useState(false);

  const movies = [
    { id: 1, title: 'Inception', year: '2010', duration: '148 min', category: 'Sci-Fi', status: 'Published', views: '124,000', poster: 'https://picsum.photos/seed/inception/100/150' },
    { id: 2, title: 'Interstellar', year: '2014', duration: '169 min', category: 'Sci-Fi', status: 'Premium', views: '98,200', poster: 'https://picsum.photos/seed/interstellar/100/150' },
    { id: 3, title: 'The Dark Knight', year: '2008', duration: '152 min', category: 'Action', status: 'Published', views: '210,000', poster: 'https://picsum.photos/seed/darkknight/100/150' },
  ];

  const getStatusColor = (status) => {
    switch (status) {
      case 'Published': return 'text-green-600 bg-green-50 border-green-200';
      case 'Premium': return 'text-purple-600 bg-purple-50 border-purple-200';
      case 'Coming Soon': return 'text-blue-600 bg-blue-50 border-blue-200';
      case 'Draft': return 'text-gray-600 bg-gray-50 border-gray-200';
      default: return 'text-gray-600 bg-gray-50 border-gray-200';
    }
  };

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

            <form className="p-8 grid grid-cols-1 md:grid-cols-2 gap-8">
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-bold mb-1">Movie Title</label>
                  <input type="text" className="input-field w-full" placeholder="Enter title" />
                </div>
                <div>
                  <label className="block text-sm font-bold mb-1">Overview / Synopsis</label>
                  <textarea className="input-field w-full h-32 resize-none" placeholder="Enter movie description"></textarea>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-bold mb-1">Release Year</label>
                    <input type="text" className="input-field w-full" placeholder="2024" />
                  </div>
                  <div>
                    <label className="block text-sm font-bold mb-1">Duration (min)</label>
                    <input type="text" className="input-field w-full" placeholder="120" />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-bold mb-1">Category</label>
                  <select className="input-field w-full">
                    <option>Action</option>
                    <option>Sci-Fi</option>
                    <option>Drama</option>
                    <option>Horror</option>
                  </select>
                </div>
              </div>

              <div className="space-y-6">
                <div className="border-2 border-dashed border-[#dcdcde] rounded-lg p-6 text-center hover:border-blue-400 transition-colors cursor-pointer group">
                  <ImageIcon size={32} className="mx-auto mb-2 text-gray-400 group-hover:text-blue-500" />
                  <p className="text-sm font-bold">Upload Poster</p>
                  <p className="text-xs text-gray-400 mt-1">Recommended: 1000x1500px</p>
                </div>
                <div className="border-2 border-dashed border-[#dcdcde] rounded-lg p-6 text-center hover:border-blue-400 transition-colors cursor-pointer group">
                  <Play size={32} className="mx-auto mb-2 text-gray-400 group-hover:text-blue-500" />
                  <p className="text-sm font-bold">Upload Trailer</p>
                  <p className="text-xs text-gray-400 mt-1">MP4 format preferred</p>
                </div>
                <div className="bg-blue-50 border border-blue-100 rounded-lg p-4">
                  <div className="flex items-center gap-3 mb-3">
                    <Upload size={18} className="text-blue-600" />
                    <span className="font-bold text-blue-800">Movie File</span>
                  </div>
                  <button type="button" className="btn-primary w-full justify-center">Select Video File</button>
                </div>
              </div>

              <div className="md:col-span-2 flex justify-end gap-4 border-t border-[#dcdcde] pt-6">
                <button type="button" onClick={() => setIsAddingNew(false)} className="btn-secondary">Cancel</button>
                <button type="submit" className="btn-primary px-8">Publish Movie</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Filters Bar */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          <select className="input-field text-sm py-1">
            <option>Bulk Actions</option>
            <option>Edit</option>
            <option>Move to Trash</option>
          </select>
          <button className="btn-secondary py-1 px-3 text-sm">Apply</button>

          <select className="input-field text-sm py-1 ml-4">
            <option>All Dates</option>
          </select>
          <button className="btn-secondary py-1 px-3 text-sm">Filter</button>
        </div>

        <div className="relative">
          <input type="text" placeholder="Search movies..." className="input-field pl-10 text-sm" />
          <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        </div>
      </div>

      {/* Movies Table */}
      <div className="admin-card overflow-hidden p-0">
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
            {movies.map((movie) => (
              <tr key={movie.id} className="hover:bg-gray-50 group">
                <td className="p-4"><input type="checkbox" /></td>
                <td className="p-4">
                  <div className="w-10 h-14 bg-gray-200 rounded overflow-hidden shadow-sm">
                    <img src={movie.poster} alt={movie.title} className="w-full h-full object-cover" />
                  </div>
                </td>
                <td className="p-4">
                  <div>
                    <p className="font-bold text-[#2271b1] hover:underline cursor-pointer">{movie.title}</p>
                    <p className="text-xs text-gray-500 mt-1">{movie.category} • {movie.duration}</p>
                  </div>
                </td>
                <td className="p-4 text-center">
                  <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold border uppercase ${getStatusColor(movie.status)}`}>
                    {movie.status}
                  </span>
                </td>
                <td className="p-4 text-sm text-gray-600">{movie.year}</td>
                <td className="p-4">
                  <div className="flex items-center justify-end gap-2 pr-4">
                    <button className="p-2 hover:bg-gray-100 rounded text-blue-600 transition-colors"><Film size={16} /></button>
                    <button className="p-2 hover:bg-red-50 rounded text-red-500 transition-colors"><X size={16} /></button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default Movies;
