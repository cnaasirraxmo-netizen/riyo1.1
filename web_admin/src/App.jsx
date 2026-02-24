import React, { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Movies from './pages/Movies';
import Media from './pages/Media';
import Users from './pages/Users';
import Layout from './pages/Layout';
import Management from './pages/Management';
import Sidebar from './components/Sidebar';
import api from './utils/api';

function App() {
  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('role');
    window.location.href = '/';
  };

  return (
    <BrowserRouter>
      <div className="flex min-h-screen bg-[#141414]">
        <Sidebar onLogout={handleLogout} />
        <main className="flex-1 p-8 overflow-y-auto">
          <Routes>
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/movies" element={<Movies />} />
            <Route path="/media" element={<Media />} />
            <Route path="/users" element={<Users />} />
            <Route path="/layout" element={<Layout />} />
            <Route path="/management" element={<Management />} />
            <Route path="*" element={<Navigate to="/dashboard" />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  );
}

export default App;
