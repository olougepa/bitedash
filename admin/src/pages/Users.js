import React, { useEffect, useState } from 'react';
import {
  Typography,
  Paper,
  Grid,
  Button,
  TextField,
  List,
  ListItem,
  ListItemText,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
  Box,
  CircularProgress,
  MenuItem,
} from '@mui/material';
import DeleteIcon from '@mui/icons-material/Delete';
import EditIcon from '@mui/icons-material/Edit';
import api from '../api';

function Users() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ id: null, email: '', full_name: '', role: 'customer', status: 'active' });

  const loadUsers = async () => {
    setLoading(true);
    try {
      const response = await api.get('/user');
      setUsers(response.data || []);
    } catch (e) {
      console.error('Failed to load users:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadUsers();
  }, []);

  const getRoleColor = (role) => {
    switch (role) {
      case 'admin': return 'error';
      case 'restaurant_owner': return 'warning';
      case 'delivery_agent': return 'info';
      default: return 'success';
    }
  };

  const openForm = (user) => {
    if (user) {
      setForm({
        id: user.id,
        email: user.email || '',
        full_name: user.full_name || '',
        role: user.role || 'customer',
        status: user.status || 'active',
      });
    } else {
      setForm({ id: null, email: '', full_name: '', role: 'customer', status: 'active' });
    }
    setOpen(true);
  };

  const handleSave = async () => {
    const payload = {
      email: form.email,
      full_name: form.full_name,
      role: form.role,
      status: form.status,
    };
    if (form.id) {
      await api.put(`/user/${form.id}`, payload);
    } else {
      await api.post('/user', payload);
    }
    setOpen(false);
    loadUsers();
  };

  const handleDelete = async (id) => {
    if (window.confirm('Delete this user?')) {
      await api.delete(`/user/${id}`);
      loadUsers();
    }
  };

  return (
    <div>
      <Typography variant="h4" gutterBottom fontWeight="bold">
        Users
      </Typography>
      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Paper sx={{ p: 2 }}>
            {loading ? (
              <Box display="flex" justifyContent="center" py={4}>
                <CircularProgress />
              </Box>
            ) : (
              <List>
                {users.map((user) => (
                  <ListItem key={user.id} divider secondaryAction={
                    <>
                      <IconButton edge="end" aria-label="edit" onClick={() => openForm(user)}>
                        <EditIcon />
                      </IconButton>
                      <IconButton edge="end" aria-label="delete" onClick={() => handleDelete(user.id)}>
                        <DeleteIcon />
                      </IconButton>
                    </>
                  }>
                    <ListItemText
                      primary={
                        <Box display="flex" alignItems="center" gap={1}>
                          {user.full_name || 'Unnamed'}
                          <Chip label={user.role} color={getRoleColor(user.role)} size="small" />
                          <Chip label={user.status} variant="outlined" size="small" />
                        </Box>
                      }
                      secondary={user.email}
                    />
                  </ListItem>
                ))}
              </List>
            )}
          </Paper>
        </Grid>
      </Grid>

      <Dialog open={open} onClose={() => setOpen(false)}>
        <DialogTitle>{form.id ? 'Edit User' : 'New User'}</DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            label="Email"
            margin="dense"
            value={form.email}
            onChange={(e) => setForm({ ...form, email: e.target.value })}
          />
          <TextField
            fullWidth
            label="Full Name"
            margin="dense"
            value={form.full_name}
            onChange={(e) => setForm({ ...form, full_name: e.target.value })}
          />
          <TextField
            select
            fullWidth
            label="Role"
            margin="dense"
            value={form.role}
            onChange={(e) => setForm({ ...form, role: e.target.value })}
          >
            <MenuItem value="customer">Customer</MenuItem>
            <MenuItem value="restaurant_owner">Restaurant Owner</MenuItem>
            <MenuItem value="delivery_agent">Delivery Agent</MenuItem>
            <MenuItem value="admin">Admin</MenuItem>
          </TextField>
          <TextField
            select
            fullWidth
            label="Status"
            margin="dense"
            value={form.status}
            onChange={(e) => setForm({ ...form, status: e.target.value })}
          >
            <MenuItem value="active">Active</MenuItem>
            <MenuItem value="pending">Pending</MenuItem>
            <MenuItem value="suspended">Suspended</MenuItem>
            <MenuItem value="deleted">Deleted</MenuItem>
          </TextField>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleSave}>Save</Button>
        </DialogActions>
      </Dialog>
    </div>
  );
}

export default Users;