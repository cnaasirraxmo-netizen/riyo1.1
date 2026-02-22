import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import { User, Mail, Calendar, Smartphone, Shield, CreditCard, Activity, Clock, Trash2, Ban, ArrowUpCircle, Bell, DollarSign, X } from 'lucide-react';

const ROLES = ['user', 'admin', 'super-admin', 'content-admin', 'support-admin', 'analytics-admin', 'moderator'];
const PERMISSIONS = [
  { key: 'manage_movies', label: 'Manage Movies' },
  { key: 'manage_users', label: 'Manage Users' },
  { key: 'manage_settings', label: 'Manage Settings' },
  { key: 'manage_admins', label: 'Manage Admins' },
  { key: 'view_analytics', label: 'View Analytics' },
  { key: 'financial_access', label: 'Financial Access' },
];

const Users = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDetailOpen, setIsDetailOpen] = useState(false);

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const res = await api.get('/admin/users');
        setUsers(res.data);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const res = await api.get('/admin/users');
      setUsers(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateRole = async (userId, role) => {
    try {
      await api.put(`/admin/users/${userId}/role`, { role });
      fetchUsers();
    } catch (err) {
      alert('Error updating role');
    }
  };

  const handleUpdatePermissions = async (userId, permissions) => {
    try {
      await api.put(`/admin/users/${userId}/permissions`, { permissions });
      fetchUsers();
      setIsModalOpen(false);
    } catch (err) {
      alert('Error updating permissions');
    }
  };

  const handleUserAction = async (action, userId) => {
    if (!window.confirm(`Are you sure you want to perform ${action}?`)) return;
    try {
      await api.post(`/admin/users/${userId}/action`, { action });
      fetchUsers();
    } catch (err) {
      alert(`Action ${action} failed`);
    }
  };

  return (
    <div className="p-8 pb-24">
      <div className="mb-8">
        <h1 className="text-3xl font-bold">User Management</h1>
        <p className="text-gray-400">View and manage application users.</p>
      </div>

      <div className="bg-[#1C1C1C] rounded-xl border border-white/5 overflow-hidden">
        <table className="w-full text-left">
          <thead>
            <tr className="bg-[#262626] text-gray-400 text-sm uppercase tracking-wider">
              <th className="px-6 py-4 font-medium">Name</th>
              <th className="px-6 py-4 font-medium">Email</th>
              <th className="px-6 py-4 font-medium">Role</th>
              <th className="px-6 py-4 font-medium">Joined</th>
              <th className="px-6 py-4 font-medium">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/5">
            {loading ? (
              <tr>
                <td colSpan="5" className="px-6 py-10 text-center text-gray-500 italic">Fetching user data...</td>
              </tr>
            ) : users.map((user) => (
              <tr key={user._id} className="hover:bg-white/[0.02] transition-colors">
                <td className="px-6 py-4 font-medium cursor-pointer hover:text-[#0ea5e9] transition-colors" onClick={() => { setSelectedUser(user); setIsDetailOpen(true); }}>{user.name}</td>
                <td className="px-6 py-4 text-gray-400">{user.email}</td>
                <td className="px-6 py-4">
                  <span className={`px-2 py-1 rounded text-[10px] font-bold uppercase ${
                    user.role === 'admin' ? 'bg-purple-500/20 text-purple-400' : 'bg-blue-500/20 text-blue-400'
                  }`}>
                    {user.role}
                  </span>
                </td>
                <td className="px-6 py-4 text-gray-500 text-sm">
                  {new Date(user.createdAt).toLocaleDateString()}
                </td>
                <td className="px-6 py-4">
                   <select
                     value={user.role}
                     onChange={(e) => handleUpdateRole(user._id, e.target.value)}
                     className="bg-[#262626] border border-white/10 rounded text-xs px-2 py-1 outline-none focus:border-purple-500"
                   >
                     {ROLES.map(role => <option key={role} value={role}>{role}</option>)}
                   </select>
                </td>
                <td className="px-6 py-4 text-gray-500 text-sm">
                  {new Date(user.createdAt).toLocaleDateString()}
                </td>
                <td className="px-6 py-4">
                   <button
                     onClick={() => { setSelectedUser(user); setIsModalOpen(true); }}
                     className="text-purple-500 hover:text-purple-400 mr-4 text-sm"
                   >
                     Permissions
                   </button>
                   <button className="text-red-500/50 hover:text-red-500 text-sm">Suspend</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {isDetailOpen && selectedUser && (
        <div className="fixed inset-0 bg-black/90 backdrop-blur-md flex items-center justify-center p-8 z-50">
           <div className="bg-[#1f2937] border border-white/10 rounded-3xl max-w-5xl w-full h-[80vh] overflow-hidden flex flex-col shadow-2xl animate-in fade-in zoom-in-95">
              <div className="p-6 border-b border-white/5 bg-[#111827] flex justify-between items-center">
                 <div className="flex items-center space-x-4">
                    <div className="w-12 h-12 bg-[#0ea5e9] rounded-2xl flex items-center justify-center text-white font-black text-xl shadow-lg shadow-[#0ea5e9]/20">{selectedUser.name?.charAt(0)}</div>
                    <div>
                       <h2 className="text-xl font-black text-white uppercase tracking-tight">{selectedUser.name}</h2>
                       <p className="text-xs text-gray-500 font-bold uppercase tracking-widest">User ID: {selectedUser._id}</p>
                    </div>
                 </div>
                 <button onClick={() => setIsDetailOpen(false)} className="p-2 text-gray-500 hover:text-white transition-colors"><X size={24} /></button>
              </div>

              <div className="flex-1 overflow-y-auto custom-scrollbar p-8">
                 <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                    {/* Left: Info Cards */}
                    <div className="space-y-6">
                       <div className="bg-[#111827] p-6 rounded-2xl border border-white/5">
                          <h3 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-4">Account Summary</h3>
                          <div className="space-y-4">
                             <div className="flex items-center text-sm"><Mail size={14} className="mr-3 text-gray-600" /> <span className="text-gray-300">{selectedUser.email}</span></div>
                             <div className="flex items-center text-sm"><Smartphone size={14} className="mr-3 text-gray-600" /> <span className="text-gray-300">{selectedUser.phone || 'No phone linked'}</span></div>
                             <div className="flex items-center text-sm"><Calendar size={14} className="mr-3 text-gray-600" /> <span className="text-gray-300">Joined {new Date(selectedUser.createdAt).toLocaleDateString()}</span></div>
                             <div className="flex items-center text-sm"><Shield size={14} className="mr-3 text-gray-600" /> <span className="text-purple-400 font-bold uppercase">{selectedUser.role}</span></div>
                          </div>
                       </div>

                       <div className="bg-[#111827] p-6 rounded-2xl border border-white/5">
                          <h3 className="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-4">Subscription</h3>
                          <div className="flex items-center justify-between">
                             <div>
                                <div className="text-lg font-black text-white uppercase">{selectedUser.subscription?.planName || 'Free'}</div>
                                <div className="text-[10px] text-gray-500 font-bold uppercase">Expires: {selectedUser.subscription?.endDate ? new Date(selectedUser.subscription.endDate).toLocaleDateString() : 'N/A'}</div>
                             </div>
                             <div className={`px-2 py-1 rounded text-[8px] font-black uppercase ${selectedUser.subscription?.status === 'active' ? 'bg-emerald-500/10 text-emerald-500' : 'bg-rose-500/10 text-rose-500'}`}>
                                {selectedUser.subscription?.status || 'inactive'}
                             </div>
                          </div>
                       </div>
                    </div>

                    {/* Middle: Usage Stats */}
                    <div className="md:col-span-2 space-y-6">
                       <div className="grid grid-cols-3 gap-4">
                          <div className="bg-[#111827] p-4 rounded-2xl border border-white/5">
                             <Activity size={20} className="text-[#0ea5e9] mb-2" />
                             <div className="text-xl font-black text-white">{Math.floor((selectedUser.totalWatchTime || 0) / 60)}h</div>
                             <div className="text-[8px] text-gray-500 font-bold uppercase">Total Watch Time</div>
                          </div>
                          <div className="bg-[#111827] p-4 rounded-2xl border border-white/5">
                             <Monitor size={20} className="text-purple-500 mb-2" />
                             <div className="text-xl font-black text-white">{selectedUser.devices?.length || 0}</div>
                             <div className="text-[8px] text-gray-500 font-bold uppercase">Active Devices</div>
                          </div>
                          <div className="bg-[#111827] p-4 rounded-2xl border border-white/5">
                             <DollarSign size={20} className="text-emerald-500 mb-2" />
                             <div className="text-xl font-black text-white">${selectedUser.balance?.toFixed(2) || '0.00'}</div>
                             <div className="text-[8px] text-gray-500 font-bold uppercase">Wallet Balance</div>
                          </div>
                       </div>

                       <div className="bg-[#111827] rounded-2xl border border-white/5 overflow-hidden">
                          <div className="p-4 border-b border-white/5 bg-white/[0.02] flex justify-between items-center">
                             <h3 className="text-[10px] font-black text-gray-400 uppercase tracking-widest">Recent Watch History</h3>
                             <button className="text-[8px] font-black text-[#0ea5e9] hover:underline uppercase">View All</button>
                          </div>
                          <div className="p-4 space-y-3">
                             {selectedUser.watchHistory?.length > 0 ? selectedUser.watchHistory.slice(-4).map((h, i) => (
                               <div key={i} className="flex items-center justify-between text-xs">
                                  <span className="text-gray-300 font-medium line-clamp-1">{h.movie?.title || 'Unknown Title'}</span>
                                  <span className="text-gray-600 font-mono text-[10px]">{h.progress}% watched</span>
                               </div>
                             )) : <div className="text-center py-4 text-gray-600 text-[10px] uppercase font-bold">No history available</div>}
                          </div>
                       </div>

                       <div className="flex gap-3">
                          <button className="flex-1 py-4 bg-white/5 hover:bg-[#0ea5e9] text-white font-black rounded-2xl text-xs transition-all border border-white/5 flex items-center justify-center">
                             <ArrowUpCircle size={16} className="mr-2" /> UPGRADE PLAN
                          </button>
                          <button className="flex-1 py-4 bg-white/5 hover:bg-[#0ea5e9] text-white font-black rounded-2xl text-xs transition-all border border-white/5 flex items-center justify-center">
                             <DollarSign size={16} className="mr-2" /> ADJUST BALANCE
                          </button>
                          <button className="flex-1 py-4 bg-white/5 hover:bg-[#0ea5e9] text-white font-black rounded-2xl text-xs transition-all border border-white/5 flex items-center justify-center">
                             <Bell size={16} className="mr-2" /> NOTIFY USER
                          </button>
                       </div>
                    </div>
                 </div>
              </div>

              <div className="p-8 border-t border-white/5 bg-[#111827] flex justify-between items-center">
                 <div className="flex space-x-2">
                    <button className="px-6 py-3 bg-white/5 hover:bg-white/10 text-white font-bold rounded-xl text-xs transition-all border border-white/5">RESET PASSWORD</button>
                    <button className="px-6 py-3 bg-amber-600/10 hover:bg-amber-600 text-amber-500 hover:text-white font-bold rounded-xl text-xs transition-all border border-amber-600/20 flex items-center">
                       <Ban size={14} className="mr-2" /> SUSPEND ACCOUNT
                    </button>
                 </div>
                 <button className="px-6 py-3 bg-rose-600/10 hover:bg-rose-600 text-rose-500 hover:text-white font-bold rounded-xl text-xs transition-all border border-rose-600/20 flex items-center uppercase">
                    <Trash2 size={14} className="mr-2" /> Delete permanently
                 </button>
              </div>
           </div>
        </div>
      )}

      {isModalOpen && selectedUser && (
        <div className="fixed inset-0 bg-black/80 flex items-center justify-center p-4 z-50">
          <div className="bg-[#1C1C1C] border border-white/10 rounded-xl max-w-md w-full p-8">
            <h2 className="text-2xl font-bold mb-2">Permissions</h2>
            <p className="text-gray-400 mb-6 italic text-sm">Managing: {selectedUser.name}</p>

            <div className="space-y-4 mb-8">
              {PERMISSIONS.map(perm => (
                <label key={perm.key} className="flex items-center justify-between group cursor-pointer">
                  <span className="text-gray-300 group-hover:text-white transition-colors">{perm.label}</span>
                  <input
                    type="checkbox"
                    className="w-5 h-5 rounded border-white/10 bg-[#262626] text-purple-600 focus:ring-purple-500"
                    checked={selectedUser.permissions?.[perm.key] || false}
                    onChange={(e) => {
                      const newPerms = { ...selectedUser.permissions, [perm.key]: e.target.checked };
                      setSelectedUser({ ...selectedUser, permissions: newPerms });
                    }}
                  />
                </label>
              ))}
            </div>

            <div className="flex gap-4">
              <button
                onClick={() => handleUpdatePermissions(selectedUser._id, selectedUser.permissions)}
                className="flex-1 bg-purple-600 hover:bg-purple-700 py-2 rounded font-bold transition-colors"
              >
                SAVE CHANGES
              </button>
              <button
                onClick={() => setIsModalOpen(false)}
                className="flex-1 bg-white/5 hover:bg-white/10 py-2 rounded font-bold transition-colors"
              >
                CANCEL
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Users;
