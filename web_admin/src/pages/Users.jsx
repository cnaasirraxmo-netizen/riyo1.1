import React, { useState, useEffect } from 'react';
import { Search, Filter, MoreVertical, Shield, User as UserIcon } from 'lucide-react';
import api from '../utils/api';

const Users = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const res = await api.get('/admin/users');
        setUsers(res.data);
      } catch (err) {
        console.error(err);
        // Fallback mock data if API fails in this environment
        setUsers([
          { _id: '1', name: 'John Doe', email: 'john@example.com', role: 'user', createdAt: new Date().toISOString(), plan: 'Premium' },
          { _id: '2', name: 'Jane Smith', email: 'jane@example.com', role: 'admin', createdAt: new Date().toISOString(), plan: 'Basic' },
        ]);
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
          <h1 className="text-2xl font-bold text-[#1d2327]">Users</h1>
          <p className="text-sm text-gray-500 mt-1">Manage and moderate application users.</p>
        </div>
      </div>

      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-2">
          <select className="input-field text-sm py-1">
            <option>Bulk Actions</option>
            <option>Delete</option>
            <option>Change Role to Subscriber</option>
            <option>Change Role to Administrator</option>
          </select>
          <button className="btn-secondary py-1 text-sm">Apply</button>
        </div>
        <div className="relative">
          <input type="text" placeholder="Search users..." className="input-field pl-10 text-sm py-1 w-64" />
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
        </div>
      </div>

      <div className="admin-card p-0 overflow-hidden">
        <table className="w-full text-left">
          <thead>
            <tr className="bg-gray-50 border-b border-[#dcdcde] text-xs font-bold text-gray-500 uppercase">
              <th className="p-4 w-12"><input type="checkbox" /></th>
              <th className="p-4">Username / Email</th>
              <th className="p-4">Name</th>
              <th className="p-4">Role</th>
              <th className="p-4">Plan</th>
              <th className="p-4">Registered</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#dcdcde]">
            {users.map((user) => (
              <tr key={user._id} className="hover:bg-gray-50 group transition-colors">
                <td className="p-4"><input type="checkbox" /></td>
                <td className="p-4">
                  <div>
                    <p className="font-bold text-[#2271b1] cursor-pointer hover:underline">{user.email}</p>
                    <div className="flex items-center gap-2 mt-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      <button className="text-[11px] text-[#2271b1] hover:text-[#135e96]">Edit</button>
                      <span className="text-gray-300 text-[11px]">|</span>
                      <button className="text-[11px] text-red-600 hover:text-red-800">Delete</button>
                      <span className="text-gray-300 text-[11px]">|</span>
                      <button className="text-[11px] text-[#2271b1] hover:text-[#135e96]">View</button>
                    </div>
                  </div>
                </td>
                <td className="p-4 text-sm text-gray-700 font-medium">{user.name}</td>
                <td className="p-4 text-sm">
                  <div className="flex items-center gap-2">
                    {user.role === 'admin' ? <Shield size={14} className="text-purple-600" /> : <UserIcon size={14} className="text-gray-400" />}
                    <span className="capitalize">{user.role}</span>
                  </div>
                </td>
                <td className="p-4">
                  <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase ${
                    user.plan === 'Premium' ? 'bg-emerald-100 text-emerald-700' : 'bg-blue-100 text-blue-700'
                  }`}>
                    {user.plan || 'Free'}
                  </span>
                </td>
                <td className="p-4 text-sm text-gray-500">
                  {new Date(user.createdAt).toLocaleDateString()}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default Users;
