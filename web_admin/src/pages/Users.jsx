import React, { useState, useEffect } from 'react';
import { Search, Filter, MoreVertical, Shield, User as UserIcon, Loader2 } from 'lucide-react';
import api from '../services/api';

const Users = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const res = await api.get('/admin/users');
        setUsers(res.data || []);
      } catch (err) {
        console.error(err);
        // Mock data removed
      } finally {
        setLoading(false);
      }
    };
    fetchUsers();
  }, []);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[#1d2327] dark:text-white">Users</h1>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">Manage and moderate application users.</p>
        </div>
      </div>

      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          <select className="input-field text-sm py-1 dark:bg-[#1e1e1e] dark:border-gray-700 dark:text-white">
            <option>Bulk Actions</option>
            <option>Delete</option>
            <option>Change Role to Subscriber</option>
            <option>Change Role to Administrator</option>
          </select>
          <button className="btn-secondary py-1 text-sm">Apply</button>
        </div>
        <div className="relative">
          <input
            type="text"
            placeholder="Search users..."
            className="input-field pl-10 text-sm py-1 w-64 dark:bg-[#1e1e1e] dark:border-gray-700 dark:text-white"
          />
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        </div>
      </div>

      <div className="admin-card p-0 overflow-hidden dark:bg-[#1e1e1e] dark:border-gray-800">
        {loading ? (
          <div className="p-12 flex justify-center">
            <Loader2 className="w-8 h-8 animate-spin text-[#2271b1]" />
          </div>
        ) : (
          <table className="w-full text-left">
            <thead>
              <tr className="bg-gray-50 dark:bg-[#2c3338] border-b border-[#dcdcde] dark:border-gray-800 text-xs font-bold text-gray-500 dark:text-gray-400 uppercase">
                <th className="p-4 w-12"><input type="checkbox" /></th>
                <th className="p-4">Username / Email</th>
                <th className="p-4">Name</th>
                <th className="p-4">Role</th>
                <th className="p-4">Plan</th>
                <th className="p-4">Registered</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#dcdcde] dark:divide-gray-800">
              {users.map((user) => (
                <tr key={user._id} className="hover:bg-gray-50 dark:hover:bg-[#2c3338] group transition-colors">
                  <td className="p-4"><input type="checkbox" /></td>
                  <td className="p-4">
                    <div>
                      <p className="font-bold text-[#2271b1] dark:text-blue-400 cursor-pointer hover:underline">{user.email}</p>
                      <div className="flex items-center gap-2 mt-1 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button className="text-[11px] text-[#2271b1] dark:text-blue-400 hover:text-[#135e96]">Edit</button>
                        <span className="text-gray-300 dark:text-gray-700 text-[11px]">|</span>
                        <button className="text-[11px] text-red-600 hover:text-red-800">Delete</button>
                        <span className="text-gray-300 dark:text-gray-700 text-[11px]">|</span>
                        <button className="text-[11px] text-[#2271b1] dark:text-blue-400 hover:text-[#135e96]">View</button>
                      </div>
                    </div>
                  </td>
                  <td className="p-4 text-sm text-gray-700 dark:text-gray-300 font-medium">{user.name}</td>
                  <td className="p-4 text-sm dark:text-gray-300">
                    <div className="flex items-center gap-2">
                      {user.role === 'admin' ? <Shield size={14} className="text-purple-600" /> : <UserIcon size={14} className="text-gray-400" />}
                      <span className="capitalize">{user.role}</span>
                    </div>
                  </td>
                  <td className="p-4">
                    <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${
                      user.plan === 'Premium' ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400' : 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400'
                    }`}>
                      {user.plan || 'Free'}
                    </span>
                  </td>
                  <td className="p-4 text-sm text-gray-500 dark:text-gray-400">
                    {new Date(user.createdAt).toLocaleDateString()}
                  </td>
                </tr>
              ))}
              {users.length === 0 && (
                <tr>
                  <td colSpan="6" className="p-12 text-center text-gray-500 dark:text-gray-400">
                    No users found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default Users;
