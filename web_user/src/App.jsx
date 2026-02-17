import React, { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { requestForToken, onMessageListener } from './utils/firebase';
import Home from './pages/Home';
import Login from './pages/Login';
import Signup from './pages/Signup';
import MovieDetails from './pages/MovieDetails';
import Player from './pages/Player';
import Search from './pages/Search';
import MyList from './pages/MyList';
import Navbar from './components/Navbar';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(!!localStorage.getItem('token'));
  const [user, setUser] = useState(null);
  const [notification, setNotification] = useState({ title: '', body: '' });

  useEffect(() => {
    if (isAuthenticated) {
      requestForToken();
    }
  }, [isAuthenticated]);

  useEffect(() => {
    onMessageListener().then(payload => {
      setNotification({
        title: payload.notification.title,
        body: payload.notification.body
      });
      console.log(payload);
    }).catch(err => console.log('failed: ', err));
  }, []);

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
        {notification.title && (
          <div className="fixed top-4 right-4 z-50 bg-gray-800 p-4 rounded-lg border-l-4 border-red-600 shadow-lg animate-bounce">
            <h4 className="font-bold text-white">{notification.title}</h4>
            <p className="text-sm text-gray-300">{notification.body}</p>
            <button
              onClick={() => setNotification({ title: '', body: '' })}
              className="mt-2 text-xs text-red-500 hover:underline"
            >
              Close
            </button>
          </div>
        )}
        {isAuthenticated && <Navbar onLogout={handleLogout} />}
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
      </div>
    </BrowserRouter>
  );
}

export default App;
