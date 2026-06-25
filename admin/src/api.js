import axios from 'axios';

const api = axios.create({
  baseURL: process.env.REACT_APP_API_BASE_URL || 'http://127.0.0.1:8000/v1',
  headers: {
    'Content-Type': 'application/json',
  },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

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
export const updateDeliveryAgentPrice = (id, pricePerKm, isFixed, fixedPrice) => api.patch(`/delivery-agent/${id}/price`, { price_per_km: pricePerKm, is_fixed_price: isFixed ? 1 : 0, fixed_price: fixedPrice });
export const deleteDeliveryAgent = (id) => api.delete(`/delivery-agent/${id}`);

export const fetchNotifications = () => api.get('/notification');
export const createNotification = (notification) => api.post('/notification', notification);
export const updateNotification = (id, notification) => api.put(`/notification/${id}`, notification);
export const deleteNotification = (id) => api.delete(`/notification/${id}`);

export const fetchUsers = () => api.get('/user');
export const createUser = (user) => api.post('/user', user);
export const updateUser = (id, user) => api.put(`/user/${id}`, user);
export const deleteUser = (id) => api.delete(`/user/${id}`);

export const fetchKycRecords = () => api.get('/kyc');
export const approveKyc = (id) => api.put(`/kyc/${id}`, { status: 'approved' });
export const rejectKyc = (id) => api.put(`/kyc/${id}`, { status: 'rejected' });

export const fetchCities = () => api.get('/city');
export const createCity = (city) => api.post('/city', city);
export const updateCity = (id, city) => api.put(`/city/${id}`, city);
export const deleteCity = (id) => api.delete(`/city/${id}`);

export const fetchCoupons = () => api.get('/coupon');
export const createCoupon = (coupon) => api.post('/coupon', coupon);
export const updateCoupon = (id, coupon) => api.put(`/coupon/${id}`, coupon);
export const deleteCoupon = (id) => api.delete(`/coupon/${id}`);

export const fetchAds = () => api.get('/ad');
export const createAd = (ad) => api.post('/ad', ad);
export const updateAd = (id, ad) => api.put(`/ad/${id}`, ad);
export const deleteAd = (id) => api.delete(`/ad/${id}`);
export const approveAd = (id) => api.patch(`/ad/${id}/approve`);
export const rejectAd = (id, remark) => api.patch(`/ad/${id}/reject`, { admin_remark: remark });

export const fetchSystemSettings = () => api.get('/settings');
export const updateSystemSetting = (key, value) => api.post('/settings', { setting_key: key, setting_value: value });

export const fetchPriceRequests = () => api.get('/price-request');
export const approvePriceRequest = (id) => api.put(`/price-request/${id}`, { status: 'approved' });
export const rejectPriceRequest = (id, remark) => api.put(`/price-request/${id}`, { status: 'rejected', admin_remark: remark });

export default api;