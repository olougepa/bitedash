import React, { useEffect, useState, useCallback } from 'react';
import { Box, Typography, Table, TableHead, TableRow, TableCell, TableBody, Button, Dialog, DialogTitle, DialogContent, TextField, DialogActions, Chip, MenuItem, Snackbar, Alert } from '@mui/material';
import { fetchAds, createAd, updateAd, deleteAd, approveAd, rejectAd } from '../api';

function Ads() {
  const [ads, setAds] = useState([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [editingAd, setEditingAd] = useState(null);
  const [formData, setFormData] = useState({ title: '', description: '', image_url: '', target_type: 'restaurant', status: 'pending' });
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

  useEffect(() => {
    loadAds();
  }, [loadAds]);

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
    setFormData(ad || { title: '', description: '', image_url: '', target_type: 'restaurant', status: 'pending' });
    setOpen(true);
  };

  const handleClose = () => {
    setOpen(false);
    setEditingAd(null);
  };

  const handleSave = async () => {
    try {
      if (editingAd) {
        await updateAd(editingAd.id, formData);
        showSnack('Ad updated');
      } else {
        await createAd(formData);
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
            <TableCell>Status</TableCell>
            <TableCell>Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {ads.map((a) => (
            <TableRow key={a.id}>
              <TableCell>{a.title}</TableCell>
              <TableCell>{a.target_type}</TableCell>
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