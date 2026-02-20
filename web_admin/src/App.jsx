import React, { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Movies from './pages/Movies';
import AddMovie from './pages/AddMovie';
import Media from './pages/Media';
import Users from './pages/Users';
import Sports from './pages/Sports';
import Notifications from './pages/Notifications';
import Sidebar from './components/Sidebar';

// Placeholder components for new routes
const Placeholder = ({ title }) => (
  <div className="p-8">
    <h1 className="text-3xl font-black text-white">{title}</h1>
    <p className="text-gray-400 mt-1">This module is under development.</p>
  </div>
);

function App() {
  // Support both localStorage and sessionStorage (for "Remember me")
  const getToken = () => localStorage.getItem('adminToken') || sessionStorage.getItem('adminToken');
  const getRole = () => localStorage.getItem('role') || sessionStorage.getItem('role');

  const [isAuthenticated, setIsAuthenticated] = useState(!!getToken());
  const [role, setRole] = useState(getRole());

  const handleLogin = (token, userRole) => {
    // If not "remembered", it should be in sessionStorage (handled in Login.jsx)
    // Here we just update state
    setIsAuthenticated(true);
    setRole(userRole);
  };

  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    localStorage.removeItem('adminRefreshToken');
    localStorage.removeItem('role');
    sessionStorage.removeItem('adminToken');
    sessionStorage.removeItem('role');
    setIsAuthenticated(false);
    setRole(null);
  };

  if (!isAuthenticated) {
    return (
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login onLogin={handleLogin} />} />
          <Route path="*" element={<Navigate to="/login" />} />
        </Routes>
      </BrowserRouter>
    );
  }

  const adminRoles = ['admin', 'super-admin', 'content-admin', 'support-admin', 'analytics-admin', 'moderator'];
  if (!adminRoles.includes(role)) {
    return (
      <div className="h-screen flex items-center justify-center bg-[#111827] text-white p-8">
        <div className="max-w-md w-full bg-[#1f2937] p-8 rounded-3xl border border-white/5 text-center shadow-2xl">
          <div className="w-20 h-20 bg-rose-500/10 text-rose-500 rounded-full flex items-center justify-center mx-auto mb-6">
             <span className="text-4xl font-bold">!</span>
          </div>
          <h1 className="text-2xl font-black mb-2 uppercase tracking-tight">Access Denied</h1>
          <p className="text-gray-400 mb-8 text-sm">Your account ({role}) does not have the necessary permissions to access the admin headquarters.</p>
          <button
            onClick={handleLogout}
            className="w-full py-3 bg-[#0ea5e9] hover:bg-[#0284c7] text-white font-black rounded-xl transition-all shadow-lg shadow-[#0ea5e9]/20"
          >
            RETURN TO LOGIN
          </button>
        </div>
      </div>
    );
  }

  return (
    <BrowserRouter>
      <div className="flex h-screen bg-[#111827] overflow-hidden">
        <Sidebar onLogout={handleLogout} />
        <main className="flex-1 h-screen overflow-y-auto custom-scrollbar bg-[#111827]">
          <Routes>
            <Route path="/dashboard" element={<Dashboard />} />

            {/* Movies */}
            <Route path="/movies" element={<Movies />} />
            <Route path="/movies/add" element={<AddMovie />} />
            <Route path="/movies/categories" element={<Placeholder title="Movie Categories" />} />

            {/* Series */}
            <Route path="/series" element={<Placeholder title="TV Series Management" />} />
            <Route path="/series/add" element={<Placeholder title="Add New Series" />} />
            <Route path="/series/episodes" element={<Placeholder title="Episode Manager" />} />

            {/* Users */}
            <Route path="/users" element={<Users />} />
            <Route path="/users/admins" element={<Placeholder title="Admin Management" />} />

            <Route path="/media" element={<Media />} />
            <Route path="/sports" element={<Sports />} />
            <Route path="/notifications" element={<Notifications />} />

            {/* Analytics */}
            <Route path="/analytics" element={<Placeholder title="Analytics Overview" />} />
            <Route path="/analytics/geo" element={<Placeholder title="Geographic Distribution" />} />

            <Route path="/settings" element={<Placeholder title="System Settings" />} />

            <Route path="/" element={<Navigate to="/dashboard" />} />
            <Route path="*" element={<Navigate to="/dashboard" />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  );
}

export default App;
