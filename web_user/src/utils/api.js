import axios from 'axios';

// Unified Global API Gateway URL
const API_URL = 'https://api.riyo.com/v1';

const api = axios.create({
  baseURL: API_URL,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  // Prepend /cms to legacy routes if not already present
  if (!config.url.startsWith('/cms') &&
      !config.url.startsWith('/users') &&
      !config.url.startsWith('/metadata')) {
    config.url = `/cms${config.url.startsWith('/') ? '' : '/'}${config.url}`;
  }

  return config;
});

export default api;
export { API_URL };
