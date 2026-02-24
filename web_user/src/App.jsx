import React, { useState, useEffect, lazy, Suspense } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Navbar from './components/Navbar';

// Lazy load pages for better performance
const Home = lazy(() => import('./pages/Home'));
const Login = lazy(() => import('./pages/Login'));
const Signup = lazy(() => import('./pages/Signup'));
const MovieDetails = lazy(() => import('./pages/MovieDetails'));
const Player = lazy(() => import('./pages/Player'));
const Search = lazy(() => import('./pages/Search'));
const MyList = lazy(() => import('./pages/MyList'));

// Loading component
const PageLoader = () => (
  <div className="h-screen flex items-center justify-center bg-[#141414]">
    <div className="w-12 h-12 border-4 border-purple-600 border-t-transparent rounded-full animate-spin"></div>
  </div>
);

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(!!localStorage.getItem('token'));
  const [user, setUser] = useState(null);

  useEffect(() => {
    if (isAuthenticated) {
      // Potentially fetch user profile here
    }
  }, [isAuthenticated]);

  const handleLogin = (token, userData) => {
    localStorage.setItem('token', token);
    setIsAuthenticated(true);
    setUser(userData);
  };

  const handleLogout = () => {
    localStorage.removeItem('token');
    setIsAuthenticated(false);
    setUser(null);
  };

  return (
    <BrowserRouter>
      <div className="min-h-screen bg-[#141414] text-white">
        {isAuthenticated && <Navbar onLogout={handleLogout} />}
        <Suspense fallback={<PageLoader />}>
          <Routes>
            <Route path="/login" element={!isAuthenticated ? <Login onLogin={handleLogin} /> : <Navigate to="/" />} />
            <Route path="/signup" element={!isAuthenticated ? <Signup onLogin={handleLogin} /> : <Navigate to="/" />} />

            <Route path="/" element={isAuthenticated ? <Home /> : <Navigate to="/login" />} />
            <Route path="/movie/:id" element={isAuthenticated ? <MovieDetails /> : <Navigate to="/login" />} />
            <Route path="/watch/:id" element={isAuthenticated ? <Player /> : <Navigate to="/login" />} />
            <Route path="/search" element={isAuthenticated ? <Search /> : <Navigate to="/login" />} />
            <Route path="/my-list" element={isAuthenticated ? <MyList /> : <Navigate to="/login" />} />

            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        </Suspense>
      </div>
    </BrowserRouter>
  );
}

export default App;
