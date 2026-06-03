import React, { useEffect, useState } from 'react';
import {
  Typography,
  Paper,
  List,
  ListItem,
  ListItemText,
  Chip,
  Button,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
} from '@mui/material';
import { fetchOrders, updateOrder } from '../api';

function Orders() {
  const [orders, setOrders] = useState([]);

  const loadOrders = async () => {
    const response = await fetchOrders();
    setOrders(response.data || []);
  };

  useEffect(() => {
    loadOrders();
  }, []);

  const handleStatus = async (order, status) => {
    await updateOrder(order.id, { ...order, status });
    loadOrders();
  };
  return (
    <div>
      <Typography variant="h4" gutterBottom>
        Orders
      </Typography>
      <Paper>
        <List>
          {orders.map((order) => (
            <ListItem key={order.id} divider>
              <ListItemText
                primary={`Order #${order.id}`}
                secondary={`Status: ${order.status} · Restaurant: ${order.restaurant_id} · Total: $${order.total}`}
              />
              <Chip label={order.order_type} sx={{ mr: 1 }} />
              <FormControl sx={{ minWidth: 140 }} size="small">
                <InputLabel>Status</InputLabel>
                <Select
                  value={order.status}
                  label="Status"
                  onChange={(e) => handleStatus(order, e.target.value)}
                >
                  {['pending', 'accepted', 'preparing', 'picked_up', 'delivering', 'completed', 'cancelled'].map((status) => (
                    <MenuItem key={status} value={status}>{status}</MenuItem>
                  ))}
                </Select>
              </FormControl>
            </ListItem>
          ))}
        </List>
      </Paper>
    </div>
  );
}

export default Orders;
