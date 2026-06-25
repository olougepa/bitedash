import React, { useEffect, useState, useCallback } from 'react';
import { Box, Typography, Table, TableHead, TableRow, TableCell, TableBody, Button, Dialog, DialogTitle, DialogContent, TextField, DialogActions, Chip, MenuItem, Snackbar, Alert } from '@mui/material';
import { fetchAds, createAd, updateAd, deleteAd, approveAd, rejectAd, fetchUsers, fetchDeliveryAgents } from '../api';

function Ads() {
  const [ads, setAds] = useState([]);
  const [users, setUsers] = useState([]);
  const [agents, setAgents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [editingAd, setEditingAd] = useState(null);
  const [formData, setFormData] = useState({ title: '', description: '', image_url: '', target_type: 'restaurant', status: 'pending', budget: '', start_date: '', end_date: '', owner_id: '', agent_id: '' });
  const [snack, setSnack] = useState({ open: false, message: '', severity: 'success' });

  const showSnack = (message, severity = 'success') => setSnack({ open: true, message, severity });

  const loadAds = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetchAds();
      setAds(res.data || []);
    } catch (e) {
      showSnack('Failed to load ads', 'error');
    }
    setLoading(false);
  }, []);

  const loadUsers = useCallback(async () => {
    try {
      const res = await fetchUsers();
      setUsers(res.data || []);
    } catch (e) {
      showSnack('Failed to load users', 'error');
    }
  }, []);

  const loadAgents = useCallback(async () => {
    try {
      const res = await fetchDeliveryAgents();
      setAgents(res.data || []);
    } catch (e) {
      showSnack('Failed to load delivery agents', 'error');
    }
  }, []);

  useEffect(() => {
    loadAds();
    loadUsers();
    loadAgents();
  }, [loadAds, loadUsers, loadAgents]);

  const handleApprove = async (id) => {
    try {
      await approveAd(id);
      showSnack('Ad approved');
      loadAds();
    } catch (e) {
      showSnack('Failed to approve ad', 'error');
    }
  };

  const handleReject = async (id) => {
    const remark = prompt('Enter rejection remark:');
    if (remark !== null) {
      try {
        await rejectAd(id, remark);
        showSnack('Ad rejected');
        loadAds();
      } catch (e) {
        showSnack('Failed to reject ad', 'error');
      }
    }
  };

  const handleOpen = (ad = null) => {
    setEditingAd(ad);
    setFormData(ad || { title: '', description: '', image_url: '', target_type: 'restaurant', status: 'pending', budget: '', start_date: '', end_date: '', owner_id: '', agent_id: '' });
    setOpen(true);
  };

  const handleClose = () => {
    setOpen(false);
    setEditingAd(null);
  };

  const handleSave = async () => {
    try {
      const cleanedData = { ...formData };
      if (!cleanedData.owner_id) cleanedData.owner_id = null;
      if (!cleanedData.agent_id) cleanedData.agent_id = null;
      if (!cleanedData.budget) cleanedData.budget = null;

      if (editingAd) {
        await updateAd(editingAd.id, cleanedData);
        showSnack('Ad updated');
      } else {
        await createAd(cleanedData);
        showSnack('Ad created');
      }
      loadAds();
      handleClose();
    } catch (e) {
      showSnack(editingAd ? 'Failed to update ad' : 'Failed to create ad', 'error');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Delete this ad?')) {
      try {
        await deleteAd(id);
        showSnack('Ad deleted');
        loadAds();
      } catch (e) {
        showSnack('Failed to delete ad', 'error');
      }
    }
  };

  const restaurantOwners = users.filter(u => u.role === 'restaurant_owner');
  const deliveryAgents = agents;

  if (loading) return <Typography>Loading...</Typography>;

  return (
    <Box p={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h4">Ads Management</Typography>
        <Button variant="contained" onClick={() => handleOpen()}>Create Ad</Button>
      </Box>
      <Table>
        <TableHead>
          <TableRow>
            <TableCell>Title</TableCell>
            <TableCell>Target</TableCell>
            <TableCell>Requester</TableCell>
            <TableCell>Budget (XAF)</TableCell>
            <TableCell>Start Date</TableCell>
            <TableCell>End Date</TableCell>
            <TableCell>Duration</TableCell>
            <TableCell>Status</TableCell>
            <TableCell>Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {ads.map((a) => (
            <TableRow key={a.id}>
              <TableCell>{a.title}</TableCell>
              <TableCell>{a.target_type}</TableCell>
              <TableCell>{a.requester_name || '-'}</TableCell>
              <TableCell>{a.budget ? `${a.budget} XAF` : '-'}</TableCell>
              <TableCell>{a.start_date ? new Date(a.start_date).toLocaleDateString() : '-'}</TableCell>
              <TableCell>{a.end_date ? new Date(a.end_date).toLocaleDateString() : '-'}</TableCell>
              <TableCell>{a.duration_days || 7} days</TableCell>
              <TableCell>
                <Chip label={a.status} color={a.status === 'approved' ? 'success' : a.status === 'rejected' ? 'error' : 'warning'} size="small" />
              </TableCell>
              <TableCell>
                {a.status === 'pending' && (
                  <>
                    <Button size="small" onClick={() => handleApprove(a.id)}>Approve</Button>
                    <Button size="small" color="error" onClick={() => handleReject(a.id)}>Reject</Button>
                  </>
                )}
                <Button size="small" onClick={() => handleOpen(a)}>Edit</Button>
                <Button size="small" color="error" onClick={() => handleDelete(a.id)}>Delete</Button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
      <Dialog open={open} onClose={handleClose}>
        <DialogTitle>{editingAd ? 'Edit Ad' : 'Create Ad'}</DialogTitle>
        <DialogContent>
          <TextField fullWidth margin="dense" label="Title" value={formData.title} onChange={(e) => setFormData({...formData, title: e.target.value})} />
          <TextField fullWidth margin="dense" label="Description" value={formData.description} onChange={(e) => setFormData({...formData, description: e.target.value})} />
          <TextField fullWidth margin="dense" label="Image URL" value={formData.image_url} onChange={(e) => setFormData({...formData, image_url: e.target.value})} />
          <TextField fullWidth margin="dense" select label="Target Type" value={formData.target_type} onChange={(e) => setFormData({...formData, target_type: e.target.value})}>
            <MenuItem value="restaurant">Restaurant</MenuItem>
            <MenuItem value="rider">Rider</MenuItem>
          </TextField>
          <TextField fullWidth margin="dense" type="number" label="Budget (XAF)" value={formData.budget} onChange={(e) => setFormData({...formData, budget: e.target.value})} />
          <TextField fullWidth margin="dense" type="date" label="Start Date" value={formData.start_date || ''} onChange={(e) => setFormData({...formData, start_date: e.target.value})} InputLabelProps={{ shrink: true }} />
          <TextField fullWidth margin="dense" type="date" label="End Date" value={formData.end_date || ''} onChange={(e) => setFormData({...formData, end_date: e.target.value})} InputLabelProps={{ shrink: true }} />
          <TextField fullWidth margin="dense" select label="Restaurant Owner" value={formData.owner_id || ''} onChange={(e) => setFormData({...formData, owner_id: e.target.value})} disabled={formData.target_type !== 'restaurant'}>
            <MenuItem value="">None</MenuItem>
            {restaurantOwners.map((u) => (
              <MenuItem key={u.id} value={u.id}>{u.full_name || u.email}</MenuItem>
            ))}
          </TextField>
          <TextField fullWidth margin="dense" select label="Delivery Agent" value={formData.agent_id || ''} onChange={(e) => setFormData({...formData, agent_id: e.target.value})} disabled={formData.target_type !== 'rider'}>
            <MenuItem value="">None</MenuItem>
            {deliveryAgents.map((a) => (
              <MenuItem key={a.id} value={a.id}>{a.agency_name || `Agent ${a.id}`}</MenuItem>
            ))}
          </TextField>
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

export default Ads;