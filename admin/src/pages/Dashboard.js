import React from 'react';
import { Typography, Grid, Paper } from '@mui/material';

function Dashboard() {
  return (
    <div>
      <Typography variant="h4" gutterBottom>
        Bitedash Admin Dashboard
      </Typography>
      <Grid container spacing={3}>
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 2 }}>Total restaurants, orders, revenue, delivery agents</Paper>
        </Grid>
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 2 }}>Recent orders and deliveries</Paper>
        </Grid>
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 2 }}>Pending KYC &amp; restaurant approvals</Paper>
        </Grid>
      </Grid>
    </div>
  );
}

export default Dashboard;
