import React, { useEffect, useState, useCallback } from 'react';
import { Box, Typography, Table, TableHead, TableRow, TableCell, TableBody, Button, Dialog, DialogTitle, DialogContent, TextField, DialogActions, Chip, MenuItem, Snackbar, Alert } from '@mui/material';
import api from '../api';

function Coupons() {
  const [coupons, setCoupons] = useState([]);
  const [restaurants, setRestaurants] = useState([]);
  const [agents, setAgents] = useState([]);
  const [selectedRestaurant, setSelectedRestaurant] = useState('');
  const [selectedAgent, setSelectedAgent] = useState('');
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [editingCoupon, setEditingCoupon] = useState(null);
  const [formData, setFormData] = useState({ code: '', description: '', discount_percent: '', discount_amount: '', valid_from: '', valid_until: '', max_uses: '', restaurant_id: '', delivery_agent_id: '' });
  const [snack, setSnack] = useState({ open: false, message: '', severity: 'success' });

  const showSnack = (message, severity = 'success') => setSnack({ open: true, message, severity });

  const loadCoupons = useCallback(async () => {
    setLoading(true);
    try {
      let url = '/coupon';
      const params = [];
      if (selectedRestaurant) params.push(`restaurant_id=${selectedRestaurant}`);
      if (selectedAgent) params.push(`agent_id=${selectedAgent}`);
      if (params.length) url += '?' + params.join('&');
      const res = await api.get(url);
      setCoupons(res.data || []);
    } catch (e) {
      showSnack('Failed to load coupons', 'error');
    }
    setLoading(false);
  }, [selectedRestaurant, selectedAgent]);

  const loadRestaurants = useCallback(async () => {
    try {
      const res = await api.get('/restaurant');
      setRestaurants(res.data || []);
    } catch (e) {
      showSnack('Failed to load restaurants', 'error');
    }
  }, []);

  const loadAgents = useCallback(async () => {
    try {
      const res = await api.get('/delivery-agent');
      setAgents(res.data || []);
    } catch (e) {
      showSnack('Failed to load agents', 'error');
    }
  }, []);

  useEffect(() => {
    loadCoupons();
    loadRestaurants();
    loadAgents();
  }, [loadCoupons, loadRestaurants, loadAgents]);

  const handleOpen = (coupon = null) => {
    setEditingCoupon(coupon);
    setFormData(coupon || { code: '', description: '', discount_percent: '', discount_amount: '', valid_from: '', valid_until: '', max_uses: '', restaurant_id: '', delivery_agent_id: '' });
    setOpen(true);
  };

  const handleClose = () => {
    setOpen(false);
    setEditingCoupon(null);
  };

  const handleSave = async () => {
    try {
      if (editingCoupon) {
        await api.put(`/coupon/${editingCoupon.id}`, formData);
        showSnack('Coupon updated');
      } else {
        await api.post('/coupon', formData);
        showSnack('Coupon created');
      }
      loadCoupons();
      handleClose();
    } catch (e) {
      showSnack(editingCoupon ? 'Failed to update coupon' : 'Failed to create coupon', 'error');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Delete this coupon?')) {
      try {
        await api.delete(`/coupon/${id}`);
        showSnack('Coupon deleted');
        loadCoupons();
      } catch (e) {
        showSnack('Failed to delete coupon', 'error');
      }
    }
  };

  if (loading) return <Typography>Loading...</Typography>;

  return (
    <Box p={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h4">Coupons</Typography>
        <Button variant="contained" onClick={() => handleOpen()}>Create Coupon</Button>
      </Box>
      <Box display="flex" gap={2} mb={2}>
        <TextField select size="small" label="Filter by Restaurant" value={selectedRestaurant} onChange={(e) => setSelectedRestaurant(e.target.value)}>
          <MenuItem value="">All Restaurants</MenuItem>
          {restaurants.map((r) => <MenuItem key={r.id} value={r.id}>{r.name}</MenuItem>)}
        </TextField>
        <TextField select size="small" label="Filter by Agent" value={selectedAgent} onChange={(e) => setSelectedAgent(e.target.value)}>
          <MenuItem value="">All Agents</MenuItem>
          {agents.map((a) => <MenuItem key={a.id} value={a.id}>{a.full_name || a.name}</MenuItem>)}
        </TextField>
      </Box>
      <Table>
        <TableHead>
          <TableRow>
            <TableCell>Code</TableCell>
            <TableCell>Description</TableCell>
            <TableCell>Target</TableCell>
            <TableCell>Discount</TableCell>
            <TableCell>Status</TableCell>
            <TableCell>Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {coupons.map((c) => {
            const restaurant = restaurants.find(r => r.id === c.restaurant_id);
            const agent = agents.find(a => a.id === c.delivery_agent_id);
            return (
              <TableRow key={c.id}>
                <TableCell>{c.code}</TableCell>
                <TableCell>{c.description}</TableCell>
                <TableCell>
                  {c.restaurant_id ? `Restaurant: ${restaurant?.name || c.restaurant_id}` : c.delivery_agent_id ? `Agent: ${agent?.full_name || c.delivery_agent_id}` : 'Global'}
                </TableCell>
                <TableCell>
                  {c.discount_percent ? `${c.discount_percent}%` : c.discount_amount ? `$${c.discount_amount}` : '-'}
                </TableCell>
                <TableCell>
                  <Chip label={c.is_active ? 'Active' : 'Inactive'} color={c.is_active ? 'success' : 'default'} size="small" />
                </TableCell>
                <TableCell>
                  <Button size="small" onClick={() => handleOpen(c)}>Edit</Button>
                  <Button size="small" color="error" onClick={() => handleDelete(c.id)}>Delete</Button>
                </TableCell>
              </TableRow>
            );
          })}
        </TableBody>
      </Table>
      <Dialog open={open} onClose={handleClose}>
        <DialogTitle>{editingCoupon ? 'Edit Coupon' : 'Create Coupon'}</DialogTitle>
        <DialogContent>
          <TextField fullWidth margin="dense" label="Code" value={formData.code} onChange={(e) => setFormData({...formData, code: e.target.value})} />
          <TextField fullWidth margin="dense" label="Description" value={formData.description} onChange={(e) => setFormData({...formData, description: e.target.value})} />
          <TextField fullWidth margin="dense" label="Discount Percent" value={formData.discount_percent} onChange={(e) => setFormData({...formData, discount_percent: e.target.value})} />
          <TextField fullWidth margin="dense" label="Discount Amount" value={formData.discount_amount} onChange={(e) => setFormData({...formData, discount_amount: e.target.value})} />
          <TextField fullWidth margin="dense" select label="Restaurant" value={formData.restaurant_id} onChange={(e) => setFormData({...formData, restaurant_id: e.target.value})}>
            <MenuItem value="">Global</MenuItem>
            {restaurants.map((r) => <MenuItem key={r.id} value={r.id}>{r.name}</MenuItem>)}
          </TextField>
          <TextField fullWidth margin="dense" select label="Delivery Agent" value={formData.delivery_agent_id} onChange={(e) => setFormData({...formData, delivery_agent_id: e.target.value})}>
            <MenuItem value="">None</MenuItem>
            {agents.map((a) => <MenuItem key={a.id} value={a.id}>{a.full_name || a.name}</MenuItem>)}
          </TextField>
          <TextField fullWidth margin="dense" label="Valid From" type="date" InputLabelProps={{shrink: true}} value={formData.valid_from} onChange={(e) => setFormData({...formData, valid_from: e.target.value})} />
          <TextField fullWidth margin="dense" label="Valid Until" type="date" InputLabelProps={{shrink: true}} value={formData.valid_until} onChange={(e) => setFormData({...formData, valid_until: e.target.value})} />
          <TextField fullWidth margin="dense" label="Max Uses" value={formData.max_uses} onChange={(e) => setFormData({...formData, max_uses: e.target.value})} />
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

export default Coupons;