import React, { useState } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import {
  LayoutDashboard,
  Film,
  Tv,
  Users,
  Bell,
  Trophy,
  Settings,
  LogOut,
  ChevronDown,
  ChevronRight,
  Menu,
  X,
  PlusCircle,
  List,
  FolderOpen,
  PieChart,
  ShieldCheck,
  Globe
} from 'lucide-react';

const Sidebar = ({ onLogout }) => {
  const [isCollapsed, setIsCollapsed] = useState(false);
  const [openSubmenus, setOpenSubmenus] = useState({});
  const location = useLocation();

  const toggleSidebar = () => setIsCollapsed(!isCollapsed);

  const toggleSubmenu = (label) => {
    if (isCollapsed) setIsCollapsed(false);
    setOpenSubmenus((prev) => ({
      ...prev,
      [label]: !prev[label],
    }));
  };

  const menuItems = [
    {
      label: 'Dashboard',
      icon: <LayoutDashboard size={20} />,
      path: '/dashboard',
    },
    {
      label: 'Movies',
      icon: <Film size={20} />,
      subItems: [
        { label: 'All Movies', path: '/movies', icon: <List size={16} /> },
        { label: 'Add Movie', path: '/movies/add', icon: <PlusCircle size={16} /> },
        { label: 'Categories', path: '/movies/categories', icon: <FolderOpen size={16} /> },
      ],
    },
    {
      label: 'Series',
      icon: <Tv size={20} />,
      subItems: [
        { label: 'All Series', path: '/series', icon: <List size={16} /> },
        { label: 'Add Series', path: '/series/add', icon: <PlusCircle size={16} /> },
        { label: 'Episodes', path: '/series/episodes', icon: <Film size={16} /> },
      ],
    },
    {
      label: 'Users',
      icon: <Users size={20} />,
      subItems: [
        { label: 'Manage Users', path: '/users', icon: <Users size={16} /> },
        { label: 'Admins', path: '/users/admins', icon: <ShieldCheck size={16} /> },
      ],
    },
    {
      label: 'Sports',
      icon: <Trophy size={20} />,
      path: '/sports',
    },
    {
      label: 'Analytics',
      icon: <PieChart size={20} />,
      subItems: [
        { label: 'Overview', path: '/analytics', icon: <PieChart size={16} /> },
        { label: 'Geographic', path: '/analytics/geo', icon: <Globe size={16} /> },
      ],
    },
    {
      label: 'Notifications',
      icon: <Bell size={20} />,
      path: '/notifications',
    },
    {
      label: 'Settings',
      icon: <Settings size={20} />,
      path: '/settings',
    },
    {
      label: 'Profile',
      icon: <ShieldCheck size={20} />,
      path: '/profile',
    },
  ];

  const isActive = (path) => location.pathname === path;
  const isSubmenuActive = (subItems) => subItems.some(item => location.pathname === item.path);

  return (
    <div
      className={`${
        isCollapsed ? 'w-20' : 'w-64'
      } bg-[#1f2937] text-[#f9fafb] flex flex-col transition-all duration-300 ease-in-out relative border-r border-white/5 h-screen overflow-y-auto custom-scrollbar`}
    >
      {/* Toggle Button */}
      <button
        onClick={toggleSidebar}
        className="absolute top-6 -right-3 bg-[#0ea5e9] text-white p-1 rounded-full shadow-lg z-50 hover:bg-[#0284c7] transition-colors md:flex hidden"
      >
        {isCollapsed ? <ChevronRight size={16} /> : <ChevronRight size={16} className="rotate-180" />}
      </button>

      {/* Header */}
      <div className={`p-6 flex items-center ${isCollapsed ? 'justify-center' : 'justify-between'}`}>
        {!isCollapsed && (
          <div>
            <h1 className="text-2xl font-black text-[#0ea5e9] tracking-tighter">RIYOBOX</h1>
            <p className="text-[10px] text-gray-400 uppercase tracking-widest font-bold">Admin Panel</p>
          </div>
        )}
        <button onClick={toggleSidebar} className="md:hidden block text-gray-400 hover:text-white">
          <Menu size={24} />
        </button>
        {isCollapsed && <Film className="text-[#0ea5e9]" size={32} />}
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 mt-4 space-y-1">
        {menuItems.map((item) => (
          <div key={item.label}>
            {item.subItems ? (
              <div>
                <button
                  onClick={() => toggleSubmenu(item.label)}
                  className={`w-full flex items-center px-3 py-3 rounded-lg transition-all duration-200 group ${
                    isSubmenuActive(item.subItems)
                      ? 'bg-[#374151] text-[#0ea5e9]'
                      : 'text-gray-400 hover:bg-[#374151] hover:text-[#f9fafb]'
                  }`}
                >
                  <span className={`${isCollapsed ? 'mx-auto' : 'mr-3'}`}>{item.icon}</span>
                  {!isCollapsed && (
                    <>
                      <span className="font-medium flex-1 text-left">{item.label}</span>
                      {openSubmenus[item.label] ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
                    </>
                  )}
                </button>

                {/* Submenu Items */}
                {!isCollapsed && openSubmenus[item.label] && (
                  <div className="mt-1 ml-4 pl-4 border-l border-white/10 space-y-1">
                    {item.subItems.map((subItem) => (
                      <NavLink
                        key={subItem.path}
                        to={subItem.path}
                        className={({ isActive }) =>
                          `flex items-center px-3 py-2 rounded-lg text-sm transition-all duration-200 ${
                            isActive
                              ? 'bg-[#0ea5e9]/10 text-[#0ea5e9]'
                              : 'text-gray-400 hover:bg-[#374151] hover:text-[#f9fafb]'
                          }`
                        }
                      >
                        <span className="mr-2 opacity-70">{subItem.icon}</span>
                        <span>{subItem.label}</span>
                      </NavLink>
                    ))}
                  </div>
                )}
              </div>
            ) : (
              <NavLink
                to={item.path}
                className={({ isActive }) =>
                  `flex items-center px-3 py-3 rounded-lg transition-all duration-200 group ${
                    isActive
                      ? 'bg-[#374151] text-[#0ea5e9]'
                      : 'text-gray-400 hover:bg-[#374151] hover:text-[#f9fafb]'
                  }`
                }
              >
                <span className={`${isCollapsed ? 'mx-auto' : 'mr-3'}`}>{item.icon}</span>
                {!isCollapsed && <span className="font-medium">{item.label}</span>}
              </NavLink>
            )}
          </div>
        ))}
      </nav>

      {/* Footer / User Profile & Logout */}
      <div className="p-4 border-t border-white/5 space-y-2">
        {!isCollapsed && (
          <NavLink
            to="/profile"
            className="flex items-center p-3 rounded-xl bg-white/5 border border-white/5 hover:bg-white/10 transition-all mb-4 group"
          >
             <div className="w-10 h-10 bg-[#0ea5e9] rounded-lg flex items-center justify-center text-white font-black mr-3 shadow-lg shadow-[#0ea5e9]/20">
                {JSON.parse(localStorage.getItem('adminUser') || sessionStorage.getItem('adminUser') || '{}').name?.charAt(0) || 'A'}
             </div>
             <div className="flex-1 overflow-hidden">
                <p className="text-xs font-black text-white truncate uppercase tracking-tighter">
                  {JSON.parse(localStorage.getItem('adminUser') || sessionStorage.getItem('adminUser') || '{}').name || 'Admin User'}
                </p>
                <p className="text-[9px] text-gray-500 font-bold truncate">
                  {localStorage.getItem('role') || sessionStorage.getItem('role')}
                </p>
             </div>
             <ChevronRight size={14} className="text-gray-600 group-hover:text-[#0ea5e9] transition-colors" />
          </NavLink>
        )}
        <button
          onClick={onLogout}
          className={`w-full flex items-center px-3 py-3 rounded-lg transition-all duration-200 group ${
            isCollapsed ? 'justify-center' : ''
          } text-gray-400 hover:text-red-500 hover:bg-red-500/5`}
        >
          <LogOut size={20} className={`${isCollapsed ? '' : 'mr-3'}`} />
          {!isCollapsed && <span className="font-medium">Logout</span>}
        </button>
      </div>
    </div>
  );
};

export default Sidebar;
