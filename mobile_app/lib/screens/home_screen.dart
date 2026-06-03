import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../models/notification.dart';
import 'restaurant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> restaurantsFuture;
  late Future<List<NotificationItem>> notificationsFuture;

  @override
  void initState() {
    super.initState();
    restaurantsFuture = Provider.of<ApiService>(context, listen: false).fetchRestaurants();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    notificationsFuture = Provider.of<ApiService>(context, listen: false)
        .fetchNotifications(category: auth.user?.role)
        .then((list) => list.map((item) => NotificationItem.fromJson(item as Map<String, dynamic>)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bitedash'),
        actions: [
          FutureBuilder<List<NotificationItem>>(
            future: notificationsFuture,
            builder: (context, snapshot) {
              final unreadCount = snapshot.hasData
                  ? snapshot.data!.where((note) => !note.isRead).length
                  : 0;
              return IconButton(
                icon: unreadCount > 0
                    ? Badge(
                        label: Text(unreadCount.toString()),
                        child: const Icon(Icons.notifications),
                      )
                    : const Icon(Icons.notifications),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder<List<NotificationItem>>(
            future: notificationsFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final notes = snapshot.data!;
                return Container(
                  width: double.infinity,
                  color: Colors.orange.shade50,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Latest Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...notes.take(2).map((note) => Text('• ${note.title}')),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.user?.role == 'restaurant_owner') {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ListTile(
                    title: const Text('Owner POS Dashboard'),
                    subtitle: const Text('Manage in-store sales and incoming online orders'),
                    trailing: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/owner-pos'),
                      child: const Text('Open'),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: restaurantsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final restaurants = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index] as Map<String, dynamic>;
                    return ListTile(
                      title: Text(restaurant['name'] ?? 'Restaurant'),
                      subtitle: Text(restaurant['description'] ?? ''),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RestaurantScreen(
                              restaurantId: restaurant['id'] as int? ?? 0,
                              restaurantName: restaurant['name'] as String? ?? 'Restaurant',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
