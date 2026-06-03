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
} from '@mui/material';
import DeleteIcon from '@mui/icons-material/Delete';
import EditIcon from '@mui/icons-material/Edit';
import {
  fetchDeliveryAgents,
  createDeliveryAgent,
  updateDeliveryAgent,
  deleteDeliveryAgent,
} from '../api';

function DeliveryAgents() {
  const [agents, setAgents] = useState([]);
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState({ id: null, name: '', vehicle_type: '', rating: 0 });

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
      });
    } else {
      setForm({ id: null, name: '', vehicle_type: '', rating: 0 });
    }
    setOpen(true);
  };

  const handleSave = async () => {
    const payload = {
      name: form.name,
      vehicle_type: form.vehicle_type,
      rating: form.rating,
    };
    if (form.id) {
      await updateDeliveryAgent(form.id, payload);
    } else {
      await createDeliveryAgent(payload);
    }
    setOpen(false);
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
                secondary={`${agent.vehicle_type || 'Vehicle not set'} · Rating: ${agent.rating || 0}`}
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
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleSave}>Save</Button>
        </DialogActions>
      </Dialog>
    </div>
  );
}

export default DeliveryAgents;
