import React from 'react';
import { Routes, Route, Navigate, useLocation } from 'react-router-dom';
import { CssBaseline, Box } from '@mui/material';
import Sidebar from './components/Sidebar';
import Dashboard from './pages/Dashboard';
import Restaurants from './pages/Restaurants';
import Orders from './pages/Orders';
import MenuManager from './pages/MenuManager';
import DeliveryAgents from './pages/DeliveryAgents';
import Users from './pages/Users';
import Kyc from './pages/Kyc';
import Login from './pages/Login';
import PosTerminal from './pages/PosTerminal';
import NotificationsPage from './pages/Notifications';
import Cities from './pages/Cities';
import Coupons from './pages/Coupons';
import Ads from './pages/Ads';
import Settings from './pages/Settings';
import PriceRequests from './pages/PriceRequests';
import api from './api';

function RequireAuth({ children }) {
  const location = useLocation();
  const token = localStorage.getItem('access_token');
  if (!token) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }
  return children;
}

function App() {
  const token = localStorage.getItem('access_token');
  if (token) {
    api.defaults.headers.Authorization = `Bearer ${token}`;
  }

  return (
    <Box sx={{ display: 'flex' }}>
      <CssBaseline />
      <Sidebar />
      <Box component="main" sx={{ flexGrow: 1, p: 3, ml: '240px' }}>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route
            path="/dashboard"
            element={
              <RequireAuth>
                <Dashboard />
              </RequireAuth>
            }
          />
          <Route
            path="/restaurants"
            element={
              <RequireAuth>
                <Restaurants />
              </RequireAuth>
            }
          />
          <Route
            path="/orders"
            element={
              <RequireAuth>
                <Orders />
              </RequireAuth>
            }
          />
          <Route
            path="/menu-manager"
            element={
              <RequireAuth>
                <MenuManager />
              </RequireAuth>
            }
          />
          <Route
            path="/delivery-agents"
            element={
              <RequireAuth>
                <DeliveryAgents />
              </RequireAuth>
            }
          />
          <Route
            path="/users"
            element={
              <RequireAuth>
                <Users />
              </RequireAuth>
            }
          />
          <Route
            path="/kyc"
            element={
              <RequireAuth>
                <Kyc />
              </RequireAuth>
            }
          />
          <Route
            path="/pos"
            element={
              <RequireAuth>
                <PosTerminal />
              </RequireAuth>
            }
          />
          <Route
            path="/notifications"
            element={
              <RequireAuth>
                <NotificationsPage />
              </RequireAuth>
            }
          />
          <Route
            path="/cities"
            element={
              <RequireAuth>
                <Cities />
              </RequireAuth>
            }
          />
          <Route
            path="/coupons"
            element={
              <RequireAuth>
                <Coupons />
              </RequireAuth>
            }
          />
          <Route
            path="/ads"
            element={
              <RequireAuth>
                <Ads />
              </RequireAuth>
            }
          />
          <Route
            path="/settings"
            element={
              <RequireAuth>
                <Settings />
              </RequireAuth>
            }
          />
          <Route
            path="/price-requests"
            element={
              <RequireAuth>
                <PriceRequests />
              </RequireAuth>
            }
          />
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </Box>
    </Box>
  );
}

export default App;