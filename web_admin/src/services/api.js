import axios from 'axios';

const API_BASE_URL = 'https://riyo-2.onrender.com';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add auth interceptor
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const movieService = {
  getAll: async () => {
    const response = await api.get('/admin/movies');
    return response.data;
  },
  create: async (data) => {
    const response = await api.post('/admin/movies', data);
    return response.data;
  },
  update: async (id, data) => {
    const response = await api.put(`/admin/movies/${id}`, data);
    return response.data;
  },
  delete: async (id) => {
    const response = await api.delete(`/admin/movies/${id}`);
    return response.data;
  },
  publish: async (id, status) => {
    const response = await api.put(`/admin/movies/${id}`, { isPublished: status });
    return response.data;
  }
};

export const tvService = {
  getAll: async () => {
    const response = await api.get('/admin/movies?isTvShow=true&paginate=false');
    return response.data;
  },
  create: async (data) => {
    const response = await api.post('/admin/movies', { ...data, isTvShow: true });
    return response.data;
  }
};

export const systemService = {
  getConfig: async () => {
    const response = await api.get('/admin/config');
    return response.data;
  },
  updateConfig: async (config) => {
    const response = await api.post('/admin/config', config);
    return response.data;
  },
  getStats: async () => {
    const response = await api.get('/admin/stats');
    return response.data;
  }
};

export default api;
