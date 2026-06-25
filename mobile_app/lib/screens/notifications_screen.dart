import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../services/l10n.dart';
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
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _refreshNotifications();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _refreshNotifications();
    });
  }

  Future<void> _refreshNotifications() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final list = await api.fetchNotifications(category: auth.user?.role);
      if (mounted) {
        setState(() {
          notifications = list.map<NotificationItem>((item) => NotificationItem.fromJson(item as Map<String, dynamic>)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.t('unable_to_mark_read'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(L10n.t('notifications'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('${L10n.t('error')}: $_error'))
              : notifications.isEmpty
                  ? Center(child: Text(L10n.t('no_notifications_yet')))
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
                                ? Chip(label: Text(L10n.t('read')))
                                : TextButton(
                                    onPressed: () => _markRead(notification),
                                    child: Text(L10n.t('mark_read')),
                                  ),
                          );
                        },
                      ),
                    ),
    );
  }
}