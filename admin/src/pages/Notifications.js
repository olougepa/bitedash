import React, { useEffect, useState } from 'react';
import {
  Typography,
  Paper,
  List,
  ListItem,
  ListItemText,
  Chip,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
} from '@mui/material';
import { fetchNotifications, createNotification, deleteNotification } from '../api';

function NotificationsPage() {
  const [notifications, setNotifications] = useState([]);
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ title: '', message: '', category: 'all' });

  const loadNotifications = async () => {
    const response = await fetchNotifications();
    setNotifications(response.data || []);
  };

  useEffect(() => {
    loadNotifications();
  }, []);

  const handleSave = async () => {
    await createNotification(form);
    setOpen(false);
    setForm({ title: '', message: '', category: 'all' });
    loadNotifications();
  };

  return (
    <div>
      <Typography variant="h4" gutterBottom>
        Notifications
      </Typography>
      <Button variant="contained" color="primary" sx={{ mb: 2 }} onClick={() => setOpen(true)}>
        Create Alert
      </Button>
      <Paper>
        <List>
          {notifications.map((notification) => (
            <ListItem key={notification.id} divider>
              <ListItemText
                primary={notification.title}
                secondary={`${notification.message} · ${notification.category}`}
              />
              <Chip label={notification.category} />
              <Button color="error" onClick={() => deleteNotification(notification.id)}>
                Delete
              </Button>
            </ListItem>
          ))}
        </List>
      </Paper>
      <Dialog open={open} onClose={() => setOpen(false)}>
        <DialogTitle>Create Notification</DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            label="Title"
            margin="dense"
            value={form.title}
            onChange={(e) => setForm({ ...form, title: e.target.value })}
          />
          <TextField
            fullWidth
            label="Message"
            margin="dense"
            value={form.message}
            onChange={(e) => setForm({ ...form, message: e.target.value })}
          />
          <TextField
            fullWidth
            label="Category"
            margin="dense"
            value={form.category}
            onChange={(e) => setForm({ ...form, category: e.target.value })}
            helperText="customer, restaurant_owner, delivery_agent, admin, all"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleSave}>Save</Button>
        </DialogActions>
      </Dialog>
    </div>
  );
}

export default NotificationsPage;
