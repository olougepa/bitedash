import React, { useEffect, useState } from 'react';
import { Typography, Grid, Paper, Box, CircularProgress } from '@mui/material';
import api from '../api';

function Dashboard() {
  const [stats, setStats] = useState({ restaurants: 0, orders: 0, users: 0, agents: 0 });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchStats() {
      setLoading(true);
      try {
        const [restaurantsRes, ordersRes, usersRes, agentsRes] = await Promise.all([
          api.get('/restaurant'),
          api.get('/order'),
          api.get('/user'),
          api.get('/delivery-agent'),
        ]);
        setStats({
          restaurants: restaurantsRes.data?.length ?? 0,
          orders: ordersRes.data?.length ?? 0,
          users: usersRes.data?.length ?? 0,
          agents: agentsRes.data?.length ?? 0,
        });
      } catch (e) {
        console.error('Failed to load stats:', e);
      } finally {
        setLoading(false);
      }
    }
    fetchStats();
  }, []);

  const StatCard = ({ title, value, color = 'primary' }) => (
    <Paper sx={{ p: 3, textAlign: 'center', background: `linear-gradient(135deg, ${color === 'primary' ? '#ff9800' : '#2196f3'} 0%, ${color === 'primary' ? '#ff5722' : '#03a9f4'} 100%)`, color: 'white' }}>
      <Typography variant="h3" component="div">{loading ? <CircularProgress size={24} color="inherit" /> : value}</Typography>
      <Typography variant="subtitle1">{title}</Typography>
    </Paper>
  );

  return (
    <div>
      <Typography variant="h4" gutterBottom fontWeight="bold">
        Bitedash Admin Dashboard
      </Typography>
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard title="Restaurants" value={stats.restaurants} color="primary" />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard title="Orders" value={stats.orders} color="secondary" />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard title="Users" value={stats.users} color="default" />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard title="Delivery Agents" value={stats.agents} color="secondary" />
        </Grid>
      </Grid>
      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>Recent Orders</Typography>
            <Box height={200}>Activity feed coming soon...</Box>
          </Paper>
        </Grid>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>System Health</Typography>
            <Box height={200}>All systems operational</Box>
          </Paper>
        </Grid>
      </Grid>
    </div>
  );
}

export default Dashboard;