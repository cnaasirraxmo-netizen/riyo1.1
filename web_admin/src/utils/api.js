import axios from 'axios';

// Centralized Backend API URL
const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
  ? 'http://localhost:5000'
  : (import.meta.env.VITE_API_BASE_URL || 'https://riyo1-1.onrender.com');

const api = axios.create({
  baseURL: API_URL,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
    console.log(`[API] Attaching token to ${config.method.toUpperCase()} ${config.url}`);
  } else {
    console.warn(`[API] No token found for protected request to ${config.url}`);
  }
  return config;
}, (error) => {
  return Promise.reject(error);
});

api.interceptors.response.use((response) => {
  return response;
}, (error) => {
  if (error.response && error.response.status === 401) {
    console.error('[API] Unauthorized access - redirecting to login');
    localStorage.removeItem('token');
    localStorage.removeItem('role');
    window.location.href = '/login';
  }
  return Promise.reject(error);
});

export default api;
export { API_URL };
