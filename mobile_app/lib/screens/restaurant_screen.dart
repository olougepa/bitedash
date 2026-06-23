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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    restaurantFuture = Provider.of<ApiService>(context, listen: false).fetchRestaurant(widget.restaurantId);
    menuFuture = Provider.of<ApiService>(context, listen: false).fetchMenuForRestaurant(widget.restaurantId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
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
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(restaurant['name'] ?? 'Restaurant', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Row(children: [
                        Icon(Icons.star, color: Colors.orange, size: 16),
                        Text(' ${rating.toStringAsFixed(1)}', style: TextStyle(color: Colors.orange)),
                      ]),
                      if (lat != 0 && lng != 0)
                        Text('Location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}', style: TextStyle(color: Colors.grey)),
                      Text(restaurant['description'] ?? ''),
                    ],
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search meals...', border: OutlineInputBorder()),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
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
                    final mealRating = double.tryParse('${item['rating'] ?? 0}') ?? 0.0;
                    final isAvailable = item['is_available'] == 1 || item['is_available'] == true;
                    final qty = item['quantity'];
                    final hasExplicitQuantity = qty != null;
                    final isSoldOut = hasExplicitQuantity && (qty == 0);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('\$${price.toStringAsFixed(2)}'),
                            Row(children: [
                              Icon(Icons.star, color: Colors.orange, size: 14),
                              Text(' ${mealRating.toStringAsFixed(1)}', style: TextStyle(fontSize: 12, color: Colors.orange)),
                            ]),
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
                              : const SizedBox.shrink(),
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