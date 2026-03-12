import React, { lazy, Suspense } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import AdminLayout from './components/AdminLayout';

// Lazy load pages
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Movies = lazy(() => import('./pages/Movies'));
const TVShows = lazy(() => import('./pages/TVShows'));
const Trailers = lazy(() => import('./pages/Trailers'));
const Categories = lazy(() => import('./pages/Categories'));
const FeaturedContent = lazy(() => import('./pages/FeaturedContent'));
const Sports = lazy(() => import('./pages/Sports'));
const KidsContent = lazy(() => import('./pages/KidsContent'));
const Users = lazy(() => import('./pages/Users'));
const Subscriptions = lazy(() => import('./pages/Subscriptions'));
const Notifications = lazy(() => import('./pages/Notifications'));
const Analytics = lazy(() => import('./pages/Analytics'));
const Downloads = lazy(() => import('./pages/Downloads'));
const Settings = lazy(() => import('./pages/Settings'));
const SystemTools = lazy(() => import('./pages/SystemTools'));
const Login = lazy(() => import('./pages/Login'));

const PageLoader = () => (
  <div className="h-full w-full flex items-center justify-center bg-[#f0f0f1]">
    <div className="w-8 h-8 border-4 border-[#2271b1] border-t-transparent rounded-full animate-spin"></div>
  </div>
);

const ProtectedRoute = ({ children }) => {
  // Simple check for now, in real app check actual token
  // const token = localStorage.getItem('token');
  // if (!token) return <Navigate to="/login" />;
  return <AdminLayout>{children}</AdminLayout>;
};

function App() {
  return (
    <BrowserRouter>
      <Suspense fallback={<PageLoader />}>
        <Routes>
          <Route path="/login" element={<Login />} />

          <Route path="/dashboard" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
          <Route path="/movies" element={<ProtectedRoute><Movies /></ProtectedRoute>} />
          <Route path="/tv-shows" element={<ProtectedRoute><TVShows /></ProtectedRoute>} />
          <Route path="/trailers" element={<ProtectedRoute><Trailers /></ProtectedRoute>} />
          <Route path="/categories" element={<ProtectedRoute><Categories /></ProtectedRoute>} />
          <Route path="/featured" element={<ProtectedRoute><FeaturedContent /></ProtectedRoute>} />
          <Route path="/sports" element={<ProtectedRoute><Sports /></ProtectedRoute>} />
          <Route path="/kids" element={<ProtectedRoute><KidsContent /></ProtectedRoute>} />
          <Route path="/users" element={<ProtectedRoute><Users /></ProtectedRoute>} />
          <Route path="/subscriptions" element={<ProtectedRoute><Subscriptions /></ProtectedRoute>} />
          <Route path="/notifications" element={<ProtectedRoute><Notifications /></ProtectedRoute>} />
          <Route path="/analytics" element={<ProtectedRoute><Analytics /></ProtectedRoute>} />
          <Route path="/downloads" element={<ProtectedRoute><Downloads /></ProtectedRoute>} />
          <Route path="/settings" element={<ProtectedRoute><Settings /></ProtectedRoute>} />
          <Route path="/system" element={<ProtectedRoute><SystemTools /></ProtectedRoute>} />

          <Route path="*" element={<Navigate to="/dashboard" />} />
        </Routes>
      </Suspense>
    </BrowserRouter>
  );
}

export default App;
