import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../models/notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshNotifications();
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final api = Provider.of<ApiService>(context, listen: false);
      final list = await api.fetchNotifications(category: auth.user?.role);
      setState(() {
        notifications = list.map<NotificationItem>((item) => NotificationItem.fromJson(item as Map<String, dynamic>)).toList();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _markRead(NotificationItem notification) async {
    if (notification.isRead) return;
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.markNotificationRead(notification.id);
      setState(() {
        notification.isRead = true;
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to mark notification as read')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : notifications.isEmpty
                  ? const Center(child: Text('No notifications yet.'))
                  : RefreshIndicator(
                      onRefresh: _refreshNotifications,
                      child: ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return ListTile(
                            title: Text(notification.title),
                            subtitle: Text(notification.message),
                            trailing: notification.isRead
                                ? Chip(label: const Text('Read'))
                                : TextButton(
                                    onPressed: () => _markRead(notification),
                                    child: const Text('Mark read'),
                                  ),
                          );
                        },
                      ),
                    ),
    );
  }
}
