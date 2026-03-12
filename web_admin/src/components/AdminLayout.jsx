import React, { useState, useEffect } from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import Sidebar from './Sidebar';
import { User, LogOut, Bell, Search, Globe, ChevronDown, Moon, Sun } from 'lucide-react';

const AdminLayout = ({ children }) => {
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
  const [isDarkMode, setIsDarkMode] = useState(localStorage.getItem('admin-theme') === 'dark');
  const navigate = useNavigate();

  useEffect(() => {
    if (isDarkMode) {
      document.documentElement.classList.add('dark');
      localStorage.setItem('admin-theme', 'dark');
    } else {
      document.documentElement.classList.remove('dark');
      localStorage.setItem('admin-theme', 'light');
    }
  }, [isDarkMode]);

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('role');
    navigate('/login');
  };

  const toggleTheme = () => setIsDarkMode(!isDarkMode);

  return (
    <div className={`min-h-screen flex flex-col ${isDarkMode ? 'bg-[#121212] text-gray-200' : 'bg-[#f0f0f1] text-[#3c434a]'}`}>
      {/* Top Header Bar */}
      <header className="h-12 bg-[#1e1e1e] text-white flex items-center justify-between px-4 sticky top-0 z-50">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2 cursor-pointer hover:text-blue-400 transition-colors">
            <Globe size={18} />
            <span className="text-sm font-semibold">RIYO Platform</span>
          </div>
          <div className="h-4 w-[1px] bg-gray-600"></div>
          <div className="flex items-center gap-4">
            <button className="text-sm hover:text-blue-400 transition-colors">Howdy, Admin</button>
            <button className="text-sm hover:text-blue-400 transition-colors flex items-center gap-1">
              + New <ChevronDown size={14} />
            </button>
          </div>
        </div>

        <div className="flex items-center gap-6">
          <button
            onClick={toggleTheme}
            className="p-1 hover:bg-gray-700 rounded transition-colors text-gray-400 hover:text-white"
            title={isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode'}
          >
            {isDarkMode ? <Sun size={18} /> : <Moon size={18} />}
          </button>

          <div className="relative group">
            <Bell size={18} className="cursor-pointer hover:text-blue-400" />
            <span className="absolute -top-1 -right-1 bg-blue-500 text-[10px] rounded-full w-4 h-4 flex items-center justify-center">3</span>
          </div>
          <div className="flex items-center gap-2 group cursor-pointer relative">
            <div className="w-8 h-8 rounded-full bg-gray-600 flex items-center justify-center overflow-hidden">
              <User size={20} />
            </div>
            <span className="text-sm font-medium group-hover:text-blue-400">admin</span>
            <div className="absolute top-12 right-0 bg-white dark:bg-[#1e1e1e] text-[#3c434a] dark:text-gray-200 border border-[#dcdcde] dark:border-gray-800 shadow-lg rounded hidden group-hover:block w-48 z-[60]">
              <div className="p-3 border-b border-[#dcdcde] dark:border-gray-800">
                <p className="text-xs text-gray-500 dark:text-gray-400">Logged in as</p>
                <p className="font-bold">Admin User</p>
              </div>
              <button onClick={() => navigate('/settings')} className="w-full text-left p-3 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors text-sm flex items-center gap-2">
                <User size={16} /> Edit Profile
              </button>
              <button onClick={handleLogout} className="w-full text-left p-3 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors text-sm text-red-600 flex items-center gap-2 border-t border-[#dcdcde] dark:border-gray-800">
                <LogOut size={16} /> Logout
              </button>
            </div>
          </div>
        </div>
      </header>

      <div className="flex flex-1 relative">
        {/* Sidebar */}
        <Sidebar collapsed={isSidebarCollapsed} onToggle={() => setIsSidebarCollapsed(!isSidebarCollapsed)} />

        {/* Main Content Area */}
        <main className={`flex-1 transition-all duration-300 ${isSidebarCollapsed ? 'ml-12' : 'ml-52'}`}>
          <div className="p-8 max-w-[1400px] mx-auto">
            {children}
          </div>

          <footer className="p-8 border-t border-[#dcdcde] dark:border-gray-800 text-sm text-[#3c434a] dark:text-gray-400 flex justify-between">
            <p>Thank you for creating with RIYO.</p>
            <p>Version 3.0.0</p>
          </footer>
        </main>
      </div>
    </div>
  );
};

export default AdminLayout;
