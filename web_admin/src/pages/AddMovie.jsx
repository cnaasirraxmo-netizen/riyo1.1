import React, { useState } from 'react';
import {
  Upload,
  Link as LinkIcon,
  Globe,
  Youtube,
  Cloud,
  Info,
  Settings,
  Image as ImageIcon,
  Video,
  Languages,
  DollarSign,
  Plus,
  Trash2,
  CheckCircle2,
  AlertCircle,
  ArrowRight,
  ArrowLeft,
  ChevronRight
} from 'lucide-react';
import api from '../utils/api';
import { useNavigate } from 'react-router-dom';

const AddMovie = ({ isTvShow: isTvShowProp = false }) => {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('basic');
  const [uploadMethod, setUploadMethod] = useState('file');
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);

  const [formData, setFormData] = useState({
    // Basic Info
    title: '',
    description: '',
    genres: [],
    category: '',
    year: new Date().getFullYear(),
    duration: '',
    language: 'English',
    country: '',

    // Categorization
    contentRating: 'PG-13',
    tags: '',
    collection: '',
    regionalAvailability: ['Global'],

    // Settings
    status: 'Draft', // Public, Draft, Coming Soon
    isPremium: false,
    isDownloadable: true,
    isFeatured: false,
    isOriginal: false,
    isTvShow: isTvShowProp,

    // TV Show Specific
    seasons: [
      {
        number: 1,
        status: 'Completed',
        episodes: [{ number: 1, title: '', duration: '', videoUrl: '', thumbnailUrl: '', isDownloadable: true, sources: { '480p': '', '720p': '', '1080p': '', '4K': '' } }]
      }
    ],

    // Media
    posterUrl: '',
    backdropUrl: '',
    trailerUrl: '',
    gallery: [],

    // Video Sources
    sources: {
      '480p': '',
      '720p': '',
      '1080p': '',
      '4K': '',
    },
    useDRM: false,

    // Subtitles
    subtitles: [],

    // Monetization
    rentPrice: 0,
    buyPrice: 0,
    rentalDuration: 48, // hours
    premiumOnly: false
  });

  const tabs = [
    { id: 'basic', label: 'Basic Info', icon: <Info size={16} /> },
    { id: 'categorization', label: 'Categorization', icon: <Globe size={16} /> },
    { id: 'media', label: 'Media Assets', icon: <ImageIcon size={16} /> },
    { id: 'video', label: 'Video & Sources', icon: <Video size={16} /> },
    ...(formData.isTvShow ? [{ id: 'episodes', label: 'Seasons & Episodes', icon: <Tv size={16} /> }] : []),
    { id: 'monetization', label: 'Monetization', icon: <DollarSign size={16} /> },
    { id: 'settings', label: 'Final Settings', icon: <Settings size={16} /> },
  ];

  const uploadMethods = [
    { id: 'file', label: 'Direct Upload', icon: <Upload size={20} />, desc: 'Max 10GB (MP4, MKV)' },
    { id: 'url', label: 'URL Upload', icon: <LinkIcon size={20} />, desc: 'MP4, MKV, HLS, DASH' },
    { id: 'multi', label: 'Multi-Quality', icon: <Settings size={20} />, desc: 'Different URLs per quality' },
    { id: 'embed', label: 'Embed', icon: <Youtube size={20} />, desc: 'YouTube, Vimeo' },
    { id: 'cloud', label: 'Cloud Import', icon: <Cloud size={20} />, desc: 'Drive, Dropbox, S3' },
  ];

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const handleGenreToggle = (genre) => {
    setFormData(prev => ({
      ...prev,
      genres: prev.genres.includes(genre)
        ? prev.genres.filter(g => g !== genre)
        : [...prev.genres, genre]
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsUploading(true);

    try {
      // Map frontend genres to backend format (ensure it matches backend expectactions)
      const submissionData = {
        ...formData,
        genre: formData.genres,
        collectionName: formData.collection,
      };

      const response = await api.post('/movies', submissionData);

      setIsUploading(false);
      alert(`${formData.isTvShow ? 'TV Show' : 'Movie'} added successfully!`);
      navigate(formData.isTvShow ? '/series' : '/movies');
    } catch (err) {
      console.error(err);
      setIsUploading(false);
      alert('Error adding content: ' + (err.response?.data?.message || err.message));
    }
  };

  return (
    <div className="p-8 max-w-6xl mx-auto pb-24">
      <div className="flex items-center space-x-2 text-gray-500 text-sm mb-4">
        <span className="hover:text-white cursor-pointer" onClick={() => navigate(formData.isTvShow ? '/series' : '/movies')}>{formData.isTvShow ? 'TV Series' : 'Movies'}</span>
        <ChevronRight size={14} />
        <span className="text-[#0ea5e9] font-bold uppercase tracking-widest text-xs">Add New Content</span>
      </div>

      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-black text-white">Create {formData.isTvShow ? 'Series' : 'Movie'}</h1>
          <p className="text-gray-400 mt-1">Configure metadata, media, and distribution settings.</p>
        </div>
        <div className="flex space-x-3">
          <button className="px-6 py-2 rounded-xl bg-white/5 text-gray-300 font-bold hover:bg-white/10 transition-colors border border-white/5">
            Save Draft
          </button>
          <button
            onClick={handleSubmit}
            className="px-8 py-2 rounded-xl bg-[#0ea5e9] text-white font-black hover:bg-[#0284c7] shadow-lg shadow-[#0ea5e9]/20 transition-all flex items-center"
          >
            {isUploading ? 'Publishing...' : 'Publish Movie'}
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex space-x-1 bg-[#1f2937] p-1 rounded-2xl mb-8 border border-white/5">
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`flex-1 flex items-center justify-center space-x-2 py-3 rounded-xl text-sm font-bold transition-all ${
              activeTab === tab.id ? 'bg-[#374151] text-[#0ea5e9] shadow-sm' : 'text-gray-400 hover:text-white hover:bg-white/5'
            }`}
          >
            {tab.icon}
            <span>{tab.label}</span>
          </button>
        ))}
      </div>

      <form className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Main Form Area */}
        <div className="lg:col-span-2 space-y-8">

          {activeTab === 'basic' && (
            <div className="bg-[#1f2937] p-8 rounded-3xl border border-white/5 space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
              <h3 className="text-xl font-bold text-white flex items-center">
                <Info className="mr-2 text-[#0ea5e9]" size={20} /> Basic Information
              </h3>

              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-black text-gray-500 uppercase tracking-widest mb-2">Movie Title</label>
                  <input
                    type="text"
                    name="title"
                    value={formData.title}
                    onChange={handleInputChange}
                    placeholder="Enter movie title"
                    className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-[#0ea5e9] transition-colors"
                  />
                </div>

                <div>
                  <label className="block text-xs font-black text-gray-500 uppercase tracking-widest mb-2">Description (max 500 chars)</label>
                  <textarea
                    name="description"
                    value={formData.description}
                    onChange={handleInputChange}
                    maxLength={500}
                    rows={4}
                    placeholder="Briefly describe the movie..."
                    className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-[#0ea5e9] transition-colors resize-none"
                  ></textarea>
                  <div className="text-right text-[10px] text-gray-500 mt-1 font-bold">
                    {formData.description.length}/500
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-black text-gray-500 uppercase tracking-widest mb-2">Release Year</label>
                    <input
                      type="number"
                      name="year"
                      value={formData.year}
                      onChange={handleInputChange}
                      className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-[#0ea5e9] transition-colors"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-black text-gray-500 uppercase tracking-widest mb-2">Duration (Auto-detected)</label>
                    <input
                      type="text"
                      name="duration"
                      value={formData.duration}
                      onChange={handleInputChange}
                      placeholder="e.g. 2h 15m"
                      className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-[#0ea5e9] transition-colors"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-black text-gray-500 uppercase tracking-widest mb-2">Primary Language</label>
                    <select
                      name="language"
                      value={formData.language}
                      onChange={handleInputChange}
                      className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-[#0ea5e9] transition-colors"
                    >
                      <option>English</option>
                      <option>Somali</option>
                      <option>Arabic</option>
                      <option>French</option>
                      <option>Spanish</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-xs font-black text-gray-500 uppercase tracking-widest mb-2">Country of Origin</label>
                    <input
                      type="text"
                      name="country"
                      value={formData.country}
                      onChange={handleInputChange}
                      placeholder="e.g. USA, UK"
                      className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-[#0ea5e9] transition-colors"
                    />
                  </div>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'categorization' && (
            <div className="bg-[#1f2937] p-8 rounded-3xl border border-white/5 space-y-8">
               <div>
                  <h3 className="text-xl font-bold text-white mb-6">Genres</h3>
                  <div className="flex flex-wrap gap-2">
                    {['Action', 'Comedy', 'Drama', 'Sci-Fi', 'Horror', 'Romance', 'Thriller', 'Animation', 'Documentary', 'Fantasy'].map(genre => (
                      <button
                        key={genre}
                        type="button"
                        onClick={() => handleGenreToggle(genre)}
                        className={`px-4 py-2 rounded-full text-xs font-bold transition-all border ${
                          formData.genres.includes(genre)
                            ? 'bg-[#0ea5e9] border-[#0ea5e9] text-white shadow-lg shadow-[#0ea5e9]/20'
                            : 'bg-[#111827] border-white/10 text-gray-400 hover:border-[#0ea5e9]/50'
                        }`}
                      >
                        {genre}
                      </button>
                    ))}
                  </div>
               </div>

               <div className="grid grid-cols-2 gap-8">
                  <div>
                    <label className="block text-xs font-black text-gray-500 uppercase tracking-widest mb-3">Content Rating</label>
                    <div className="grid grid-cols-2 gap-2">
                      {['G', 'PG', 'PG-13', 'R'].map(rating => (
                        <button
                          key={rating}
                          type="button"
                          onClick={() => setFormData({...formData, contentRating: rating})}
                          className={`py-3 rounded-xl text-sm font-black border transition-all ${
                            formData.contentRating === rating
                              ? 'bg-[#111827] border-[#0ea5e9] text-[#0ea5e9]'
                              : 'bg-[#111827] border-white/10 text-gray-500 hover:bg-white/5'
                          }`}
                        >
                          {rating}
                        </button>
                      ))}
                    </div>
                  </div>
                  <div>
                    <label className="block text-xs font-black text-gray-500 uppercase tracking-widest mb-3">Collection / Franchise</label>
                    <input
                      type="text"
                      name="collection"
                      value={formData.collection}
                      onChange={handleInputChange}
                      placeholder="e.g. Marvel Cinematic Universe"
                      className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-[#0ea5e9]"
                    />
                  </div>
               </div>

               <div>
                <label className="block text-xs font-black text-gray-500 uppercase tracking-widest mb-2">Tags (comma separated)</label>
                <input
                  type="text"
                  name="tags"
                  value={formData.tags}
                  onChange={handleInputChange}
                  placeholder="trending, oscar-winner, 4k"
                  className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-[#0ea5e9]"
                />
              </div>
            </div>
          )}

          {activeTab === 'media' && (
            <div className="bg-[#1f2937] p-8 rounded-3xl border border-white/5 space-y-8">
               <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                  <div className="space-y-4">
                    <label className="block text-xs font-black text-gray-500 uppercase tracking-widest">Main Poster</label>
                    <div className="aspect-[2/3] bg-[#111827] rounded-3xl border-2 border-dashed border-white/10 flex flex-col items-center justify-center relative overflow-hidden group cursor-pointer">
                        <ImageIcon size={48} className="text-gray-600 group-hover:text-[#0ea5e9] transition-colors mb-4" />
                        <span className="text-xs font-bold text-gray-500">Click or drag image</span>
                        <span className="text-[10px] text-gray-600 mt-1">Recommended: 1000x1500px</span>
                    </div>
                  </div>
                  <div className="space-y-4">
                    <label className="block text-xs font-black text-gray-500 uppercase tracking-widest">Landscape Backdrop</label>
                    <div className="aspect-video bg-[#111827] rounded-3xl border-2 border-dashed border-white/10 flex flex-col items-center justify-center relative overflow-hidden group cursor-pointer">
                        <ImageIcon size={48} className="text-gray-600 group-hover:text-[#0ea5e9] transition-colors mb-4" />
                        <span className="text-xs font-bold text-gray-500">Click or drag image</span>
                        <span className="text-[10px] text-gray-600 mt-1">Recommended: 1920x1080px</span>
                    </div>
                    <div className="pt-4">
                      <label className="block text-xs font-black text-gray-500 uppercase tracking-widest mb-2">Trailer URL (YouTube/Direct)</label>
                      <input
                        type="text"
                        name="trailerUrl"
                        value={formData.trailerUrl}
                        onChange={handleInputChange}
                        placeholder="https://youtube.com/watch?v=..."
                        className="w-full bg-[#111827] border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-[#0ea5e9]"
                      />
                    </div>
                  </div>
               </div>

               <div>
                <div className="flex justify-between items-center mb-4">
                  <label className="block text-xs font-black text-gray-500 uppercase tracking-widest">Gallery (Max 10 Images)</label>
                  <button type="button" className="text-[#0ea5e9] text-xs font-black flex items-center hover:underline">
                    <Plus size={14} className="mr-1" /> ADD MORE
                  </button>
                </div>
                <div className="grid grid-cols-5 gap-4">
                  {[1, 2, 3, 4, 5].map(i => (
                    <div key={i} className="aspect-square bg-[#111827] rounded-xl border border-white/5 flex items-center justify-center text-gray-700 hover:text-[#0ea5e9] cursor-pointer hover:border-[#0ea5e9]/20 transition-all">
                        <Plus size={24} />
                    </div>
                  ))}
                </div>
               </div>
            </div>
          )}

          {activeTab === 'episodes' && formData.isTvShow && (
            <div className="bg-[#1f2937] p-8 rounded-3xl border border-white/5 space-y-8 animate-in fade-in duration-500">
               <div className="flex justify-between items-center">
                  <h3 className="text-xl font-bold text-white">Series Structure</h3>
                  <button
                    type="button"
                    onClick={() => setFormData({...formData, seasons: [...formData.seasons, { number: formData.seasons.length + 1, episodes: [] }]})}
                    className="text-[#0ea5e9] text-xs font-black flex items-center hover:bg-[#0ea5e9]/10 px-3 py-2 rounded-lg transition-colors border border-[#0ea5e9]/20"
                  >
                    <Plus size={14} className="mr-1" /> ADD SEASON
                  </button>
               </div>

               {formData.seasons.map((season, sIdx) => (
                 <div key={sIdx} className="bg-[#111827] rounded-3xl border border-white/5 overflow-hidden">
                    <div className="p-4 bg-white/5 flex justify-between items-center">
                       <div className="flex items-center space-x-4">
                          <span className="text-sm font-black text-white uppercase tracking-widest">Season {season.number}</span>
                          <select
                            value={season.status}
                            onChange={(e) => {
                              const newSeasons = [...formData.seasons];
                              newSeasons[sIdx].status = e.target.value;
                              setFormData({...formData, seasons: newSeasons});
                            }}
                            className="bg-[#1f2937] text-[10px] font-bold text-gray-300 border border-white/10 rounded px-2 py-1 outline-none"
                          >
                            <option>Ongoing</option>
                            <option>Completed</option>
                          </select>
                       </div>
                       <div className="flex space-x-2">
                         <button
                           type="button"
                           onClick={() => {
                             const newSeasons = [...formData.seasons];
                             const nextNum = newSeasons[sIdx].episodes.length + 1;
                             newSeasons[sIdx].episodes.push({ number: nextNum, title: '', duration: '', videoUrl: '', thumbnailUrl: '', isDownloadable: true, sources: { '480p': '', '720p': '', '1080p': '', '4K': '' } });
                             setFormData({...formData, seasons: newSeasons});
                           }}
                           className="text-[10px] font-black text-[#0ea5e9] uppercase bg-[#0ea5e9]/10 px-3 py-1.5 rounded-lg border border-[#0ea5e9]/20"
                         >
                           Add Episode
                         </button>
                         <button
                           type="button"
                           onClick={() => {
                             const input = document.createElement('input');
                             input.type = 'file';
                             input.multiple = true;
                             input.onchange = (e) => {
                               const files = Array.from(e.target.files);
                               const newSeasons = [...formData.seasons];
                               files.forEach((file, idx) => {
                                 // Simple auto-numbering from filename
                                 const match = file.name.match(/\d+/);
                                 const num = match ? parseInt(match[0]) : newSeasons[sIdx].episodes.length + 1;
                                 newSeasons[sIdx].episodes.push({
                                   number: num,
                                   title: file.name.replace(/\.[^/.]+$/, "").replace(/_/g, " "),
                                   duration: '--',
                                   videoUrl: 'Local: ' + file.name,
                                   thumbnailUrl: '',
                                   isDownloadable: true,
                                   sources: { '480p': '', '720p': '', '1080p': '', '4K': '' }
                                 });
                               });
                               setFormData({...formData, seasons: newSeasons});
                             };
                             input.click();
                           }}
                           className="text-[10px] font-black text-purple-400 uppercase bg-purple-500/10 px-3 py-1.5 rounded-lg border border-purple-500/20"
                         >
                           Batch Upload
                         </button>
                       </div>
                    </div>
                    <div className="p-6 space-y-4">
                       {season.episodes.sort((a,b) => a.number - b.number).map((ep, eIdx) => (
                         <div key={eIdx} className="p-4 bg-[#1f2937] rounded-2xl border border-white/5 space-y-3">
                            <div className="flex items-center gap-4">
                              <input
                                type="number"
                                value={ep.number}
                                onChange={(e) => {
                                  const newSeasons = [...formData.seasons];
                                  newSeasons[sIdx].episodes[eIdx].number = parseInt(e.target.value);
                                  setFormData({...formData, seasons: newSeasons});
                                }}
                                className="w-12 bg-[#111827] border border-white/10 rounded-lg px-2 py-1.5 text-xs text-[#0ea5e9] font-black text-center"
                              />
                              <input
                                type="text"
                                placeholder="Episode Title"
                                value={ep.title}
                                onChange={(e) => {
                                  const newSeasons = [...formData.seasons];
                                  newSeasons[sIdx].episodes[eIdx].title = e.target.value;
                                  setFormData({...formData, seasons: newSeasons});
                                }}
                                className="flex-1 bg-[#111827] border border-white/10 rounded-xl px-4 py-2 text-sm text-white outline-none focus:border-[#0ea5e9]"
                              />
                              <input
                                type="text"
                                placeholder="Duration"
                                value={ep.duration}
                                onChange={(e) => {
                                  const newSeasons = [...formData.seasons];
                                  newSeasons[sIdx].episodes[eIdx].duration = e.target.value;
                                  setFormData({...formData, seasons: newSeasons});
                                }}
                                className="w-24 bg-[#111827] border border-white/10 rounded-xl px-4 py-2 text-sm text-white outline-none focus:border-[#0ea5e9]"
                              />
                              <div className="flex items-center space-x-2">
                                <span className="text-[10px] text-gray-500 font-bold uppercase">DL</span>
                                <input
                                  type="checkbox"
                                  checked={ep.isDownloadable}
                                  onChange={(e) => {
                                    const newSeasons = [...formData.seasons];
                                    newSeasons[sIdx].episodes[eIdx].isDownloadable = e.target.checked;
                                    setFormData({...formData, seasons: newSeasons});
                                  }}
                                  className="w-4 h-4 rounded border-white/10 bg-[#111827] text-[#0ea5e9]"
                                />
                              </div>
                              <button
                                type="button"
                                onClick={() => {
                                  const newSeasons = [...formData.seasons];
                                  newSeasons[sIdx].episodes.splice(eIdx, 1);
                                  setFormData({...formData, seasons: newSeasons});
                                }}
                                className="p-2 text-gray-600 hover:text-rose-500 transition-colors"
                              >
                                <Trash2 size={16} />
                              </button>
                            </div>
                            <div className="flex gap-4">
                               <div className="w-24 h-16 bg-[#111827] rounded-lg border border-white/10 flex items-center justify-center text-gray-700 cursor-pointer overflow-hidden relative group">
                                  {ep.thumbnailUrl ? <img src={ep.thumbnailUrl} className="w-full h-full object-cover" /> : <ImageIcon size={20} />}
                                  <div className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100 flex items-center justify-center transition-opacity text-[8px] text-white font-bold">SET THUMB</div>
                               </div>
                               <input
                                type="text"
                                placeholder="Main Stream URL / Path"
                                value={ep.videoUrl}
                                onChange={(e) => {
                                  const newSeasons = [...formData.seasons];
                                  newSeasons[sIdx].episodes[eIdx].videoUrl = e.target.value;
                                  setFormData({...formData, seasons: newSeasons});
                                }}
                                className="flex-1 bg-[#111827] border border-white/10 rounded-xl px-4 py-2 text-xs text-gray-400 outline-none focus:border-[#0ea5e9]"
                              />
                            </div>
                         </div>
                       ))}
                    </div>
                 </div>
               ))}
            </div>
          )}

          {activeTab === 'video' && (
            <div className="bg-[#1f2937] p-8 rounded-3xl border border-white/5 space-y-8">
                <div className="flex flex-wrap gap-3">
                  {uploadMethods.map(m => (
                    <button
                      key={m.id}
                      type="button"
                      onClick={() => setUploadMethod(m.id)}
                      className={`flex-1 min-w-[140px] p-4 rounded-2xl border transition-all text-left group ${
                        uploadMethod === m.id
                          ? 'bg-[#111827] border-[#0ea5e9] shadow-lg'
                          : 'bg-[#111827] border-white/5 text-gray-500 hover:border-white/20'
                      }`}
                    >
                      <div className={`mb-3 p-2 rounded-lg w-fit transition-colors ${uploadMethod === m.id ? 'bg-[#0ea5e9] text-white' : 'bg-white/5 text-gray-400 group-hover:text-white'}`}>
                        {m.icon}
                      </div>
                      <div className={`text-xs font-black uppercase tracking-tight ${uploadMethod === m.id ? 'text-white' : 'text-gray-400'}`}>{m.label}</div>
                      <div className="text-[9px] mt-1 opacity-60 leading-tight">{m.desc}</div>
                    </button>
                  ))}
                </div>

                <div className="bg-[#111827] rounded-3xl p-8 border border-white/5">
                  {uploadMethod === 'file' && (
                    <div className="flex flex-col items-center justify-center space-y-4">
                        <div className="w-20 h-20 bg-[#0ea5e9]/10 rounded-full flex items-center justify-center text-[#0ea5e9] animate-pulse">
                          <Upload size={40} />
                        </div>
                        <div className="text-center">
                          <h4 className="font-bold text-white">Click to select video file</h4>
                          <p className="text-xs text-gray-500 mt-1">MP4, MKV, AVI, MOV supported</p>
                        </div>
                        <button type="button" className="bg-[#0ea5e9] px-6 py-2 rounded-xl text-white font-black text-sm shadow-lg shadow-[#0ea5e9]/20">BROWSE FILES</button>
                    </div>
                  )}

                  {uploadMethod === 'url' && (
                    <div className="space-y-4">
                      <label className="block text-xs font-black text-gray-500 uppercase tracking-widest">Remote Stream URL</label>
                      <input
                        type="text"
                        placeholder="https://example.com/movie.mp4 or .m3u8"
                        className="w-full bg-[#1f2937] border border-white/10 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-[#0ea5e9]"
                      />
                    </div>
                  )}

                  {uploadMethod === 'multi' && (
                    <div className="space-y-4">
                      {['480p', '720p', '1080p', '4K'].map(quality => (
                        <div key={quality} className="flex items-center space-x-4">
                          <div className="w-16 text-xs font-black text-gray-500 uppercase">{quality}</div>
                          <input
                            type="text"
                            placeholder={`URL for ${quality}`}
                            className="flex-1 bg-[#1f2937] border border-white/10 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-[#0ea5e9]"
                          />
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                <div className="flex items-center justify-between p-6 bg-[#111827] rounded-2xl border border-white/5">
                  <div className="flex items-center space-x-4">
                    <div className="p-3 bg-purple-500/10 text-purple-500 rounded-xl">
                      <ShieldCheck size={24} />
                    </div>
                    <div>
                      <h4 className="text-sm font-black text-white uppercase tracking-tight">DRM Protection</h4>
                      <p className="text-xs text-gray-500">Encrypt video stream with Widevine/Fairplay</p>
                    </div>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input type="checkbox" className="sr-only peer" checked={formData.useDRM} name="useDRM" onChange={handleInputChange} />
                    <div className="w-11 h-6 bg-white/10 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-purple-600"></div>
                  </label>
                </div>
            </div>
          )}

          {activeTab === 'monetization' && (
            <div className="bg-[#1f2937] p-8 rounded-3xl border border-white/5 space-y-8 animate-in fade-in duration-500">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                  <div className="bg-[#111827] p-6 rounded-3xl border border-white/5">
                      <div className="flex items-center justify-between mb-6">
                        <div className="flex items-center space-x-3">
                          <div className="p-2 bg-blue-500/10 text-blue-500 rounded-lg"><Download size={18} /></div>
                          <h4 className="font-bold text-white uppercase tracking-tighter text-sm">Rental Pricing</h4>
                        </div>
                      </div>
                      <div className="space-y-4">
                          <div>
                            <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Price (USD)</label>
                            <input type="number" step="0.01" className="w-full bg-[#1f2937] border border-white/5 rounded-xl px-4 py-2 text-white outline-none" />
                          </div>
                          <div>
                            <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Duration (Hours)</label>
                            <input type="number" className="w-full bg-[#1f2937] border border-white/5 rounded-xl px-4 py-2 text-white outline-none" />
                          </div>
                      </div>
                  </div>
                  <div className="bg-[#111827] p-6 rounded-3xl border border-white/5">
                      <div className="flex items-center justify-between mb-6">
                        <div className="flex items-center space-x-3">
                          <div className="p-2 bg-emerald-500/10 text-emerald-500 rounded-lg"><CheckCircle2 size={18} /></div>
                          <h4 className="font-bold text-white uppercase tracking-tighter text-sm">Purchase Pricing</h4>
                        </div>
                      </div>
                      <div className="space-y-4">
                          <div>
                            <label className="block text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Price (USD)</label>
                            <input type="number" step="0.01" className="w-full bg-[#1f2937] border border-white/5 rounded-xl px-4 py-2 text-white outline-none" />
                          </div>
                          <div className="p-3 bg-[#1f2937] rounded-xl border border-white/5 mt-auto">
                            <p className="text-[10px] text-gray-500 leading-tight">Purchased items are added to user's permanent library with no expiration.</p>
                          </div>
                      </div>
                  </div>
                </div>

                <div className="flex items-center justify-between p-6 bg-[#111827] rounded-2xl border border-white/5">
                  <div className="flex items-center space-x-4">
                    <div className="p-3 bg-amber-500/10 text-amber-500 rounded-xl">
                      <CreditCard size={24} />
                    </div>
                    <div>
                      <h4 className="text-sm font-black text-white uppercase tracking-tight">Premium Only</h4>
                      <p className="text-xs text-gray-500">Only accessible to users with active subscription</p>
                    </div>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input type="checkbox" className="sr-only peer" checked={formData.premiumOnly} name="premiumOnly" onChange={handleInputChange} />
                    <div className="w-11 h-6 bg-white/10 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-amber-500"></div>
                  </label>
                </div>
            </div>
          )}

          {activeTab === 'settings' && (
            <div className="bg-[#1f2937] p-8 rounded-3xl border border-white/5 space-y-8 animate-in fade-in duration-500">
                <div className="grid grid-cols-2 gap-4">
                  {['Public', 'Draft', 'Coming Soon'].map(status => (
                    <button
                      key={status}
                      type="button"
                      onClick={() => setFormData({...formData, status})}
                      className={`p-6 rounded-2xl border text-left transition-all ${
                        formData.status === status
                          ? 'bg-[#111827] border-[#0ea5e9] ring-2 ring-[#0ea5e9]/20'
                          : 'bg-[#111827] border-white/5 text-gray-500 hover:border-white/10'
                      }`}
                    >
                      <div className={`text-xs font-black uppercase tracking-widest ${formData.status === status ? 'text-[#0ea5e9]' : 'text-gray-600'}`}>{status}</div>
                      <div className="text-[10px] mt-1 opacity-60">
                        {status === 'Public' ? 'Available to all users immediately.' : status === 'Draft' ? 'Saved for later editing.' : 'Show in "Coming Soon" section.'}
                      </div>
                    </button>
                  ))}
                </div>

                <div className="space-y-4">
                  <div className="flex items-center justify-between p-4 bg-[#111827] rounded-2xl border border-white/5 hover:bg-white/[0.02] transition-colors">
                    <div className="flex items-center space-x-3">
                      <Plus className="text-[#0ea5e9]" size={20} />
                      <span className="text-sm font-bold text-gray-300">Allow user downloads</span>
                    </div>
                    <input type="checkbox" checked={formData.isDownloadable} name="isDownloadable" onChange={handleInputChange} className="w-5 h-5 rounded border-white/10 bg-[#1f2937] text-[#0ea5e9] focus:ring-[#0ea5e9]" />
                  </div>
                  <div className="flex items-center justify-between p-4 bg-[#111827] rounded-2xl border border-white/5 hover:bg-white/[0.02] transition-colors">
                    <div className="flex items-center space-x-3">
                      <Plus className="text-rose-500" size={20} />
                      <span className="text-sm font-bold text-gray-300">Mark as Featured (Hero Slider)</span>
                    </div>
                    <input type="checkbox" checked={formData.isFeatured} name="isFeatured" onChange={handleInputChange} className="w-5 h-5 rounded border-white/10 bg-[#1f2937] text-rose-500 focus:ring-rose-500" />
                  </div>
                  <div className="flex items-center justify-between p-4 bg-[#111827] rounded-2xl border border-white/5 hover:bg-white/[0.02] transition-colors">
                    <div className="flex items-center space-x-3">
                      <Plus className="text-purple-500" size={20} />
                      <span className="text-sm font-bold text-gray-300">RIYOBOX Original Badge</span>
                    </div>
                    <input type="checkbox" checked={formData.isOriginal} name="isOriginal" onChange={handleInputChange} className="w-5 h-5 rounded border-white/10 bg-[#1f2937] text-purple-500 focus:ring-purple-500" />
                  </div>
                  <div className="flex items-center justify-between p-4 bg-purple-500/10 rounded-2xl border border-purple-500/20 hover:bg-purple-500/20 transition-colors">
                    <div className="flex items-center space-x-3">
                      <Tv className="text-purple-500" size={20} />
                      <span className="text-sm font-black text-white uppercase tracking-tighter">Is TV Series / Show</span>
                    </div>
                    <input type="checkbox" checked={formData.isTvShow} name="isTvShow" onChange={handleInputChange} className="w-6 h-6 rounded-lg border-white/10 bg-[#1f2937] text-purple-500 focus:ring-purple-500" />
                  </div>
                </div>

                <div className="bg-red-500/5 border border-red-500/20 p-6 rounded-2xl">
                    <div className="flex items-start space-x-3">
                      <AlertCircle className="text-red-500 mt-1" size={20} />
                      <div>
                        <h4 className="text-sm font-black text-white uppercase tracking-tight">Content Warnings</h4>
                        <p className="text-xs text-gray-500 mt-1">Ensure the content complies with local censorship laws. Incorrect categorization may lead to platform removal.</p>
                      </div>
                    </div>
                </div>
            </div>
          )}

        </div>

        {/* Sidebar/Preview Area */}
        <div className="space-y-8">
            <div className="bg-[#1f2937] rounded-3xl border border-white/5 overflow-hidden shadow-2xl">
              <div className="aspect-[2/3] bg-[#111827] relative">
                {formData.posterUrl ? (
                  <img src={formData.posterUrl} className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center flex-col text-gray-700">
                    <ImageIcon size={64} className="mb-4" />
                    <span className="text-xs font-black uppercase">Poster Preview</span>
                  </div>
                )}
                {formData.isOriginal && (
                  <div className="absolute top-4 left-4 bg-purple-600 text-white text-[8px] font-black px-2 py-1 rounded uppercase tracking-tighter">Original</div>
                )}
                {formData.contentRating && (
                  <div className="absolute top-4 right-4 bg-black/60 backdrop-blur px-2 py-1 rounded text-[10px] font-bold text-white border border-white/20">{formData.contentRating}</div>
                )}
              </div>
              <div className="p-6 bg-gradient-to-t from-[#111827] to-[#1f2937]">
                <h4 className="text-lg font-black text-white leading-tight mb-1">{formData.title || 'Movie Title'}</h4>
                <div className="flex items-center space-x-2 text-[10px] text-gray-500 font-bold">
                  <span>{formData.year}</span>
                  <span>•</span>
                  <span>{formData.duration || '--'}</span>
                  <span>•</span>
                  <span className="text-purple-400 uppercase">{formData.language}</span>
                </div>
                <div className="flex flex-wrap gap-1 mt-3">
                  {formData.genres.slice(0, 3).map(g => (
                    <span key={g} className="text-[8px] bg-white/5 border border-white/10 px-2 py-0.5 rounded text-gray-400">{g}</span>
                  ))}
                </div>
              </div>
            </div>

            <div className="bg-[#1f2937] p-6 rounded-3xl border border-white/5">
                <h4 className="text-xs font-black text-white uppercase tracking-widest mb-4">Step Progress</h4>
                <div className="space-y-4">
                  {tabs.map((tab, i) => (
                    <div key={tab.id} className="flex items-center">
                      <div className={`w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold mr-3 ${
                        activeTab === tab.id ? 'bg-[#0ea5e9] text-white shadow-lg shadow-[#0ea5e9]/20' : 'bg-[#111827] text-gray-600'
                      }`}>
                        {i + 1}
                      </div>
                      <span className={`text-xs font-bold ${activeTab === tab.id ? 'text-white' : 'text-gray-500'}`}>{tab.label}</span>
                    </div>
                  ))}
                </div>
            </div>

            <button
              type="button"
              onClick={() => {
                const currentIndex = tabs.findIndex(t => t.id === activeTab);
                if (currentIndex < tabs.length - 1) setActiveTab(tabs[currentIndex + 1].id);
              }}
              className="w-full bg-[#374151] hover:bg-[#4b5563] text-white font-black py-4 rounded-2xl transition-all flex items-center justify-center group"
            >
              <span>CONTINUE</span>
              <ArrowRight size={18} className="ml-2 group-hover:translate-x-1 transition-transform" />
            </button>
        </div>
      </form>
    </div>
  );
};

export default AddMovie;
