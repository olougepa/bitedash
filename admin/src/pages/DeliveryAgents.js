import React, { useEffect, useState } from 'react';
import {
  Typography,
  Paper,
  List,
  ListItem,
  ListItemText,
  IconButton,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  MenuItem,
} from '@mui/material';
import DeleteIcon from '@mui/icons-material/Delete';
import EditIcon from '@mui/icons-material/Edit';
import AttachMoneyIcon from '@mui/icons-material/AttachMoney';
import {
  fetchDeliveryAgents,
  createDeliveryAgent,
  updateDeliveryAgent,
  updateDeliveryAgentPrice,
  deleteDeliveryAgent,
} from '../api';

function DeliveryAgents() {
  const [agents, setAgents] = useState([]);
  const [open, setOpen] = useState(false);
  const [priceDialog, setPriceDialog] = useState(false);
  const [selectedAgent, setSelectedAgent] = useState(null);
  const [form, setForm] = useState({ id: null, name: '', vehicle_type: '', rating: 0, price_per_km: 1.50, is_fixed_price: 0, fixed_price: '' });
  const [priceForm, setPriceForm] = useState({ price_per_km: 1.50, is_fixed_price: '0', fixed_price: '' });

  const loadAgents = async () => {
    const response = await fetchDeliveryAgents();
    setAgents(response.data || []);
  };

  useEffect(() => {
    loadAgents();
  }, []);

  const openForm = (agent) => {
    if (agent) {
      setForm({
        id: agent.id,
        name: agent.name || '',
        vehicle_type: agent.vehicle_type || '',
        rating: agent.rating || 0,
        price_per_km: agent.price_per_km || 1.50,
        is_fixed_price: agent.is_fixed_price ? 1 : 0,
        fixed_price: agent.fixed_price || '',
      });
    } else {
      setForm({ id: null, name: '', vehicle_type: '', rating: 0, price_per_km: 1.50, is_fixed_price: 0, fixed_price: '' });
    }
    setOpen(true);
  };

  const openPriceForm = (agent) => {
    setSelectedAgent(agent);
    setPriceForm({ price_per_km: agent.price_per_km || 1.50, is_fixed_price: agent.is_fixed_price ? '1' : '0', fixed_price: agent.fixed_price || '' });
    setPriceDialog(true);
  };

  const handleSave = async () => {
    const payload = {
      name: form.name,
      vehicle_type: form.vehicle_type,
      rating: form.rating,
      price_per_km: form.price_per_km,
      is_fixed_price: form.is_fixed_price,
      fixed_price: form.is_fixed_price ? form.fixed_price : null,
    };
    if (form.id) {
      await updateDeliveryAgent(form.id, payload);
    } else {
      await createDeliveryAgent(payload);
    }
    setOpen(false);
    loadAgents();
  };

  const handlePriceSave = async () => {
    if (selectedAgent) {
      await updateDeliveryAgentPrice(selectedAgent.id, priceForm.price_per_km, priceForm.is_fixed_price === '1', priceForm.is_fixed_price === '1' ? priceForm.fixed_price : null);
    }
    setPriceDialog(false);
    loadAgents();
  };

  const handleDelete = async (id) => {
    await deleteDeliveryAgent(id);
    loadAgents();
  };

  return (
    <div>
      <Typography variant="h4" gutterBottom>
        Delivery Agents
      </Typography>
      <Button variant="contained" color="primary" sx={{ mb: 2 }} onClick={() => openForm(null)}>
        Add Delivery Agent
      </Button>
      <Paper>
        <List>
          {agents.map((agent) => (
            <ListItem key={agent.id} secondaryAction={
              <>
                <IconButton edge="end" aria-label="price" onClick={() => openPriceForm(agent)}>
                  <AttachMoneyIcon />
                </IconButton>
                <IconButton edge="end" aria-label="edit" onClick={() => openForm(agent)}>
                  <EditIcon />
                </IconButton>
                <IconButton edge="end" aria-label="delete" onClick={() => handleDelete(agent.id)}>
                  <DeleteIcon />
                </IconButton>
              </>
            }>
              <ListItemText
                primary={agent.name}
                secondary={`${agent.vehicle_type || 'Vehicle not set'} · Rating: ${agent.rating || 0} · $${agent.price_per_km || 1.5}/km`}
              />
            </ListItem>
          ))}
        </List>
      </Paper>

      <Dialog open={open} onClose={() => setOpen(false)}>
        <DialogTitle>{form.id ? 'Edit Delivery Agent' : 'New Delivery Agent'}</DialogTitle>
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
            label="Vehicle Type"
            margin="dense"
            value={form.vehicle_type}
            onChange={(e) => setForm({ ...form, vehicle_type: e.target.value })}
          />
          <TextField
            fullWidth
            type="number"
            label="Rating"
            margin="dense"
            value={form.rating}
            onChange={(e) => setForm({ ...form, rating: parseFloat(e.target.value) || 0 })}
          />
          <TextField
            fullWidth
            type="number"
            label="Price per km ($)"
            margin="dense"
            value={form.price_per_km}
            onChange={(e) => setForm({ ...form, price_per_km: parseFloat(e.target.value) || 0 })}
          />
          <TextField
            fullWidth
            select
            label="Fixed Price Mode"
            margin="dense"
            value={form.is_fixed_price}
            onChange={(e) => setForm({ ...form, is_fixed_price: parseInt(e.target.value) })}
          >
            <MenuItem value={0}>Variable (per km)</MenuItem>
            <MenuItem value={1}>Fixed Price</MenuItem>
          </TextField>
          {form.is_fixed_price === 1 && (
            <TextField
              fullWidth
              type="number"
              label="Fixed Price ($)"
              margin="dense"
              value={form.fixed_price}
              onChange={(e) => setForm({ ...form, fixed_price: parseFloat(e.target.value) || '' })}
            />
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleSave}>Save</Button>
        </DialogActions>
      </Dialog>

      <Dialog open={priceDialog} onClose={() => setPriceDialog(false)}>
        <DialogTitle>Update Delivery Fee</DialogTitle>
        <DialogContent>
          <TextField
            fullWidth
            select
            label="Fee Type"
            margin="dense"
            value={priceForm.is_fixed_price}
            onChange={(e) => setPriceForm({ ...priceForm, is_fixed_price: e.target.value })}
          >
            <MenuItem value="0">Per km</MenuItem>
            <MenuItem value="1">Fixed Price</MenuItem>
          </TextField>
          {priceForm.is_fixed_price === '1' ? (
            <TextField
              fullWidth
              type="number"
              label="Fixed Price ($)"
              margin="dense"
              value={priceForm.fixed_price}
              onChange={(e) => setPriceForm({ ...priceForm, fixed_price: parseFloat(e.target.value) || '' })}
            />
          ) : (
            <TextField
              fullWidth
              type="number"
              label="Price per km ($)"
              margin="dense"
              value={priceForm.price_per_km}
              onChange={(e) => setPriceForm({ ...priceForm, price_per_km: parseFloat(e.target.value) || 0 })}
            />
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setPriceDialog(false)}>Cancel</Button>
          <Button variant="contained" onClick={handlePriceSave}>Save</Button>
        </DialogActions>
      </Dialog>
    </div>
  );
}

export default DeliveryAgents;