import React, { useEffect, useState, useCallback } from 'react';
import { Box, Typography, Table, TableHead, TableRow, TableCell, TableBody, Button, Dialog, DialogTitle, DialogContent, TextField, DialogActions, Snackbar, Alert } from '@mui/material';
import { fetchCities, createCity, updateCity, deleteCity } from '../api';

function Cities() {
  const [cities, setCities] = useState([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [editingCity, setEditingCity] = useState(null);
  const [formData, setFormData] = useState({ name: '', country: '', latitude: '', longitude: '' });
  const [snack, setSnack] = useState({ open: false, message: '', severity: 'success' });

  const showSnack = (message, severity = 'success') => setSnack({ open: true, message, severity });

  const loadCities = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetchCities();
      setCities(res.data || res || []);
    } catch (e) {
      showSnack('Failed to load cities: ' + (e.response?.data?.message || e.message), 'error');
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    loadCities();
  }, [loadCities]);

  const handleOpen = (city = null) => {
    setEditingCity(city);
    setFormData(city ? { name: city.name || '', country: city.country || '', latitude: city.latitude || '', longitude: city.longitude || '' } : { name: '', country: '', latitude: '', longitude: '' });
    setOpen(true);
  };

  const handleClose = () => {
    setOpen(false);
    setEditingCity(null);
  };

  const handleSave = async () => {
    try {
      if (editingCity) {
        await updateCity(editingCity.id, formData);
        showSnack('City updated');
      } else {
        await createCity(formData);
        showSnack('City created');
      }
      loadCities();
      handleClose();
    } catch (e) {
      const errorMsg = e.response?.data?.errors 
        ? JSON.stringify(e.response.data.errors) 
        : (e.response?.data?.message || e.message || (editingCity ? 'Failed to update city' : 'Failed to create city'));
      showSnack(errorMsg, 'error');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Delete this city?')) {
      try {
        await deleteCity(id);
        showSnack('City deleted');
        loadCities();
      } catch (e) {
        showSnack('Failed to delete city', 'error');
      }
    }
  };

  if (loading) return <Typography>Loading...</Typography>;

  return (
    <Box p={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h4">Cities</Typography>
        <Button variant="contained" onClick={() => handleOpen()}>Add City</Button>
      </Box>
      <Table>
        <TableHead>
          <TableRow>
            <TableCell>ID</TableCell>
            <TableCell>Name</TableCell>
            <TableCell>Country</TableCell>
            <TableCell>Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {cities.map((city) => (
            <TableRow key={city.id}>
              <TableCell>{city.id}</TableCell>
              <TableCell>{city.name}</TableCell>
              <TableCell>{city.country}</TableCell>
              <TableCell>
                <Button size="small" onClick={() => handleOpen(city)}>Edit</Button>
                <Button size="small" color="error" onClick={() => handleDelete(city.id)}>Delete</Button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
      <Dialog open={open} onClose={handleClose}>
        <DialogTitle>{editingCity ? 'Edit City' : 'Add City'}</DialogTitle>
        <DialogContent>
          <TextField fullWidth margin="dense" label="Name" value={formData.name} onChange={(e) => setFormData({...formData, name: e.target.value})} />
          <TextField fullWidth margin="dense" label="Country" value={formData.country} onChange={(e) => setFormData({...formData, country: e.target.value})} />
          <TextField fullWidth margin="dense" label="Latitude" value={formData.latitude} onChange={(e) => setFormData({...formData, latitude: e.target.value})} />
          <TextField fullWidth margin="dense" label="Longitude" value={formData.longitude} onChange={(e) => setFormData({...formData, longitude: e.target.value})} />
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose}>Cancel</Button>
          <Button onClick={handleSave}>Save</Button>
        </DialogActions>
      </Dialog>
      <Snackbar open={snack.open} autoHideDuration={6000} onClose={() => setSnack({ ...snack, open: false })}>
        <Alert severity={snack.severity} onClose={() => setSnack({ ...snack, open: false })}>
          {snack.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}

export default Cities;