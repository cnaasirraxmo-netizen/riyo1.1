import React, { useState } from 'react';
import api from '../utils/api';
import { Send } from 'lucide-react';

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
      setStatus({ type: 'success', message: 'Notification broadcasted successfully!' });
      setFormData({ title: '', body: '' });
    } catch (err) {
      setStatus({ type: 'error', message: 'Failed to send notification.' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-2xl">
      <div className="mb-8">
        <h1 className="text-3xl font-bold">Push Notifications</h1>
        <p className="text-gray-400">Send manual announcements to all registered devices.</p>
      </div>

      {status && (
        <div className={`p-4 rounded-lg mb-6 border ${
          status.type === 'success' ? 'bg-green-500/10 border-green-500/50 text-green-500' : 'bg-red-500/10 border-red-500/50 text-red-500'
        }`}>
          {status.message}
        </div>
      )}

      <form onSubmit={handleSubmit} className="bg-[#1C1C1C] p-8 rounded-2xl border border-white/5 space-y-6">
        <div>
          <label className="block text-sm font-medium text-gray-400 mb-2">Notification Title</label>
          <input
            required
            className="w-full bg-[#262626] border border-white/10 rounded-lg px-4 py-3 focus:outline-none focus:border-purple-500 transition-colors text-white"
            placeholder="e.g. Weekend Special! 🍿"
            value={formData.title}
            onChange={(e) => setFormData({...formData, title: e.target.value})}
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-400 mb-2">Message Body</label>
          <textarea
            required
            rows="4"
            className="w-full bg-[#262626] border border-white/10 rounded-lg px-4 py-3 focus:outline-none focus:border-purple-500 transition-colors text-white"
            placeholder="Write your message here..."
            value={formData.body}
            onChange={(e) => setFormData({...formData, body: e.target.value})}
          />
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-purple-600 hover:bg-purple-700 text-white font-bold py-4 rounded-xl transition-all flex items-center justify-center disabled:opacity-50"
        >
          {loading ? 'SENDING...' : (
            <>
              <Send size={18} className="mr-2" /> BROADCAST NOTIFICATION
            </>
          )}
        </button>
      </form>

      <div className="mt-12 p-6 bg-yellow-500/5 border border-yellow-500/10 rounded-xl">
         <h3 className="text-yellow-500 font-bold mb-2 flex items-center">
           <span className="mr-2">⚠️</span> IMPORTANT NOTICE
         </h3>
         <p className="text-xs text-gray-500 leading-relaxed">
           Push notifications are sent instantly to all active devices. Use this feature sparingly to avoid being flagged as spam by mobile OS providers. Content should be relevant and engaging.
         </p>
      </div>
    </div>
  );
};

export default Notifications;
