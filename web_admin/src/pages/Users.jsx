import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import { Users as UsersIcon, Search, MoreVertical, Shield, ShieldAlert, UserX, UserCheck, Calendar, Mail } from 'lucide-react';

const Users = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterRole, setFilterRole] = useState('all');

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

  const filteredUsers = users.filter(user => {
    const matchesSearch = user.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         user.email.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesRole = filterRole === 'all' || user.role === filterRole;
    return matchesSearch && matchesRole;
  });

  const handleToggleAdmin = async (userId, currentRole) => {
    if (!window.confirm(`Are you sure you want to change this user's role?`)) return;
    try {
      const newRole = currentRole === 'admin' ? 'user' : 'admin';
      await api.patch(`/admin/users/${userId}`, { role: newRole });
      setUsers(users.map(u => u._id === userId ? { ...u, role: newRole } : u));
    } catch (err) {
      alert('Failed to update role');
    }
  };

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
        <div>
          <h1 className="text-4xl font-black text-white tracking-tight">User Directory</h1>
          <p className="text-gray-400 text-lg mt-1">Monitor and manage your community.</p>
        </div>
        <div className="flex items-center gap-4">
          <div className="relative group">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 group-focus-within:text-purple-500 transition-colors" size={20} />
            <input
              type="text"
              placeholder="Search by name or email..."
              className="bg-[#1C1C1C] border border-white/5 rounded-2xl pl-12 pr-6 py-3 text-sm focus:outline-none focus:border-purple-500 transition-all w-80"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          <select
            className="bg-[#1C1C1C] border border-white/5 rounded-2xl px-6 py-3 text-sm font-bold outline-none focus:border-purple-500 transition-all appearance-none cursor-pointer"
            value={filterRole}
            onChange={(e) => setFilterRole(e.target.value)}
          >
            <option value="all">All Roles</option>
            <option value="user">Users</option>
            <option value="admin">Admins</option>
          </select>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-[#1C1C1C] p-6 rounded-3xl border border-white/5 flex items-center gap-6">
          <div className="p-4 bg-purple-600/20 rounded-2xl text-purple-500">
            <UsersIcon size={24} />
          </div>
          <div>
            <p className="text-gray-500 text-[10px] font-black uppercase tracking-widest">Total Accounts</p>
            <h3 className="text-2xl font-black text-white mt-1">{users.length}</h3>
          </div>
        </div>
        <div className="bg-[#1C1C1C] p-6 rounded-3xl border border-white/5 flex items-center gap-6">
          <div className="p-4 bg-blue-600/20 rounded-2xl text-blue-500">
            <Shield size={24} />
          </div>
          <div>
            <p className="text-gray-500 text-[10px] font-black uppercase tracking-widest">Administrators</p>
            <h3 className="text-2xl font-black text-white mt-1">{users.filter(u => u.role === 'admin').length}</h3>
          </div>
        </div>
        <div className="bg-[#1C1C1C] p-6 rounded-3xl border border-white/5 flex items-center gap-6">
          <div className="p-4 bg-green-600/20 rounded-2xl text-green-500">
            <UserCheck size={24} />
          </div>
          <div>
            <p className="text-gray-500 text-[10px] font-black uppercase tracking-widest">Active Today</p>
            <h3 className="text-2xl font-black text-white mt-1">128</h3>
          </div>
        </div>
      </div>

      <div className="bg-[#1C1C1C] rounded-[40px] border border-white/5 overflow-hidden shadow-2xl relative">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-black/20 text-gray-500 text-[10px] font-black uppercase tracking-[0.2em]">
                <th className="px-10 py-6 border-b border-white/5">Member Identity</th>
                <th className="px-10 py-6 border-b border-white/5">Access Rights</th>
                <th className="px-10 py-6 border-b border-white/5">Registration</th>
                <th className="px-10 py-6 border-b border-white/5">Status</th>
                <th className="px-10 py-6 border-b border-white/5 text-right">Operational Logic</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {loading ? (
                <tr>
                  <td colSpan="5" className="px-10 py-32 text-center">
                    <div className="flex flex-col items-center space-y-4">
                      <div className="w-10 h-10 border-2 border-purple-600 border-t-transparent rounded-full animate-spin"></div>
                      <span className="text-gray-500 font-bold uppercase tracking-widest text-[10px]">Accessing Database Securely...</span>
                    </div>
                  </td>
                </tr>
              ) : filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan="5" className="px-10 py-20 text-center text-gray-500 font-bold uppercase tracking-widest text-xs italic">
                    No matching identities found in the system.
                  </td>
                </tr>
              ) : filteredUsers.map((user) => (
                <tr key={user._id} className="hover:bg-white/[0.02] transition-colors group">
                  <td className="px-10 py-6">
                    <div className="flex items-center gap-4">
                      <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-purple-600/20 to-indigo-600/20 border border-white/5 flex items-center justify-center text-purple-500 font-black text-lg group-hover:from-purple-600 group-hover:text-white transition-all duration-300 shadow-inner">
                        {user.name[0].toUpperCase()}
                      </div>
                      <div className="flex flex-col">
                        <span className="text-white font-bold text-base leading-tight">{user.name}</span>
                        <div className="flex items-center gap-1.5 text-gray-500 text-xs mt-1">
                          <Mail size={12} />
                          <span className="font-medium">{user.email}</span>
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-10 py-6">
                    <div className={`inline-flex items-center gap-2 px-4 py-1.5 rounded-full text-[10px] font-black uppercase tracking-widest ${
                      user.role === 'admin' ? 'bg-purple-500/10 text-purple-500' : 'bg-blue-500/10 text-blue-500'
                    }`}>
                      {user.role === 'admin' ? <Shield size={12} /> : <UsersIcon size={12} />}
                      {user.role}
                    </div>
                  </td>
                  <td className="px-10 py-6">
                    <div className="flex items-center gap-2 text-gray-400 font-bold text-xs uppercase tracking-tighter">
                      <Calendar size={14} className="text-gray-600" />
                      {new Date(user.createdAt).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })}
                    </div>
                  </td>
                  <td className="px-10 py-6">
                    <span className="flex items-center gap-2">
                      <div className="w-2 h-2 rounded-full bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.5)]"></div>
                      <span className="text-xs font-black text-green-500 uppercase tracking-widest">Active</span>
                    </span>
                  </td>
                  <td className="px-10 py-6 text-right">
                    <div className="flex items-center justify-end gap-2 transform translate-x-4 opacity-0 group-hover:translate-x-0 group-hover:opacity-100 transition-all duration-300">
                      <button
                        onClick={() => handleToggleAdmin(user._id, user.role)}
                        className={`p-3 rounded-2xl border border-white/5 transition-all ${
                          user.role === 'admin' ? 'text-orange-500 hover:bg-orange-500/10' : 'text-purple-500 hover:bg-purple-500/10'
                        }`}
                        title={user.role === 'admin' ? "Revoke Admin" : "Make Admin"}
                      >
                        {user.role === 'admin' ? <ShieldAlert size={18} /> : <Shield size={18} />}
                      </button>
                      <button
                        className="p-3 rounded-2xl border border-white/5 text-red-500 hover:bg-red-500/10 transition-all"
                        title="Suspend Account"
                      >
                        <UserX size={18} />
                      </button>
                      <button className="p-3 rounded-2xl border border-white/5 text-gray-500 hover:text-white hover:bg-white/10 transition-all">
                        <MoreVertical size={18} />
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
  );
};

export default Users;
