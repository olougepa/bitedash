import React, { useEffect, useState } from 'react';
import { Drawer, List, ListItemButton, ListItemIcon, ListItemText, Toolbar, Badge } from '@mui/material';
import DashboardIcon from '@mui/icons-material/Dashboard';
import RestaurantIcon from '@mui/icons-material/Restaurant';
import ShoppingCartIcon from '@mui/icons-material/ShoppingCart';
import LocalShippingIcon from '@mui/icons-material/LocalShipping';
import NotificationsIcon from '@mui/icons-material/Notifications';
import { Link } from 'react-router-dom';
import { fetchNotifications } from '../api';

const menuItems = [
  { label: 'Dashboard', icon: <DashboardIcon />, path: '/dashboard' },
  { label: 'Restaurants', icon: <RestaurantIcon />, path: '/restaurants' },
  { label: 'Orders', icon: <ShoppingCartIcon />, path: '/orders' },
  { label: 'Delivery Agents', icon: <LocalShippingIcon />, path: '/delivery-agents' },
  { label: 'POS Terminal', icon: <ShoppingCartIcon />, path: '/pos' },
  { label: 'Notifications', icon: <NotificationsIcon />, path: '/notifications' },
];

function Sidebar() {
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    fetchNotifications().then((res) => {
      const count = (res.data || []).filter((note) => note.is_read === 0 || note.is_read === false).length;
      setUnreadCount(count);
    }).catch(() => {
      setUnreadCount(0);
    });
  }, []);

  return (
    <Drawer variant="permanent" anchor="left">
      <Toolbar />
      <List>
        {menuItems.map((item) => {
          const showBadge = item.path === '/notifications' && unreadCount > 0;
          return (
            <ListItemButton key={item.label} component={Link} to={item.path}>
              <ListItemIcon>
                {showBadge ? (
                  <Badge badgeContent={unreadCount} color="error">
                    {item.icon}
                  </Badge>
                ) : (
                  item.icon
                )}
              </ListItemIcon>
              <ListItemText primary={item.label} />
            </ListItemButton>
          );
        })}
      </List>
    </Drawer>
  );
}

export default Sidebar;
