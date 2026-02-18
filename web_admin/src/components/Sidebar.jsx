import React from 'react';
import { NavLink } from 'react-router-dom';
import { LayoutDashboard, Film, FolderOpen, Users, LogOut, Trophy, Bell } from 'lucide-react';

const Sidebar = ({ onLogout }) => {
  const links = [
    { path: '/dashboard', label: 'Dashboard', icon: <LayoutDashboard size={20} /> },
    { path: '/movies', label: 'Movies', icon: <Film size={20} /> },
    { path: '/media', label: 'Media Library', icon: <FolderOpen size={20} /> },
    { path: '/users', label: 'Users', icon: <Users size={20} /> },
    { path: '/sports', label: 'Sports', icon: <Trophy size={20} /> },
    { path: '/notifications', label: 'Push Alerts', icon: <Bell size={20} /> },
  ];

  return (
    <div className="w-80 bg-[#1C1C1C] border-r border-white/5 flex flex-col relative z-20">
      <div className="p-12">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-purple-600 rounded-2xl flex items-center justify-center text-white font-black italic text-xl shadow-xl shadow-purple-600/20">R</div>
          <div>
            <h1 className="text-2xl font-black text-white tracking-tighter leading-none">RIYOBOX</h1>
            <p className="text-[9px] text-gray-500 uppercase tracking-[0.3em] font-black mt-1">Command Center</p>
          </div>
        </div>
      </div>

      <nav className="flex-1 px-6 space-y-2">
        {links.map((link) => (
          <NavLink
            key={link.path}
            to={link.path}
            className={({ isActive }) =>
              `flex items-center px-6 py-4 rounded-[20px] transition-all duration-300 group ${
                isActive
                  ? 'bg-gradient-to-r from-purple-600 to-indigo-600 text-white shadow-xl shadow-purple-600/20'
                  : 'text-gray-500 hover:bg-white/5 hover:text-gray-300'
              }`
            }
          >
            <span className={`mr-4 transition-transform duration-300 ${isActive ? 'scale-110' : 'group-hover:scale-110'}`}>{link.icon}</span>
            <span className="text-sm font-black uppercase tracking-widest">{link.label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="p-8">
        <div className="bg-white/5 rounded-[32px] p-6 mb-6 border border-white/5 relative overflow-hidden group">
          <div className="absolute inset-0 bg-purple-600/10 translate-y-12 group-hover:translate-y-0 transition-transform duration-500"></div>
          <p className="text-[10px] font-black text-gray-500 uppercase tracking-widest relative z-10">Admin Session</p>
          <div className="flex items-center gap-3 mt-3 relative z-10">
            <div className="w-8 h-8 rounded-full bg-purple-600 flex items-center justify-center text-[10px] font-black">AD</div>
            <span className="text-xs font-bold text-white">Administrator</span>
          </div>
        </div>

        <button
          onClick={onLogout}
          className="w-full flex items-center px-8 py-4 text-gray-500 hover:text-red-500 hover:bg-red-500/10 rounded-[20px] transition-all duration-300 group border border-transparent hover:border-red-500/20"
        >
          <LogOut size={18} className="mr-4 group-hover:-translate-x-1 transition-transform" />
          <span className="text-sm font-black uppercase tracking-widest">Terminate</span>
        </button>
      </div>
    </div>
  );
};

export default Sidebar;
