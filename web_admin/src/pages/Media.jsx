import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import { Video, Image as ImageIcon, Trash2, ExternalLink, HardDrive, Search, Filter, ArrowUpRight, FileText, Download } from 'lucide-react';

const Media = () => {
  const [files, setFiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  const fetchFiles = async () => {
    setLoading(true);
    try {
      const res = await api.get('/upload');
      setFiles(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFiles();
  }, []);

  const handleDelete = async (key) => {
    if (!window.confirm('IRREVERSIBLE ACTION: Are you sure you want to purge this object from R2 storage?')) return;
    try {
      await api.delete(`/upload/${key}`);
      fetchFiles();
    } catch (err) {
      alert('Deletion failed. Verify object permissions.');
    }
  };

  const filteredFiles = files.filter(f =>
    f.key.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const totalSize = files.reduce((acc, curr) => acc + curr.size, 0);

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h1 className="text-4xl font-black text-white tracking-tight">R2 Data Assets</h1>
          <p className="text-gray-400 text-lg mt-1">Direct interface with Cloudflare storage infrastructure.</p>
        </div>
        <div className="flex items-center gap-4">
          <div className="relative group">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 group-focus-within:text-purple-500 transition-colors" size={20} />
            <input
              type="text"
              placeholder="Query object key..."
              className="bg-[#1C1C1C] border border-white/5 rounded-2xl pl-12 pr-6 py-3 text-sm focus:outline-none focus:border-purple-500 transition-all w-64"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          <button
            onClick={fetchFiles}
            className="bg-white/5 hover:bg-white/10 text-white px-6 py-3 rounded-2xl font-black text-xs uppercase tracking-widest transition-all border border-white/5 active:scale-95 flex items-center gap-2"
          >
            <Filter size={16} />
            REFINE
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="md:col-span-1 bg-[#1C1C1C] p-8 rounded-[32px] border border-white/5 flex flex-col justify-between relative overflow-hidden group">
          <div className="absolute -right-4 -bottom-4 opacity-5 group-hover:scale-110 transition-transform duration-500">
            <HardDrive size={160} />
          </div>
          <div>
            <p className="text-gray-500 text-[10px] font-black uppercase tracking-widest">Total Storage</p>
            <h3 className="text-4xl font-black text-white mt-2 tracking-tighter">{(totalSize / (1024 * 1024 * 1024)).toFixed(2)} <span className="text-xl text-gray-600">GB</span></h3>
          </div>
          <div className="mt-8 pt-8 border-t border-white/5">
            <p className="text-gray-500 text-[10px] font-black uppercase tracking-widest">Object Count</p>
            <h3 className="text-2xl font-black text-white mt-1">{files.length}</h3>
          </div>
        </div>

        <div className="md:col-span-3 bg-[#1C1C1C] rounded-[40px] border border-white/5 overflow-hidden shadow-2xl relative">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-black/20 text-gray-500 text-[10px] font-black uppercase tracking-[0.2em]">
                  <th className="px-10 py-6 border-b border-white/5">Object Identity</th>
                  <th className="px-10 py-6 border-b border-white/5">Payload Size</th>
                  <th className="px-10 py-6 border-b border-white/5">Modification</th>
                  <th className="px-10 py-6 border-b border-white/5 text-right">Operational Logic</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {loading ? (
                  <tr>
                    <td colSpan="4" className="px-10 py-32 text-center">
                      <div className="flex flex-col items-center space-y-4">
                        <div className="w-10 h-10 border-2 border-purple-600 border-t-transparent rounded-full animate-spin"></div>
                        <span className="text-gray-500 font-bold uppercase tracking-widest text-[10px]">Establishing Secure Buffer...</span>
                      </div>
                    </td>
                  </tr>
                ) : filteredFiles.length === 0 ? (
                  <tr>
                    <td colSpan="4" className="px-10 py-20 text-center text-gray-500 font-bold uppercase tracking-widest text-xs italic">
                      Zero objects detected in the current namespace.
                    </td>
                  </tr>
                ) : filteredFiles.map((file) => (
                  <tr key={file.key} className="hover:bg-white/[0.02] transition-colors group">
                    <td className="px-10 py-6">
                      <div className="flex items-center gap-4">
                        <div className="w-12 h-12 rounded-2xl bg-white/5 border border-white/5 flex items-center justify-center text-gray-400 group-hover:bg-purple-600 group-hover:text-white transition-all duration-300">
                          {file.key.toString().toLowerCase().endsWith('.mp4') ? <Video size={18} /> :
                           file.key.toString().toLowerCase().match(/\.(jpg|jpeg|png|webp)$/) ? <ImageIcon size={18} /> :
                           <FileText size={18} />}
                        </div>
                        <div className="flex flex-col max-w-xs xl:max-w-md">
                          <span className="text-white font-bold text-sm truncate">{file.key}</span>
                          <a href={file.url} target="_blank" rel="noreferrer" className="text-purple-500 text-[10px] font-black uppercase tracking-tighter mt-1 hover:text-purple-400 flex items-center gap-1">
                            SOURCE URL <ArrowUpRight size={10} />
                          </a>
                        </div>
                      </div>
                    </td>
                    <td className="px-10 py-6">
                      <span className="text-gray-400 font-mono text-xs font-bold">
                        {(file.size / (1024 * 1024)).toFixed(2)} MB
                      </span>
                    </td>
                    <td className="px-10 py-6">
                      <span className="text-gray-500 font-bold text-[10px] uppercase tracking-tighter">
                        {new Date(file.lastModified).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })}
                      </span>
                    </td>
                    <td className="px-10 py-6 text-right">
                       <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                          <a
                            href={file.url}
                            download
                            className="p-3 rounded-2xl bg-white/5 text-gray-400 hover:text-white hover:bg-white/10 transition-all"
                            title="Download Object"
                          >
                            <Download size={18} />
                          </a>
                          <button
                            onClick={() => handleDelete(file.key)}
                            className="p-3 rounded-2xl bg-white/5 text-red-500 hover:bg-red-500/10 transition-all"
                            title="Purge Object"
                          >
                            <Trash2 size={18} />
                          </button>
                       </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Media;
