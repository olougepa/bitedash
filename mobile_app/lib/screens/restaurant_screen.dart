import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/menu_item_card.dart';
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
  late Future<List<dynamic>> menuFuture;

  @override
  void initState() {
    super.initState();
    menuFuture = Provider.of<ApiService>(context, listen: false).fetchMenuForRestaurant(widget.restaurantId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.restaurantName)),
      body: FutureBuilder<List<dynamic>>(
        future: menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index] as Map<String, dynamic>;
              final id = item['id'] as int? ?? 0;
              final name = item['name'] as String? ?? 'Dish';
              final price = (item['price'] ?? 0).toDouble();
              return MenuItemCard(
                title: name,
                description: item['description'] ?? '',
                price: price,
                available: item['is_available'] == true,
                onTap: () {
                  final cart = Provider.of<CartProvider>(context, listen: false);
                  cart.addItem(id, name, price);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                },
              );
            },
          );
        },
      ),
    );
  }
}
