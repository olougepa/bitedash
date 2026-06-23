import React, { useEffect, useState } from 'react';
import {
  Typography,
  Paper,
  Grid,
  Button,
  List,
  ListItem,
  ListItemText,
  IconButton,
  Chip,
  Box,
  CircularProgress,
} from '@mui/material';
import CheckIcon from '@mui/icons-material/Check';
import CloseIcon from '@mui/icons-material/Close';
import api from '../api';

function Kyc() {
  const [records, setRecords] = useState([]);
  const [loading, setLoading] = useState(true);

  const loadRecords = async () => {
    setLoading(true);
    try {
      const response = await api.get('/kyc');
      setRecords(response.data || []);
    } catch (e) {
      console.error('Failed to load KYC records:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadRecords();
  }, []);

  const handleApprove = async (id) => {
    await api.put(`/kyc/${id}`, { status: 'approved' });
    loadRecords();
  };

  const handleReject = async (id) => {
    await api.put(`/kyc/${id}`, { status: 'rejected' });
    loadRecords();
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'approved': return 'success';
      case 'rejected': return 'error';
      default: return 'warning';
    }
  };

  return (
    <div>
      <Typography variant="h4" gutterBottom fontWeight="bold">
        KYC Verification
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
                {records.map((record) => (
                  <ListItem key={record.id} divider secondaryAction={
                    record.status === 'pending' ? (
                      <>
                        <IconButton edge="end" aria-label="approve" onClick={() => handleApprove(record.id)} color="success">
                          <CheckIcon />
                        </IconButton>
                        <IconButton edge="end" aria-label="reject" onClick={() => handleReject(record.id)} color="error">
                          <CloseIcon />
                        </IconButton>
                      </>
                    ) : null
                  }>
                    <ListItemText
                      primary={
                        <Box display="flex" alignItems="center" gap={1}>
                          {record.entity_type} - {record.document_type}
                          <Chip label={record.status} color={getStatusColor(record.status)} size="small" />
                        </Box>
                      }
                      secondary={`User #${record.user_id} · ${record.document_number || 'No document number'}`}
                    />
                  </ListItem>
                ))}
              </List>
            )}
          </Paper>
        </Grid>
      </Grid>
    </div>
  );
}

export default Kyc;