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
  ListItemAvatar,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
  Box,
  CircularProgress,
  MenuItem,
  Avatar,
} from '@mui/material';
import AddIcon from '@mui/icons-material/Add';
import EditIcon from '@mui/icons-material/Edit';
import PhotoCamera from '@mui/icons-material/PhotoCamera';
import api from '../api';

function MenuManager() {
  const [restaurants, setRestaurants] = useState([]);
  const [selectedRestaurant, setSelectedRestaurant] = useState(null);
  const [menuItems, setMenuItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [photoUrl, setPhotoUrl] = useState('');
  const [uploading, setUploading] = useState(false);
  const [form, setForm] = useState({ id: null, name: '', price: '', description: '', quantity: '', is_available: true });

  const loadRestaurants = async () => {
    try {
      const response = await api.get('/restaurant');
      setRestaurants(response.data || []);
    } catch (e) {
      console.error('Failed to load restaurants:', e);
    }
  };

  const loadMenuItems = async (restaurantId) => {
    setLoading(true);
    try {
      const response = await api.get(`/menu-item?restaurant_id=${restaurantId}`);
      setMenuItems(response.data || []);
    } catch (e) {
      console.error('Failed to load menu items:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadRestaurants();
  }, []);

  const handleRestaurantChange = (event) => {
    const restaurantId = event.target.value;
    setSelectedRestaurant(restaurantId);
    if (restaurantId) loadMenuItems(restaurantId);
  };

  const openForm = (item) => {
    if (item) {
      setForm({
        id: item.id,
        name: item.name || '',
        price: item.price || '',
        description: item.description || '',
        quantity: item.quantity ?? '',
        is_available: item.is_available === 1 || item.is_available === true,
      });
      setPhotoUrl(item.photo_url || '');
    } else {
      setForm({ id: null, name: '', price: '', description: '', quantity: '', is_available: true });
      setPhotoUrl('');
    }
    setOpen(true);
  };

  const handleUpload = async (event) => {
    const file = event.target.files[0];
    if (!file) return;
    setUploading(true);
    try {
      const response = await api.uploadFile(file, 'menu-item/upload');
      setPhotoUrl(response.url);
    } catch (e) {
      console.error('Upload failed:', e);
    } finally {
      setUploading(false);
    }
  };

  const handleSave = async () => {
    const payload = {
      restaurant_id: selectedRestaurant,
      name: form.name,
      price: parseFloat(form.price) || 0,
      description: form.description,
      quantity: form.quantity === '' ? null : parseInt(form.quantity),
      is_available: form.is_available ? 1 : 0,
      photo_url: photoUrl,
    };
    if (form.id) {
      await api.put(`/menu-item/${form.id}`, payload);
    } else {
      await api.post('/menu-item', payload);
    }
    setOpen(false);
    loadMenuItems(selectedRestaurant);
  };

  return (
    <div>
      <Typography variant="h4" gutterBottom fontWeight="bold">
        Menu Management
      </Typography>
      <Grid container spacing={3}>
        <Grid item xs={12}>
          <TextField
            select
            fullWidth
            label="Select Restaurant"
            value={selectedRestaurant || ''}
            onChange={handleRestaurantChange}
          >
            <MenuItem value="">Select a restaurant...</MenuItem>
            {restaurants.map((r) => (
              <MenuItem key={r.id} value={r.id}>{r.name}</MenuItem>
            ))}
          </TextField>
        </Grid>
        {selectedRestaurant && (
          <Grid item xs={12}>
            <Paper sx={{ p: 2 }}>
              <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                <Typography variant="h6">Menu Items</Typography>
                <Button variant="contained" startIcon={<AddIcon />} onClick={() => openForm(null)}>
                  Add Item
                </Button>
              </Box>
              {loading ? (
                <Box display="flex" justifyContent="center" py={4}>
                  <CircularProgress />
                </Box>
              ) : (
                <List>
{menuItems.length === 0 ? (
                    <ListItem>
                      <ListItemText primary="No menu items yet. Add your first item!" />
                    </ListItem>
                  ) : (
                    menuItems.map((item) => (
                      <ListItem key={item.id} divider secondaryAction={
                        <IconButton edge="end" aria-label="edit" onClick={() => openForm(item)}>
                          <EditIcon />
                        </IconButton>
                      }>
                        {item.photo_url && (
                          <ListItemAvatar>
                            <Avatar src={item.photo_url} variant="rounded" sx={{ width: 64, height: 64, mr: 1 }} />
                          </ListItemAvatar>
                        )}
                        <ListItemText
                          primary={item.name}
                          secondary={`$${item.price} | ${item.quantity != null ? `Qty: ${item.quantity}` : 'Unlimited'} | ${item.is_available ? 'Available' : 'Sold Out'}`}
                        />
                      </ListItem>
                    ))
                  )}
                </List>
              )}
            </Paper>
          </Grid>
        )}
      </Grid>

      <Dialog open={open} onClose={() => setOpen(false)}>
        <DialogTitle>{form.id ? 'Edit Menu Item' : 'New Menu Item'}</DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            label="Name"
            margin="dense"
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
          />
          <TextField
            fullWidth
            label="Price"
            margin="dense"
            type="number"
            value={form.price}
            onChange={(e) => setForm({ ...form, price: e.target.value })}
          />
          <TextField
            fullWidth
            label="Description"
            margin="dense"
            multiline
            rows={2}
            value={form.description}
            onChange={(e) => setForm({ ...form, description: e.target.value })}
          />
          <TextField
            fullWidth
            label="Quantity (leave empty for unlimited)"
            margin="dense"
            type="number"
            value={form.quantity}
            onChange={(e) => setForm({ ...form, quantity: e.target.value })}
          />
          <TextField
            select
            fullWidth
            label="Available"
            margin="dense"
            value={form.is_available ? '1' : '0'}
            onChange={(e) => setForm({ ...form, is_available: e.target.value === '1' })}
          >
            <MenuItem value="1">Yes</MenuItem>
            <MenuItem value="0">No</MenuItem>
          </TextField>
          <Box mt={2} display="flex" alignItems="center" gap={2}>
            <Avatar src={photoUrl} variant="rounded" sx={{ width: 64, height: 64, bgcolor: 'grey.200' }}>
              <PhotoCamera />
            </Avatar>
            <Button
              variant="outlined"
              component="label"
              disabled={uploading}
              startIcon={uploading ? <CircularProgress size={20} /> : <PhotoCamera />}
            >
              {photoUrl ? 'Change Photo' : 'Upload Photo'}
              <input hidden type="file" accept="image/*" onChange={handleUpload} />
            </Button>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleSave}>Save</Button>
        </DialogActions>
      </Dialog>
    </div>
  );
}

export default MenuManager;