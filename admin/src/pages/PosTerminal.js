import React, { useEffect, useState } from 'react';
import {
  Typography,
  Paper,
  Grid,
  Button,
  Chip,
  TextField,
  Divider,
  List,
  ListItem,
  ListItemText,
  Box,
} from '@mui/material';
import { fetchOrders, fetchNotifications, updateOrder } from '../api';

function PosTerminal() {
  const [orders, setOrders] = useState([]);
  const [notifications, setNotifications] = useState([]);
  const [quickItem, setQuickItem] = useState('Espresso');
  const [table, setTable] = useState('1');

  useEffect(() => {
    refreshOrders();
    refreshNotifications();
  }, []);

  const refreshOrders = async () => {
    const response = await fetchOrders();
    setOrders(response.data);
  };

  const refreshNotifications = async () => {
    const response = await fetchNotifications();
    setNotifications(response.data.slice(0, 5));
  };

  const acceptOrder = async (order) => {
    await updateOrder(order.id, { ...order, status: 'accepted' });
    refreshOrders();
  };

  return (
    <div>
      <Typography variant="h4" gutterBottom>
        POS Terminal
      </Typography>
      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2, mb: 2 }}>
            <Typography variant="h6">Quick Sale</Typography>
            <TextField
              value={quickItem}
              onChange={(e) => setQuickItem(e.target.value)}
              fullWidth
              label="Item name"
              margin="normal"
            />
            <TextField
              value={table}
              onChange={(e) => setTable(e.target.value)}
              fullWidth
              label="Table / Register"
              margin="normal"
            />
            <Button variant="contained" color="primary" sx={{ mt: 1 }}>
              Add to POS Order
            </Button>
            <Typography sx={{ mt: 2 }}>
              Use this area for fast in-store checkout, split billing and quick items.
            </Typography>
          </Paper>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6">Online Order Alerts</Typography>
            <List>
              {notifications.length === 0 && <Typography>No alerts yet.</Typography>}
              {notifications.map((notification) => (
                <ListItem key={notification.id} divider>
                  <ListItemText
                    primary={notification.title}
                    secondary={notification.message}
                  />
                  <Chip label={notification.category} />
                </ListItem>
              ))}
            </List>
          </Paper>
        </Grid>
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6">Incoming Online Orders</Typography>
            <Divider sx={{ my: 1 }} />
            {orders.length === 0 && <Typography>No active orders.</Typography>}
            <List>
              {orders.slice(0, 8).map((order) => (
                <ListItem key={order.id} alignItems="flex-start" divider>
                  <ListItemText
                    primary={`Order #${order.id} — ${order.status}`}
                    secondary={`Restaurant: ${order.restaurant_id} · Total: $${order.total} · Type: ${order.order_type}`}
                  />
                  {order.status === 'pending' && (
                    <Button variant="contained" size="small" onClick={() => acceptOrder(order)}>
                      Accept
                    </Button>
                  )}
                </ListItem>
              ))}
            </List>
          </Paper>
        </Grid>
      </Grid>
    </div>
  );
}

export default PosTerminal;
