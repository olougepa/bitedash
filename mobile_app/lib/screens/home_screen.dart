import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../services/cart_provider.dart';
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
  late Future<List<dynamic>> citiesFuture;
  int? _selectedCityId;

  @override
  void initState() {
    super.initState();
    _loadData();
    citiesFuture = Provider.of<ApiService>(context, listen: false).fetchCities();
  }

  void _loadData() {
    restaurantsFuture = Provider.of<ApiService>(context, listen: false).fetchRestaurants(cityId: _selectedCityId);
    menuItemsFuture = Provider.of<ApiService>(context, listen: false).fetchAllMenuItems(cityId: _selectedCityId);
  }

  void _showCityFilter() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => FutureBuilder<List<dynamic>>(
        future: citiesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final cities = snapshot.data!;
          return SafeArea(
            child: ListView(
              children: [
                const ListTile(title: Text('Select City', style: TextStyle(fontWeight: FontWeight.bold))),
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text('All Cities'),
                  selected: _selectedCityId == null,
                  onTap: () {
                    setState(() => _selectedCityId = null);
                    _loadData();
                    Navigator.pop(context);
                  },
                ),
                ...cities.map((c) => ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text('${c['name']}, ${c['country']}'),
                  selected: _selectedCityId == int.tryParse('${c['id']}'),
                  onTap: () {
                    setState(() => _selectedCityId = int.tryParse('${c['id']}'));
                    _loadData();
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
          );
        },
      ),
    );
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
        actions: [
          IconButton(icon: const Icon(Icons.local_offer), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CouponsScreen()))),
          IconButton(icon: const Icon(Icons.people), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RidersScreen()))),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
          if (auth.isAuthenticated) ...[
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'profile') Navigator.pushNamed(context, '/profile');
                if (value == 'logout') {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'profile', child: Text('Profile')),
                const PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
              icon: const Icon(Icons.account_circle, color: Colors.white),
            ),
          ] else ...[
            TextButton.icon(onPressed: () => Navigator.pushNamed(context, '/login'), icon: const Icon(Icons.login, color: Colors.white), label: const Text('Login', style: TextStyle(color: Colors.white))),
            TextButton.icon(onPressed: () => Navigator.pushNamed(context, '/register'), icon: const Icon(Icons.person_add, color: Colors.white), label: const Text('Sign Up', style: TextStyle(color: Colors.white))),
          ],
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeroSection(auth),
              if (auth.user?.role == 'restaurant_owner') _buildOwnerSection(auth),
              if (auth.user?.role == 'delivery_agent') _buildDeliverySection(auth),
              _buildCompactFilters(),
              Expanded(
                child: _searchMode == SearchMode.restaurants ? _buildRestaurantView() : _buildMealsView(),
              ),
              AdsBanner(key: ValueKey(_selectedCityId)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (!auth.isAuthenticated) ...[
            const SizedBox(height: 2),
            const Text('Delicious food delivered fast', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildOwnerSection(AuthProvider auth) {
    if (!auth.isApproved) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              const Icon(Icons.hourglass_empty, size: 36, color: Colors.orange),
              const SizedBox(height: 8),
              const Text('Account Under Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text('Your account is awaiting admin approval.', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Upload KYC'),
                onPressed: () => Navigator.pushNamed(context, '/kyc'),
              ),
            ]),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Restaurant Owner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                _buildDashboardIcon(icon: Icons.restaurant, label: 'POS', onTap: () => Navigator.pushNamed(context, '/owner-pos')),
                const SizedBox(width: 12),
                _buildDashboardIcon(icon: Icons.local_offer, label: 'Coupons', onTap: () => Navigator.pushNamed(context, '/owner-pos')),
                const SizedBox(width: 12),
                _buildDashboardIcon(icon: Icons.campaign, label: 'Ads', onTap: () => Navigator.pushNamed(context, '/promotions')),
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
        padding: const EdgeInsets.all(8),
        child: Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              const Icon(Icons.hourglass_empty, size: 36, color: Colors.orange),
              const SizedBox(height: 8),
              const Text('Account Under Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              const Text('Your account is awaiting admin approval.', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Upload KYC'),
                onPressed: () => Navigator.pushNamed(context, '/kyc'),
              ),
            ]),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delivery Agent', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                _buildDashboardIcon(icon: Icons.delivery_dining, label: 'Deliveries', onTap: () => Navigator.pushNamed(context, '/delivery-agent')),
                const SizedBox(width: 12),
                _buildDashboardIcon(icon: Icons.map, label: 'Map', onTap: () => Navigator.pushNamed(context, '/delivery-agent')),
                const SizedBox(width: 12),
                _buildDashboardIcon(icon: Icons.campaign, label: 'Ads', onTap: () => Navigator.pushNamed(context, '/promotions')),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardIcon({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.deepOrange.shade50, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.deepOrange, size: 20),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildCompactFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.location_city, color: Colors.deepOrange, size: 20),
            tooltip: 'Filter by city',
            padding: EdgeInsets.zero,
            onPressed: _showCityFilter,
          ),
          if (_selectedCityId != null)
            const Icon(Icons.check_circle, color: Colors.green, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: SegmentedButton<SearchMode>(
              segments: const [
                ButtonSegment(value: SearchMode.restaurants, label: Text('Restaurants'), icon: Icon(Icons.restaurant, size: 16)),
                ButtonSegment(value: SearchMode.meals, label: Text('Meals'), icon: Icon(Icons.restaurant_menu, size: 16)),
              ],
              selected: {_searchMode},
              onSelectionChanged: (modes) => setState(() => _searchMode = modes.first),
            ),
          ),
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
        if (restaurants.isEmpty) return const Center(child: Text('No restaurants available'));
        return ListView.builder(
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            final restaurant = restaurants[index] as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepOrange.shade100,
                  child: const Icon(Icons.restaurant, color: Colors.deepOrange, size: 18),
                ),
                title: Text(restaurant['name'] ?? 'Restaurant', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                subtitle: Text(restaurant['description'] ?? '', style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, size: 16),
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
        if (items.isEmpty) return const Center(child: Text('No meals found'));
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index] as Map<String, dynamic>;
            final price = double.tryParse('${item['price']}') ?? 0.0;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: ListTile(
                leading: const Icon(Icons.restaurant_menu, color: Colors.deepOrange, size: 18),
                title: Text(item['name'] ?? 'Meal', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                subtitle: Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.deepOrange, size: 18),
                  onPressed: () {
                    final cart = Provider.of<CartProvider>(context, listen: false);
                    cart.addItem(
                      int.tryParse(item['id']?.toString() ?? '0') ?? 0,
                      item['name'] ?? 'Meal',
                      price,
                      restaurantId: int.tryParse(item['restaurant_id']?.toString() ?? '0') ?? 1,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['name']} added to cart')));
                  },
                ),
              ),
            );
          },
        );
      },
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

  bool _isNotExpired(Map<String, dynamic> ad) {
    final endDateStr = ad['end_date'] as String?;
    if (endDateStr == null) return true;
    final endDate = DateTime.tryParse(endDateStr);
    if (endDate == null) return true;
    return endDate.isAfter(DateTime.now());
  }

  bool _isValidForBanner(Map<String, dynamic> ad) {
    final status = ad['status'] as String? ?? 'pending';
    if (status != 'approved') return false;
    return _isNotExpired(ad);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _adsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final allAds = snapshot.data!;
        final ads = allAds.where((ad) => _isValidForBanner(ad as Map<String, dynamic>)).toList();
        if (ads.isEmpty) return const SizedBox.shrink();
        return Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ads.length,
            itemBuilder: (context, i) {
              final ad = ads[i] as Map<String, dynamic>;
              return GestureDetector(
                onTap: () {
                  final targetType = ad['target_type'] as String?;
                  final targetId = ad['owner_id'] ?? ad['agent_id'];
                  if (targetType == 'restaurant' && targetId != null) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => RestaurantScreen(
                        restaurantId: int.tryParse('$targetId') ?? 0,
                        restaurantName: ad['title'] ?? 'Restaurant',
                      ),
                    ));
                  } else if (targetType == 'rider' && targetId != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delivery Agent ID: $targetId')));
                  }
                },
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.deepOrange, Color(0xFFFFAB40)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(ad['title'] ?? 'Special Offer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(ad['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
