import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/cart_provider.dart';

class RestaurantScreen extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;

  const RestaurantScreen({required this.restaurantId, required this.restaurantName, super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  late Future<dynamic> restaurantFuture;
  late Future<List<dynamic>> menuFuture;
  late Future<List<dynamic>> couponsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    restaurantFuture = Provider.of<ApiService>(context, listen: false).fetchRestaurant(widget.restaurantId);
    menuFuture = Provider.of<ApiService>(context, listen: false).fetchMenuForRestaurant(widget.restaurantId);
    couponsFuture = Provider.of<ApiService>(context, listen: false).fetchCoupons(widget.restaurantId);
  }

  String _getAddressName(double lat, double lng) {
    if (lat == 0 && lng == 0) return 'Location not set';
    return 'Located at coordinates (${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)})';
  }

  Widget _buildMiniMap(double lat, double lng) {
    if (lat == 0 && lng == 0) return const SizedBox.shrink();
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.map, color: Colors.white, size: 40),
    );
  }

  Widget _buildMealPhoto(String? photoUrl, String name) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(photoUrl, width: 50, height: 50, fit: BoxFit.cover),
      );
    }
    return CircleAvatar(
      backgroundColor: Colors.deepOrange,
      child: Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: cart.items.isEmpty ? null : () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat available after checkout')));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder<dynamic>(
            future: restaurantFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final restaurant = snapshot.data as Map<String, dynamic>;
              final rating = double.tryParse('${restaurant['rating'] ?? 0}') ?? 0.0;
              final lat = double.tryParse('${restaurant['latitude'] ?? 0}') ?? 0.0;
              final lng = double.tryParse('${restaurant['longitude'] ?? 0}') ?? 0.0;
              final logoUrl = restaurant['logo_url'] as String?;
              final bannerUrl = restaurant['banner_url'] as String?;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bannerUrl != null && bannerUrl.isNotEmpty)
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        image: DecorationImage(image: NetworkImage(bannerUrl), fit: BoxFit.cover),
                      ),
                    ),
                  Card(
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (logoUrl != null && logoUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(logoUrl, width: 60, height: 60, fit: BoxFit.cover),
                                )
                              else
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.deepOrange,
                                  child: const Icon(Icons.restaurant, color: Colors.deepOrange, size: 30),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(restaurant['name'] ?? 'Restaurant', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    Row(children: [
                                      Icon(Icons.star, color: Colors.orange, size: 16),
                                      Text(' ${rating.toStringAsFixed(1)}', style: TextStyle(color: Colors.orange)),
                                    ]),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  restaurant['address_name'] ?? _getAddressName(lat, lng),
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildMiniMap(lat, lng),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(restaurant['description'] ?? ''),
                        ],
                      ),
                    ),
                  ),
                  FutureBuilder<List<dynamic>>(
                    future: couponsFuture,
                    builder: (context, couponSnapshot) {
                      if (!couponSnapshot.hasData || couponSnapshot.data!.isEmpty) return const SizedBox.shrink();
                      final coupons = couponSnapshot.data!;
                      return Container(
                        height: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: coupons.length,
                          itemBuilder: (context, i) {
                            final c = coupons[i] as Map<String, dynamic>;
                            return Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['code'] ?? 'COUPON', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(c['discount_percent'] != null ? '${c['discount_percent']}% off' : '\$${c['discount_amount']} off', style: TextStyle(fontSize: 10, color: Colors.orange)),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: menuFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                var items = snapshot.data ?? [];
                if (_searchQuery.isNotEmpty) {
                  items = items.where((item) => (item['name'] as String? ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index] as Map<String, dynamic>;
                    final id = int.tryParse('${item['id']}') ?? 0;
                    final name = item['name'] as String? ?? 'Dish';
                    final price = double.tryParse('${item['price']}') ?? 0.0;
                    final qty = item['quantity'];
                    final hasExplicitQuantity = qty != null;
                    final isAvailable = item['is_available'] == 1 || item['is_available'] == true;
                    final isSoldOut = hasExplicitQuantity && (qty == 0);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: _buildMealPhoto(item['photo_url'] as String?, name),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('\$${price.toStringAsFixed(2)}'),
                            if (!isAvailable || isSoldOut)
                              Text('Sold out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: isAvailable && !isSoldOut
                            ? IconButton(
                                icon: const Icon(Icons.add_shopping_cart, color: Colors.deepOrange),
                                onPressed: () {
                                  final cart = Provider.of<CartProvider>(context, listen: false);
                                  cart.addItem(id, name, price, restaurantId: widget.restaurantId);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                                },
                              )
                            : null,
                        enabled: isAvailable && !isSoldOut,
                        onTap: isAvailable && !isSoldOut
                            ? () {
                                final cart = Provider.of<CartProvider>(context, listen: false);
                                cart.addItem(id, name, price, restaurantId: widget.restaurantId);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                              }
                            : null,
                      ),
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
