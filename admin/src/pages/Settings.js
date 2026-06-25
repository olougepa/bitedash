import React, { useEffect, useState, useCallback } from 'react';
import { Box, Typography, TextField, Button, Snackbar, Alert } from '@mui/material';
import { fetchSystemSettings, updateSystemSetting } from '../api';

function Settings() {
  const [settings, setSettings] = useState({ default_price_per_km: '1.50', delivery_fee_fixed: '0', fixed_delivery_fee: '' });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [snack, setSnack] = useState({ open: false, message: '', severity: 'success' });

  const showSnack = (message, severity = 'success') => setSnack({ open: true, message, severity });

  const loadSettings = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetchSystemSettings();
      const map = {};
      (res.data || []).forEach(item => {
        map[item.setting_key] = item.setting_value;
      });
      setSettings(prev => ({ ...prev, ...map }));
    } catch (e) {
      showSnack('Failed to load settings', 'error');
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    loadSettings();
  }, [loadSettings]);

  const handleSave = async () => {
    setSaving(true);
    try {
      for (const [key, value] of Object.entries(settings)) {
        await updateSystemSetting(key, value);
      }
      showSnack('Settings saved');
    } catch (e) {
      showSnack('Failed to save settings', 'error');
    }
    setSaving(false);
  };

  if (loading) return <Typography>Loading...</Typography>;

  return (
    <Box p={3}>
      <Typography variant="h4" mb={3}>System Settings</Typography>
      <Box maxWidth={400}>
        <TextField
          fullWidth
          margin="dense"
          label="Default Price Per KM (USD)"
          value={settings.default_price_per_km || ''}
          onChange={(e) => setSettings({ ...settings, default_price_per_km: e.target.value })}
          helperText="Base delivery fee multiplier for all riders"
        />
        <TextField
          select
          fullWidth
          margin="dense"
          label="Delivery Fee Type"
          value={settings.delivery_fee_fixed || '0'}
          onChange={(e) => setSettings({ ...settings, delivery_fee_fixed: e.target.value })}
          SelectProps={{ native: true }}
        >
          <option value="0">Variable (based on distance)</option>
          <option value="1">Fixed (flat rate)</option>
        </TextField>
        <TextField
          fullWidth
          margin="dense"
          label="Fixed Delivery Fee (USD)"
          value={settings.fixed_delivery_fee || ''}
          onChange={(e) => setSettings({ ...settings, fixed_delivery_fee: e.target.value })}
          disabled={settings.delivery_fee_fixed !== '1'}
          helperText="Used when Fixed fee type is selected"
        />
        <Button variant="contained" onClick={handleSave} disabled={saving} sx={{ mt: 2 }}>
          Save Settings
        </Button>
        <Snackbar open={snack.open} autoHideDuration={6000} onClose={() => setSnack({ ...snack, open: false })}>
          <Alert severity={snack.severity} onClose={() => setSnack({ ...snack, open: false })}>
            {snack.message}
          </Alert>
        </Snackbar>
      </Box>
    </Box>
  );
}

export default Settings;