import React, { useState } from 'react';
import api from '../utils/api';
import { Send, Bell, Smartphone, ShieldCheck, AlertTriangle, History, X } from 'lucide-react';

const Notifications = () => {
  const [formData, setFormData] = useState({ title: '', body: '' });
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setStatus(null);
    try {
      await api.post('/admin/notify', formData);
      setStatus({ type: 'success', message: 'Transmission Successful. Notification has been synchronized with Firebase Cloud Messaging.' });
      setFormData({ title: '', body: '' });
    } catch (err) {
      setStatus({ type: 'error', message: 'Transmission Failure. Please verify server connectivity and API credentials.' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h1 className="text-4xl font-black text-white tracking-tight">Signal Broadcast</h1>
          <p className="text-gray-400 text-lg mt-1">Direct communication channel with active nodes.</p>
        </div>
        <div className="flex items-center gap-2 bg-white/5 px-4 py-2 rounded-2xl border border-white/5">
          <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
          <span className="text-[10px] font-black uppercase tracking-[0.2em] text-gray-500">FCM STATUS: OPERATIONAL</span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-8">
        <div className="lg:col-span-3">
          <div className="bg-[#1C1C1C] rounded-[40px] border border-white/5 overflow-hidden shadow-2xl relative">
            <div className="p-10 border-b border-white/5 flex items-center justify-between bg-black/20">
              <div className="flex items-center gap-4">
                <div className="p-3 bg-purple-600/20 rounded-2xl text-purple-500">
                  <Send size={24} />
                </div>
                <h2 className="text-xl font-black uppercase tracking-tighter">Payload Configuration</h2>
              </div>
              <button className="text-gray-600 hover:text-white transition-colors">
                <History size={20} />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="p-10 space-y-8">
              <div className="space-y-2">
                <label className="text-[10px] font-black text-gray-500 uppercase tracking-widest ml-1">Broadcast Header</label>
                <input
                  required
                  className="w-full bg-black/40 border border-white/5 rounded-2xl px-6 py-4 text-sm text-white focus:outline-none focus:border-purple-500 transition-all"
                  placeholder="e.g. SYSTEM UPDATE AVAILABLE"
                  value={formData.title}
                  onChange={(e) => setFormData({...formData, title: e.target.value})}
                />
              </div>

              <div className="space-y-2">
                <label className="text-[10px] font-black text-gray-500 uppercase tracking-widest ml-1">Data Payload (Body)</label>
                <textarea
                  required
                  rows="6"
                  className="w-full bg-black/40 border border-white/5 rounded-2xl px-6 py-4 text-sm text-white focus:outline-none focus:border-purple-500 transition-all resize-none"
                  placeholder="Enter detailed broadcast information..."
                  value={formData.body}
                  onChange={(e) => setFormData({...formData, body: e.target.value})}
                />
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-700 hover:to-indigo-700 text-white py-5 rounded-3xl font-black text-sm uppercase tracking-widest transition-all shadow-2xl shadow-purple-600/30 active:scale-[0.98] disabled:opacity-50 flex items-center justify-center gap-3"
              >
                {loading ? (
                  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                ) : (
                  <>
                    <Smartphone size={18} />
                    EXECUTE BROADCAST
                  </>
                )}
              </button>
            </form>

            {status && (
              <div className={`m-10 p-6 rounded-3xl border animate-in slide-in-from-bottom-4 duration-300 flex items-center justify-between ${
                status.type === 'success' ? 'bg-green-500/10 border-green-500/20 text-green-500' : 'bg-red-500/10 border-red-500/20 text-red-500'
              }`}>
                <div className="flex items-center gap-4">
                  {status.type === 'success' ? <ShieldCheck size={20} /> : <AlertTriangle size={20} />}
                  <span className="text-xs font-bold uppercase tracking-tight">{status.message}</span>
                </div>
                <button onClick={() => setStatus(null)} className="opacity-50 hover:opacity-100 transition-opacity">
                  <X size={16} />
                </button>
              </div>
            )}
          </div>
        </div>

        <div className="lg:col-span-2 space-y-8">
          <div className="bg-[#1C1C1C] rounded-[40px] border border-white/5 p-10 shadow-2xl">
             <h3 className="text-xl font-black text-white uppercase tracking-tighter mb-8">System Preview</h3>

             <div className="max-w-[280px] mx-auto bg-[#262626] rounded-[32px] p-2 border border-white/10 shadow-inner relative overflow-hidden group">
                <div className="bg-black rounded-[24px] aspect-[9/16] relative overflow-hidden flex flex-col items-center p-6">
                   <div className="w-20 h-1 bg-white/20 rounded-full mb-8"></div>

                   <div className="w-full bg-white/10 backdrop-blur-md rounded-2xl p-4 animate-bounce-slow border border-white/10">
                      <div className="flex items-center gap-2 mb-1">
                        <div className="w-4 h-4 bg-purple-600 rounded flex items-center justify-center text-[8px] font-black italic">R</div>
                        <span className="text-[8px] font-black text-white/50 uppercase tracking-widest">RIYOBOX</span>
                      </div>
                      <h4 className="text-[10px] font-bold text-white truncate">{formData.title || 'Notification Preview'}</h4>
                      <p className="text-[9px] text-gray-400 mt-0.5 line-clamp-2">{formData.body || 'Message content will appear here...'}</p>
                   </div>

                   <div className="absolute bottom-6 w-1 h-1 bg-white/40 rounded-full"></div>
                </div>
             </div>

             <div className="mt-10 space-y-4">
                <div className="flex items-start gap-4 p-4 bg-white/5 rounded-2xl border border-white/5">
                   <Info size={18} className="text-blue-500 mt-0.5" />
                   <p className="text-[10px] text-gray-500 font-medium leading-relaxed uppercase">
                     Signals are processed via Firebase and delivered to all registered tokens globally.
                   </p>
                </div>
             </div>
          </div>

          <div className="bg-gradient-to-br from-yellow-600/20 to-orange-600/20 rounded-[40px] border border-yellow-600/30 p-10 relative overflow-hidden group">
            <div className="absolute top-0 right-0 p-8 opacity-10 group-hover:scale-110 transition-transform duration-500">
              <AlertTriangle size={80} className="text-yellow-500" />
            </div>
            <h3 className="text-xl font-black text-yellow-500 uppercase tracking-tighter mb-4">Integrity Warning</h3>
            <p className="text-xs text-yellow-600/80 leading-relaxed font-bold uppercase tracking-tight">
              High-frequency broadcasting may lead to device-level suppression. Ensure data value before execution.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Notifications;
