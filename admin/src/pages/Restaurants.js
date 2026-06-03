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
} from '@mui/material';
import DeleteIcon from '@mui/icons-material/Delete';
import EditIcon from '@mui/icons-material/Edit';
import {
  fetchRestaurants,
  createRestaurant,
  updateRestaurant,
  deleteRestaurant,
} from '../api';

function Restaurants() {
  const [restaurants, setRestaurants] = useState([]);
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ id: null, name: '', description: '', address: '' });

  const loadRestaurants = async () => {
    const response = await fetchRestaurants();
    setRestaurants(response.data || []);
  };

  useEffect(() => {
    loadRestaurants();
  }, []);

  const openForm = (restaurant) => {
    if (restaurant) {
      setForm({
        id: restaurant.id,
        name: restaurant.name || '',
        description: restaurant.description || '',
        address: restaurant.address || '',
      });
    } else {
      setForm({ id: null, name: '', description: '', address: '' });
    }
    setOpen(true);
  };

  const handleSave = async () => {
    const payload = {
      name: form.name,
      description: form.description,
      address: form.address,
    };
    if (form.id) {
      await updateRestaurant(form.id, payload);
    } else {
      await createRestaurant(payload);
    }
    setOpen(false);
    loadRestaurants();
  };

  const handleDelete = async (id) => {
    await deleteRestaurant(id);
    loadRestaurants();
  };
  return (
    <div>
      <Typography variant="h4" gutterBottom>
        Restaurants
      </Typography>
      <Button variant="contained" color="primary" sx={{ mb: 2 }} onClick={() => openForm(null)}>
        Add Restaurant
      </Button>
      <Paper>
        <List>
          {restaurants.map((restaurant) => (
            <ListItem key={restaurant.id} secondaryAction={
              <>
                <IconButton edge="end" aria-label="edit" onClick={() => openForm(restaurant)}>
                  <EditIcon />
                </IconButton>
                <IconButton edge="end" aria-label="delete" onClick={() => handleDelete(restaurant.id)}>
                  <DeleteIcon />
                </IconButton>
              </>
            }>
              <ListItemText
                primary={restaurant.name}
                secondary={`${restaurant.description || 'No description'} · ${restaurant.address || 'No address'}`}
              />
            </ListItem>
          ))}
        </List>
      </Paper>

      <Dialog open={open} onClose={() => setOpen(false)}>
        <DialogTitle>{form.id ? 'Edit Restaurant' : 'New Restaurant'}</DialogTitle>
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
            label="Description"
            margin="dense"
            value={form.description}
            onChange={(e) => setForm({ ...form, description: e.target.value })}
          />
          <TextField
            fullWidth
            label="Address"
            margin="dense"
            value={form.address}
            onChange={(e) => setForm({ ...form, address: e.target.value })}
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

export default Restaurants;
