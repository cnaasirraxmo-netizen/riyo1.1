import axios from 'axios';

const API_BASE_URL = 'http://localhost:5000'; // Replace with production URL when ready

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add a request interceptor to include the auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

export const authService = {
  login: async (credentials) => {
    const response = await api.post('/auth/login', credentials);
    return response.data;
  },
  register: async (userData) => {
    const response = await api.post('/auth/register', userData);
    return response.data;
  },
};

export const movieService = {
  getAll: async () => {
    const response = await api.get('/admin/movies?paginate=false');
    return response.data;
  },
  create: async (movieData) => {
    const response = await api.post('/admin/movies', movieData);
    return response.data;
  },
  update: async (id, movieData) => {
    const response = await api.put(`/admin/movies/${id}`, movieData);
    return response.data;
  },
  delete: async (id) => {
    const response = await api.delete(`/admin/movies/${id}`);
    return response.data;
  },
  publish: async (id, isPublished) => {
    const response = await api.put(`/admin/movies/${id}/publish`, { isPublished });
    return response.data;
  },
};

export const systemService = {
  getConfig: async () => {
    const response = await api.get('/system-config');
    return response.data;
  },
  updateConfig: async (config) => {
    const response = await api.put('/admin/system-config', config);
    return response.data;
  },
};

export const uploadService = {
  uploadFile: async (file) => {
    const formData = new FormData();
    formData.append('file', file);
    const response = await api.post('/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    return response.data;
  },
  uploadByUrl: async (url) => {
    const response = await api.post('/upload/by-url', { url });
    return response.data;
  },
};

export default api;
