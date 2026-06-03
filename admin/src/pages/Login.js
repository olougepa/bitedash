import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Box, Button, TextField, Typography, Paper, Alert } from '@mui/material';
import { login } from '../api';

function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleSubmit = async (event) => {
    event.preventDefault();
    try {
      const response = await login(email, password);
      if (response.access_token) {
        navigate('/dashboard');
      } else {
        setError('Login failed');
      }
    } catch (err) {
      setError('Login failed');
    }
  };
  return (
    <Box display="flex" justifyContent="center" alignItems="center" minHeight="80vh">
      <Paper sx={{ p: 4, width: 360 }}>
        <Typography variant="h5" gutterBottom>
          Admin Login
        </Typography>
        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
        <form onSubmit={handleSubmit}>
          <TextField value={email} onChange={(e) => setEmail(e.target.value)} fullWidth label="Email" margin="normal" />
          <TextField value={password} onChange={(e) => setPassword(e.target.value)} fullWidth label="Password" type="password" margin="normal" />
          <Button type="submit" variant="contained" color="primary" fullWidth sx={{ mt: 2 }}>
            Sign In
          </Button>
        </form>
      </Paper>
    </Box>
  );
}

export default Login;
