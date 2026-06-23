import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../services/cart_provider.dart';
import '../models/notification.dart';
import 'restaurant_screen.dart';
import 'coupons_screen.dart';
import 'riders_screen.dart';
import 'notifications_screen.dart';

enum SearchMode { restaurants, meals }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SearchMode _searchMode = SearchMode.restaurants;
  late Future<List<dynamic>> restaurantsFuture;
  late Future<List<dynamic>> menuItemsFuture;
  late Future<List<NotificationItem>> notificationsFuture;
  String _searchQuery = '';
  String _selectedRestaurant = '';
  String _restaurantSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    restaurantsFuture = Provider.of<ApiService>(context, listen: false).fetchRestaurants();
    menuItemsFuture = Provider.of<ApiService>(context, listen: false).fetchAllMenuItems();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    notificationsFuture = Provider.of<ApiService>(context, listen: false)
        .fetchNotifications(category: auth.user?.role)
        .then((list) => list.map((item) => NotificationItem.fromJson(item as Map<String, dynamic>)).toList());
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('BiteDash'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
actions: auth.isAuthenticated
            ? [
                IconButton(icon: const Icon(Icons.local_offer), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CouponsScreen()))),
                IconButton(icon: const Icon(Icons.people), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RidersScreen()))),
                FutureBuilder<List<NotificationItem>>(
                  future: notificationsFuture,
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.hasData ? snapshot.data!.where((note) => !note.isRead).length : 0;
                    return Stack(
                      children: [
                        IconButton(icon: const Icon(Icons.notifications), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                        if (unreadCount > 0) Positioned(right: 8, top: 8, child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                          child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        )),
                      ],
                    );
                  },
                ),
              ]
            : [
                TextButton.icon(onPressed: () => Navigator.pushNamed(context, '/login'), icon: const Icon(Icons.login, color: Colors.white), label: const Text('Login', style: TextStyle(color: Colors.white))),
                TextButton.icon(onPressed: () => Navigator.pushNamed(context, '/register'), icon: const Icon(Icons.person_add, color: Colors.white), label: const Text('Sign Up', style: TextStyle(color: Colors.white))),
              ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeroSection(auth),
              if (auth.user?.role == 'restaurant_owner') _buildOwnerSection(auth),
              if (auth.user?.role == 'delivery_agent') _buildDeliverySection(auth),
              _buildSearchToggle(),
              _buildFilters(),
              Expanded(
                child: _searchMode == SearchMode.restaurants ? _buildRestaurantView() : _buildMealsView(),
              ),
              const AdsBanner(),
            ],
          ),
          if (cart.items.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 140,
              child: FloatingActionButton.extended(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                onPressed: () => Navigator.pushNamed(context, '/checkout'),
                icon: const Icon(Icons.shopping_cart),
                label: Text('${cart.items.length} items • \$${cart.total.toStringAsFixed(2)}'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepOrange, Color(0xFFFFAB40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            auth.isAuthenticated ? 'Welcome back!' : 'BiteDash',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          if (!auth.isAuthenticated) ...[
            const SizedBox(height: 8),
            const Text('Delicious food delivered fast to your doorstep', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Order as Guest - No account needed!', style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ],
      ),
    );
  }

  Widget _buildOwnerSection(AuthProvider auth) {
    if (!auth.isApproved) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.orange.shade50,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(children: [
              Icon(Icons.hourglass_empty, size: 48, color: Colors.orange),
              SizedBox(height: 16),
              Text('Account Under Review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Your restaurant owner account is awaiting admin approval. You will receive a notification once approved.'),
            ]),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Restaurant Owner', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(children: [
                _buildDashboardCard(icon: Icons.restaurant, title: 'POS Dashboard', subtitle: 'Manage orders', onTap: () => Navigator.pushNamed(context, '/owner-pos')),
                const SizedBox(width: 12),
                _buildDashboardCard(icon: Icons.local_offer, title: 'Coupons', subtitle: 'Create deals', onTap: () => Navigator.pushNamed(context, '/owner-pos')),
                const SizedBox(width: 12),
                _buildDashboardCard(icon: Icons.campaign, title: 'Promotions', subtitle: 'Request ads', onTap: () => Navigator.pushNamed(context, '/promotions')),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliverySection(AuthProvider auth) {
    if (!auth.isApproved) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.orange.shade50,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(children: [
              Icon(Icons.hourglass_empty, size: 48, color: Colors.orange),
              SizedBox(height: 16),
              Text('Account Under Review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Your delivery agent account is awaiting admin approval. You will receive a notification once approved.'),
            ]),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delivery Agent', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(children: [
                _buildDashboardCard(icon: Icons.delivery_dining, title: 'Deliveries', subtitle: 'My active orders', onTap: () => Navigator.pushNamed(context, '/delivery-agent')),
                const SizedBox(width: 12),
                _buildDashboardCard(icon: Icons.map, title: 'Map View', subtitle: 'Track location', onTap: () => Navigator.pushNamed(context, '/delivery-agent')),
                const SizedBox(width: 12),
                _buildDashboardCard(icon: Icons.campaign, title: 'Promotions', subtitle: 'Request ads', onTap: () => Navigator.pushNamed(context, '/promotions')),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchToggle() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<SearchMode>(
              segments: const [
                ButtonSegment(value: SearchMode.restaurants, label: Text('Restaurants'), icon: Icon(Icons.restaurant)),
                ButtonSegment(value: SearchMode.meals, label: Text('Meals'), icon: Icon(Icons.restaurant_menu)),
              ],
              selected: {_searchMode},
              onSelectionChanged: (modes) => setState(() => _searchMode = modes.first),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_searchMode == SearchMode.restaurants)
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search restaurants...', border: OutlineInputBorder()),
              onChanged: (v) => setState(() => _restaurantSearchQuery = v),
            )
          else ...[
            Row(
              children: [
                Expanded(child: TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search meals...', border: OutlineInputBorder(), isDense: true),
                  onChanged: (v) => setState(() => _searchQuery = v),
                )),
                const SizedBox(width: 8),
                FutureBuilder<List<dynamic>>(
                  future: restaurantsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final restaurants = snapshot.data!;
                    return SizedBox(
                      width: 150,
                      child: DropdownMenu<String>(
                        label: const Text('Restaurant'),
                        dropdownMenuEntries: [
                          const DropdownMenuEntry(value: '', label: 'All'),
                          ...restaurants.map((r) => DropdownMenuEntry(value: '${r['id']}', label: r['name'] ?? 'Unknown')).toList(),
                        ],
                        onSelected: (v) => setState(() => _selectedRestaurant = v ?? ''),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRestaurantView() {
    return FutureBuilder<List<dynamic>>(
      future: restaurantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        var restaurants = snapshot.data ?? [];
        restaurants = restaurants.where((r) => r['status'] == 'active' || r['status'] == 'approved').toList();
        if (_restaurantSearchQuery.isNotEmpty) {
          restaurants = restaurants.where((r) => (r['name'] as String? ?? '').toLowerCase().contains(_restaurantSearchQuery.toLowerCase())).toList();
        }
        if (restaurants.isEmpty) return const Center(child: Text('No restaurants available'));
        return ListView.builder(
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            final restaurant = restaurants[index] as Map<String, dynamic>;
            final rating = double.tryParse('${restaurant['rating'] ?? 0}') ?? 0.0;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepOrange,
                  child: Stack(
                    children: [
                      const Icon(Icons.restaurant, color: Colors.white),
                      if (restaurant['status'] == 'active' || restaurant['status'] == 'approved')
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: Icon(Icons.verified, color: Colors.green, size: 12),
                        ),
                    ],
                  ),
                ),
                title: Row(
                  children: [
                    Text(restaurant['name'] ?? 'Restaurant'),
                    const SizedBox(width: 4),
                    if (restaurant['status'] == 'active' || restaurant['status'] == 'approved')
                      const Icon(Icons.verified, color: Colors.green, size: 16),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurant['description'] ?? ''),
                    Row(children: [
                      Icon(Icons.star, color: Colors.orange, size: 14),
                      Text(' ${rating.toStringAsFixed(1)}', style: TextStyle(fontSize: 12, color: Colors.orange)),
                    ]),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => RestaurantScreen(
                      restaurantId: int.tryParse(restaurant['id']?.toString() ?? '0') ?? 0,
                      restaurantName: restaurant['name'] as String? ?? 'Restaurant',
                    ),
                  ));
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMealsView() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([menuItemsFuture, restaurantsFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final data = snapshot.data as List<dynamic>?;
        var items = data?[0] as List<dynamic>? ?? [];
        final restaurants = data?[1] as List<dynamic>? ?? [];
        final restaurantMap = {for (var r in restaurants) '${r['id']}': r['name'] ?? 'Unknown'};
        if (_searchQuery.isNotEmpty) {
          items = items.where((item) => (item['name'] as String? ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
        }
        if (_selectedRestaurant.isNotEmpty) {
          items = items.where((item) => item['restaurant_id'].toString() == _selectedRestaurant).toList();
        }
        if (items.isEmpty) return const Center(child: Text('No meals found'));
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index] as Map<String, dynamic>;
            final price = double.tryParse('${item['price']}') ?? 0.0;
            final mealRating = double.tryParse('${item['rating'] ?? 0}') ?? 0.0;
            final restaurantName = restaurantMap['${item['restaurant_id']}'] ?? 'Unknown';
final isAvailable = item['is_available'] == 1 || item['is_available'] == true;
            final quantity = item['quantity'];
            final hasExplicitQuantity = quantity != null;
            final isSoldOut = hasExplicitQuantity && (quantity == 0);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.restaurant_menu, color: Colors.deepOrange)),
                title: Text(item['name'] ?? 'Meal'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('\$${price.toStringAsFixed(2)}'),
                    Row(children: [
                      Icon(Icons.star, color: Colors.orange, size: 14),
                      Text(' ${mealRating.toStringAsFixed(1)}', style: TextStyle(fontSize: 12, color: Colors.orange)),
                    ]),
                    Text('from $restaurantName', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    if (!isAvailable || isSoldOut)
                      Text('Sold out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
                trailing: isAvailable && !isSoldOut
                    ? IconButton(
                        icon: const Icon(Icons.add_shopping_cart, color: Colors.deepOrange),
                        onPressed: () {
                          final cart = Provider.of<CartProvider>(context, listen: false);
                          cart.addItem(
                            int.tryParse(item['id']?.toString() ?? '0') ?? 0,
                            item['name'] ?? 'Meal',
                            price,
                            restaurantId: int.tryParse(item['restaurant_id']?.toString() ?? '0') ?? 1,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                        },
                      )
                    : const SizedBox.shrink(),
                enabled: isAvailable && !isSoldOut,
                onTap: isAvailable && !isSoldOut
                    ? () {
                        final cart = Provider.of<CartProvider>(context, listen: false);
                        cart.addItem(
                          int.tryParse(item['id']?.toString() ?? '0') ?? 0,
                          item['name'] ?? 'Meal',
                          price,
                          restaurantId: int.tryParse(item['restaurant_id']?.toString() ?? '0') ?? 1,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                      }
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDashboardCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.deepOrange.shade50, borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Icon(icon, size: 32, color: Colors.deepOrange),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
      ),
    );
  }
}

class AdsBanner extends StatefulWidget {
  const AdsBanner({super.key});

  @override
  State<AdsBanner> createState() => _AdsBannerState();
}

class _AdsBannerState extends State<AdsBanner> {
  late Future<List<dynamic>> _adsFuture;

  @override
  void initState() {
    super.initState();
    _adsFuture = Provider.of<ApiService>(context, listen: false).fetchAds();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _adsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final ads = snapshot.data!;
        return Container(
          height: 80,
          margin: const EdgeInsets.all(16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ads.length,
            itemBuilder: (context, i) {
              final ad = ads[i] as Map<String, dynamic>;
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.deepOrange, Color(0xFFFFAB40)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ad['title'] ?? 'Special Offer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(ad['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ),
              );
            },
          ),
        );
      },
    );
  }
}