import React, { useEffect, useState, useCallback } from 'react';
import { Box, Typography, Table, TableHead, TableRow, TableCell, TableBody, Button, Dialog, DialogTitle, DialogContent, TextField, DialogActions, Chip, Snackbar, Alert } from '@mui/material';
import { fetchPriceRequests, approvePriceRequest, rejectPriceRequest } from '../api';

function PriceRequests() {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [snack, setSnack] = useState({ open: false, message: '', severity: 'success' });

  const showSnack = (message, severity = 'success') => setSnack({ open: true, message, severity });

  const loadRequests = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetchPriceRequests();
      setRequests(res.data || []);
    } catch (e) {
      showSnack('Failed to load price requests', 'error');
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    loadRequests();
  }, [loadRequests]);

  const handleApprove = async (id) => {
    try {
      await approvePriceRequest(id);
      showSnack('Price request approved');
      loadRequests();
    } catch (e) {
      showSnack('Failed to approve price request', 'error');
    }
  };

  const handleReject = async (id) => {
    const remark = prompt('Enter rejection remark:');
    if (remark !== null) {
      try {
        await rejectPriceRequest(id, remark);
        showSnack('Price request rejected');
        loadRequests();
      } catch (e) {
        showSnack('Failed to reject price request', 'error');
      }
    }
  };

  if (loading) return <Typography>Loading...</Typography>;

  return (
    <Box p={3}>
      <Typography variant="h4" mb={3}>Price Change Requests</Typography>
      <Table>
        <TableHead>
          <TableRow>
            <TableCell>Agent ID</TableCell>
            <TableCell>Proposed Price</TableCell>
            <TableCell>Status</TableCell>
            <TableCell>Remark</TableCell>
            <TableCell>Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {requests.map((r) => (
            <TableRow key={r.id}>
              <TableCell>{r.delivery_agent_id}</TableCell>
              <TableCell>\${r.proposed_price}</TableCell>
              <TableCell>
                <Chip label={r.status} color={r.status === 'approved' ? 'success' : r.status === 'rejected' ? 'error' : 'warning'} size="small" />
              </TableCell>
              <TableCell>{r.admin_remark}</TableCell>
              <TableCell>
                {r.status === 'pending' && (
                  <>
                    <Button size="small" onClick={() => handleApprove(r.id)}>Approve</Button>
                    <Button size="small" color="error" onClick={() => handleReject(r.id)}>Reject</Button>
                  </>
                )}
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
      <Snackbar open={snack.open} autoHideDuration={6000} onClose={() => setSnack({ ...snack, open: false })}>
        <Alert severity={snack.severity} onClose={() => setSnack({ ...snack, open: false })}>
          {snack.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}

export default PriceRequests;