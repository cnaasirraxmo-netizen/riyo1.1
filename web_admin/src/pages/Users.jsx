import React, { useState, useEffect } from 'react';
import api from '../utils/api';

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

  return (
    <div>
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
                <td className="px-6 py-4 font-medium">{user.name}</td>
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
