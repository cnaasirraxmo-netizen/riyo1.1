import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  Film,
  Tv,
  PlaySquare,
  List,
  Star,
  Trophy,
  Baby,
  Users,
  CreditCard,
  Bell,
  BarChart3,
  Download,
  Settings,
  Wrench,
  ChevronLeft,
  ChevronRight
} from 'lucide-react';

const Sidebar = ({ collapsed, onToggle }) => {
  const menuItems = [
    { path: '/dashboard', label: 'Dashboard', icon: <LayoutDashboard size={20} /> },
    { path: '/movies', label: 'Movies', icon: <Film size={20} /> },
    { path: '/tv-shows', label: 'TV Shows', icon: <Tv size={20} /> },
    { path: '/trailers', label: 'Trailers', icon: <PlaySquare size={20} /> },
    { path: '/categories', label: 'Categories', icon: <List size={20} /> },
    { path: '/featured', label: 'Featured Content', icon: <Star size={20} /> },
    { path: '/sports', label: 'Sports', icon: <Trophy size={20} /> },
    { path: '/kids', label: 'Kids Content', icon: <Baby size={20} /> },
    { path: '/users', label: 'Users', icon: <Users size={20} /> },
    { path: '/subscriptions', label: 'Subscriptions', icon: <CreditCard size={20} /> },
    { path: '/notifications', label: 'Notifications', icon: <Bell size={20} /> },
    { path: '/analytics', label: 'Analytics', icon: <BarChart3 size={20} /> },
    { path: '/downloads', label: 'Downloads', icon: <Download size={20} /> },
    { path: '/settings', label: 'Settings', icon: <Settings size={20} /> },
    { path: '/system', label: 'System Tools', icon: <Wrench size={20} /> },
  ];

  return (
    <aside
      className={`bg-[#1e1e1e] text-gray-300 fixed left-0 top-12 bottom-0 transition-all duration-300 z-40 flex flex-col ${
        collapsed ? 'w-12' : 'w-52'
      }`}
    >
      <nav className="flex-1 py-4 overflow-y-auto overflow-x-hidden custom-scrollbar">
        {menuItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) =>
              `flex items-center h-10 px-3 transition-colors group relative ${
                isActive
                  ? 'bg-[#2271b1] text-white font-semibold'
                  : 'hover:bg-[#32373c] hover:text-blue-400'
              }`
            }
          >
            <span className="flex-shrink-0">{item.icon}</span>
            {!collapsed && (
              <span className="ml-3 text-[14px] whitespace-nowrap">{item.label}</span>
            )}

            {collapsed && (
              <div className="absolute left-12 bg-[#1e1e1e] border border-gray-700 px-3 py-1 rounded hidden group-hover:block text-xs whitespace-nowrap shadow-xl">
                {item.label}
              </div>
            )}
          </NavLink>
        ))}
      </nav>

      <button
        onClick={onToggle}
        className="h-10 border-t border-gray-700 flex items-center px-4 hover:bg-[#32373c] hover:text-blue-400 transition-colors"
      >
        {collapsed ? <ChevronRight size={20} /> : <div className="flex items-center gap-3"><ChevronLeft size={20} /> <span className="text-xs">Collapse Menu</span></div>}
      </button>
    </aside>
  );
};

export default Sidebar;
