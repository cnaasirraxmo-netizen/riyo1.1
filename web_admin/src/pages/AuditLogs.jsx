
import React, { useState, useEffect } from 'react';
import { Shield, Search, Filter, Download, User, Calendar, ExternalLink } from 'lucide-react';
import api from '../utils/api';

const AuditLogs = () => {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  const fetchLogs = async () => {
    try {
      const res = await api.get('/logs');
      setLogs(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, []);

  const getActionColor = (action) => {
    if (action.includes('DELETE')) return 'text-rose-500 bg-rose-500/10';
    if (action.includes('CREATE') || action.includes('ADD')) return 'text-emerald-500 bg-emerald-500/10';
    if (action.includes('UPDATE')) return 'text-[#0ea5e9] bg-[#0ea5e9]/10';
    return 'text-gray-500 bg-gray-500/10';
  };

  const filteredLogs = logs.filter(log =>
    log.action?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    log.admin?.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    log.module?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="p-8 pb-24">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-8">
        <div>
          <h1 className="text-3xl font-black text-white uppercase tracking-tight flex items-center">
            <Shield size={32} className="mr-3 text-[#0ea5e9]" /> Security Audit Logs
          </h1>
          <p className="text-gray-400 mt-1 font-medium">Track administrative actions and system security events.</p>
        </div>
        <button className="bg-white/5 border border-white/10 text-white px-6 py-3 rounded-2xl font-black flex items-center hover:bg-white/10 transition-all">
          <Download size={20} className="mr-2" /> EXPORT PDF/CSV
        </button>
      </div>

      <div className="bg-[#1f2937] p-4 rounded-2xl border border-white/5 mb-8 flex flex-col md:flex-row gap-4 items-center shadow-xl">
        <div className="relative flex-1 w-full">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500" size={18} />
          <input
            type="text"
            placeholder="Search by action, admin, or module..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-[#111827] border border-white/10 rounded-xl pl-12 pr-4 py-3 text-sm text-white focus:outline-none focus:border-[#0ea5e9]"
          />
        </div>
        <button className="flex items-center space-x-2 bg-[#111827] border border-white/10 px-6 py-3 rounded-xl text-gray-400 hover:text-white transition-colors">
          <Filter size={18} />
          <span className="text-sm font-bold uppercase tracking-widest">Filter</span>
        </button>
      </div>

      <div className="bg-[#1f2937] rounded-3xl border border-white/5 overflow-hidden shadow-2xl">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-[#111827] text-gray-500 text-[10px] font-black uppercase tracking-widest border-b border-white/5">
              <th className="px-6 py-5">Administrator</th>
              <th className="px-6 py-5">Action</th>
              <th className="px-6 py-5">Module</th>
              <th className="px-6 py-5">Target ID</th>
              <th className="px-6 py-5">IP Address</th>
              <th className="px-6 py-5">Timestamp</th>
              <th className="px-6 py-5 text-right">Details</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/5">
            {loading ? (
              <tr>
                <td colSpan="7" className="px-6 py-10 text-center text-gray-500 italic">Accessing secure logs...</td>
              </tr>
            ) : filteredLogs.length === 0 ? (
              <tr>
                <td colSpan="7" className="px-6 py-10 text-center text-gray-500">No logs found matching your criteria.</td>
              </tr>
            ) : filteredLogs.map((log) => (
              <tr key={log._id} className="hover:bg-white/[0.01] transition-colors group">
                <td className="px-6 py-5">
                   <div className="flex items-center space-x-3">
                      <div className="w-8 h-8 bg-[#0ea5e9]/20 text-[#0ea5e9] rounded-lg flex items-center justify-center font-black text-xs">
                        {log.admin?.name?.charAt(0)}
                      </div>
                      <div>
                        <div className="font-bold text-white text-sm">{log.admin?.name}</div>
                        <div className="text-[10px] text-gray-500 uppercase font-black">{log.admin?.role}</div>
                      </div>
                   </div>
                </td>
                <td className="px-6 py-5">
                   <span className={`px-2 py-1 rounded text-[9px] font-black uppercase tracking-tighter ${getActionColor(log.action)}`}>
                     {log.action}
                   </span>
                </td>
                <td className="px-6 py-5 text-gray-300 text-xs font-bold uppercase tracking-widest">{log.module}</td>
                <td className="px-6 py-5">
                   <div className="flex items-center text-gray-500 font-mono text-[10px]">
                      {log.targetId ? log.targetId.slice(-8).toUpperCase() : 'N/A'}
                      {log.targetId && <ExternalLink size={10} className="ml-1 opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer" />}
                   </div>
                </td>
                <td className="px-6 py-5 text-gray-400 text-xs font-mono">{log.ipAddress || '127.0.0.1'}</td>
                <td className="px-6 py-5">
                   <div className="flex items-center text-gray-400 text-xs font-medium">
                      <Calendar size={12} className="mr-1 text-gray-600" />
                      {new Date(log.createdAt).toLocaleString()}
                   </div>
                </td>
                <td className="px-6 py-5 text-right">
                   <button className="text-[10px] font-black text-gray-500 hover:text-white uppercase tracking-tighter">VIEW DETAILS</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default AuditLogs;
