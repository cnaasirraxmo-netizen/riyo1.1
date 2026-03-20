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
  const token = localStorage.getItem('token');
  const role = localStorage.getItem('role');

  if (!token || role !== 'admin') {
    return <Navigate to="/login" replace />;
  }

  return <AdminLayout>{children}</AdminLayout>;
};

function App() {
  const [authTick, setAuthTick] = React.useState(0);

  const handleLogin = (token, role) => {
    localStorage.setItem('token', token);
    localStorage.setItem('role', role);
    setAuthTick(prev => prev + 1);
  };

  return (
    <BrowserRouter>
      <Suspense fallback={<PageLoader />}>
        <Routes>
          <Route path="/login" element={<Login onLogin={handleLogin} />} />

          <Route path="/dashboard" element={<ProtectedRoute key={`dash-${authTick}`}><Dashboard /></ProtectedRoute>} />
          <Route path="/movies" element={<ProtectedRoute key={`mov-${authTick}`}><Movies /></ProtectedRoute>} />
          <Route path="/tv-shows" element={<ProtectedRoute key={`tv-${authTick}`}><TVShows /></ProtectedRoute>} />
          <Route path="/trailers" element={<ProtectedRoute key={`trail-${authTick}`}><Trailers /></ProtectedRoute>} />
          <Route path="/categories" element={<ProtectedRoute key={`cat-${authTick}`}><Categories /></ProtectedRoute>} />
          <Route path="/featured" element={<ProtectedRoute key={`feat-${authTick}`}><FeaturedContent /></ProtectedRoute>} />
          <Route path="/sports" element={<ProtectedRoute key={`sport-${authTick}`}><Sports /></ProtectedRoute>} />
          <Route path="/kids" element={<ProtectedRoute key={`kids-${authTick}`}><KidsContent /></ProtectedRoute>} />
          <Route path="/users" element={<ProtectedRoute key={`users-${authTick}`}><Users /></ProtectedRoute>} />
          <Route path="/subscriptions" element={<ProtectedRoute key={`subs-${authTick}`}><Subscriptions /></ProtectedRoute>} />
          <Route path="/notifications" element={<ProtectedRoute key={`notif-${authTick}`}><Notifications /></ProtectedRoute>} />
          <Route path="/analytics" element={<ProtectedRoute key={`anal-${authTick}`}><Analytics /></ProtectedRoute>} />
          <Route path="/downloads" element={<ProtectedRoute key={`down-${authTick}`}><Downloads /></ProtectedRoute>} />
          <Route path="/settings" element={<ProtectedRoute key={`sett-${authTick}`}><Settings /></ProtectedRoute>} />
          <Route path="/system" element={<ProtectedRoute key={`sys-${authTick}`}><SystemTools /></ProtectedRoute>} />

          <Route path="*" element={<Navigate to="/dashboard" />} />
        </Routes>
      </Suspense>
    </BrowserRouter>
  );
}

export default App;
