import React, { useState, useEffect, lazy, Suspense } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Sidebar from './components/Sidebar';

// Lazy load pages
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Movies = lazy(() => import('./pages/Movies'));
const Media = lazy(() => import('./pages/Media'));
const Users = lazy(() => import('./pages/Users'));
const Layout = lazy(() => import('./pages/Layout'));
const Management = lazy(() => import('./pages/Management'));

// Loader
const PageLoader = () => (
  <div className="h-full w-full flex items-center justify-center bg-[#141414]">
    <div className="w-10 h-10 border-4 border-purple-600 border-t-transparent rounded-full animate-spin"></div>
  </div>
);

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
          <Suspense fallback={<PageLoader />}>
            <Routes>
              <Route path="/dashboard" element={<Dashboard />} />
              <Route path="/movies" element={<Movies />} />
              <Route path="/media" element={<Media />} />
              <Route path="/users" element={<Users />} />
              <Route path="/layout" element={<Layout />} />
              <Route path="/management" element={<Management />} />
              <Route path="*" element={<Navigate to="/dashboard" />} />
            </Routes>
          </Suspense>
        </main>
      </div>
    </BrowserRouter>
  );
}

export default App;
