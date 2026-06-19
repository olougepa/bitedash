import axios from 'axios';

const api = axios.create({
  baseURL: process.env.REACT_APP_API_BASE_URL || 'http://127.0.0.1:8000/v1',
  headers: {
    'Content-Type': 'application/json',
  },
});

// attach access token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// response interceptor to handle refresh
let isRefreshing = false;
let refreshSubscribers = [];

function onRefreshed(token) {
  refreshSubscribers.map((cb) => cb(token));
}

function addRefreshSubscriber(cb) {
  refreshSubscribers.push(cb);
}

api.interceptors.response.use(
  (res) => res,
  async (err) => {
    const original = err.config;
    if (err.response && err.response.status === 401 && !original._retry) {
      original._retry = true;
      if (isRefreshing) {
        return new Promise((resolve) => {
          addRefreshSubscriber((token) => {
            original.headers.Authorization = `Bearer ${token}`;
            resolve(axios(original));
          });
        });
      }
      isRefreshing = true;
      const refresh = localStorage.getItem('refresh_token');
      try {
        const r = await api.post('/auth/refresh', { refresh_token: refresh });
        const newAccess = r.data.access_token;
        const newRefresh = r.data.refresh_token;
        localStorage.setItem('access_token', newAccess);
        if (newRefresh) localStorage.setItem('refresh_token', newRefresh);
        api.defaults.headers.Authorization = `Bearer ${newAccess}`;
        onRefreshed(newAccess);
        refreshSubscribers = [];
        isRefreshing = false;
        original.headers.Authorization = `Bearer ${newAccess}`;
        return axios(original);
      } catch (e) {
        isRefreshing = false;
        // failed refresh, redirect to login
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        window.location.href = '/login';
        return Promise.reject(e);
      }
    }
    return Promise.reject(err);
  }
);

export const login = (email, password) => api.post('/auth/login', { email, password }).then((r) => {
  const data = r.data;
  if (data.access_token) {
    localStorage.setItem('access_token', data.access_token);
    if (data.refresh_token) localStorage.setItem('refresh_token', data.refresh_token);
    api.defaults.headers.Authorization = `Bearer ${data.access_token}`;
  }
  return data;
});

export const logout = () => {
  localStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');
  api.defaults.headers.Authorization = null;
};

export const fetchDashboard = () => api.get('/admin/dashboard');
export const fetchRestaurants = () => api.get('/restaurant');
export const createRestaurant = (restaurant) => api.post('/restaurant', restaurant);
export const updateRestaurant = (id, restaurant) => api.put(`/restaurant/${id}`, restaurant);
export const deleteRestaurant = (id) => api.delete(`/restaurant/${id}`);

export const fetchOrders = () => api.get('/order');
export const updateOrder = (id, order) => api.put(`/order/${id}`, order);
export const deleteOrder = (id) => api.delete(`/order/${id}`);

export const fetchDeliveryAgents = () => api.get('/delivery-agent');
export const createDeliveryAgent = (agent) => api.post('/delivery-agent', agent);
export const updateDeliveryAgent = (id, agent) => api.put(`/delivery-agent/${id}`, agent);
export const deleteDeliveryAgent = (id) => api.delete(`/delivery-agent/${id}`);

export const fetchNotifications = () => api.get('/notification');
export const createNotification = (notification) => api.post('/notification', notification);
export const updateNotification = (id, notification) => api.put(`/notification/${id}`, notification);
export const deleteNotification = (id) => api.delete(`/notification/${id}`);

export default api;
