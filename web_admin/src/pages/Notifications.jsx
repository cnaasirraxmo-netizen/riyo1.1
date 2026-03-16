import React, { useState, useEffect } from 'react';
import { Bell, Send, History, CheckCircle, XCircle } from 'lucide-react';
import api from '../utils/api';

const Notifications = () => {
  const [target, setTarget] = useState('all');
  const [userIds, setUserIds] = useState('');
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [history, setHistory] = useState([]);
  const [status, setStatus] = useState(null);

  useEffect(() => {
    fetchHistory();
  }, []);

  const fetchHistory = async () => {
    try {
      const response = await api.get('/admin/notifications/history');
      setHistory(response.data);
    } catch (error) {
      console.error('Failed to fetch history:', error);
    }
  };

  const handleSend = async (e) => {
    e.preventDefault();
    setLoading(true);
    setStatus(null);

    try {
      const payload = {
        target,
        title,
        message,
        userIds: target === 'specific' ? userIds.split(',').map(id => id.trim()) : []
      };

      await api.post('/admin/notifications', payload);
      setStatus({ type: 'success', text: 'Notification sent successfully!' });
      setTitle('');
      setMessage('');
      setUserIds('');
      fetchHistory();
    } catch (error) {
      setStatus({ type: 'error', text: error.response?.data?.message || 'Failed to send notification' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-[#1d2327]">Notification Management</h1>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="admin-card">
          <h2 className="text-lg font-bold mb-6 flex items-center gap-2">
            <Send size={20} /> Send Push Notification
          </h2>

          {status && (
            <div className={`p-4 rounded-md mb-4 flex items-center gap-2 ${status.type === 'success' ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'}`}>
              {status.type === 'success' ? <CheckCircle size={18} /> : <XCircle size={18} />}
              {status.text}
            </div>
          )}

          <form onSubmit={handleSend} className="space-y-4">
            <div>
              <label className="block text-sm font-bold mb-1">Target Audience</label>
              <select
                className="input-field w-full"
                value={target}
                onChange={(e) => setTarget(e.target.value)}
              >
                <option value="all">All Users</option>
                <option value="specific">Specific Users (by UID)</option>
              </select>
            </div>

            {target === 'specific' && (
              <div>
                <label className="block text-sm font-bold mb-1">User IDs (comma separated)</label>
                <input
                  type="text"
                  className="input-field w-full"
                  placeholder="e.g. 60d5ecb3, 60d5ecb4"
                  value={userIds}
                  onChange={(e) => setUserIds(e.target.value)}
                  required
                />
              </div>
            )}

            <div>
              <label className="block text-sm font-bold mb-1">Notification Title</label>
              <input
                type="text"
                className="input-field w-full"
                placeholder="e.g. New Movie Released!"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                required
              />
            </div>

            <div>
              <label className="block text-sm font-bold mb-1">Message Body</label>
              <textarea
                className="input-field w-full h-24"
                placeholder="Enter notification message..."
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                required
              ></textarea>
            </div>

            <button
              type="submit"
              className="btn-primary w-full justify-center"
              disabled={loading}
            >
              {loading ? 'Sending...' : <Send size={18} />}
              {!loading && "Send Notification Now"}
            </button>
          </form>
        </div>

        <div className="admin-card">
          <h2 className="text-lg font-bold mb-6 flex items-center gap-2">
            <History size={20} /> Notification History
          </h2>
          <div className="space-y-4 max-h-[500px] overflow-y-auto">
            {history.length === 0 ? (
              <p className="text-gray-500 text-center py-4">No notification history found.</p>
            ) : (
              history.map((item) => (
                <div key={item._id} className="border-b pb-3 last:border-0">
                  <div className="flex justify-between items-start mb-1">
                    <h3 className="font-bold text-sm">{item.title}</h3>
                    <span className="text-[10px] text-gray-400">
                      {new Date(item.createdAt).toLocaleString()}
                    </span>
                  </div>
                  <p className="text-xs text-gray-600 mb-1">{item.message}</p>
                  <div className="flex gap-2">
                    <span className={`text-[10px] px-2 py-0.5 rounded-full ${item.status === 'sent' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                      {item.status}
                    </span>
                    <span className="text-[10px] px-2 py-0.5 rounded-full bg-blue-100 text-blue-700">
                      {item.type}
                    </span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Notifications;
