import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../services/cart_provider.dart';
import 'chat_screen.dart';

class RidersScreen extends StatefulWidget {
  final int? orderId;
  const RidersScreen({super.key, this.orderId});

  @override
  State<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends State<RidersScreen> {
  late Future<List<dynamic>> ridersFuture;
  String _searchQuery = '';
  int? _selectedRiderId;
  late Future<List<dynamic>> _couponsFuture;

  @override
  void initState() {
    super.initState();
    ridersFuture = Provider.of<ApiService>(context, listen: false).fetchNearbyRiders(37.7749, -122.4194);
    _couponsFuture = Future.value([]);
  }

  void _openChat(int? orderId, int riderId) {
    if (orderId != null && orderId > 0) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(orderId: orderId)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat available after placing an order')));
    }
  }

  void _requestAdminSupport() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(orderId: -1)));
  }

  Widget _buildRiderPhoto(String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(photoUrl, width: 40, height: 40, fit: BoxFit.cover),
      );
    }
    return const CircleAvatar(child: Icon(Icons.delivery_dining, color: Colors.deepOrange));
  }

  void _selectRider(int riderId) {
    setState(() {
      _selectedRiderId = riderId;
      _couponsFuture = Provider.of<ApiService>(context, listen: false).fetchCouponsByAgent(riderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verified Delivery Riders'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.support_agent), onPressed: _requestAdminSupport, tooltip: 'Contact Admin Support'),
          if (cart.items.isNotEmpty)
            IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () => Navigator.pushNamed(context, '/checkout')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search riders...', border: OutlineInputBorder()),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: ridersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                var riders = snapshot.data ?? [];
                if (_searchQuery.isNotEmpty) {
                  riders = riders.where((r) => (r['full_name'] as String? ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                }
                if (riders.isEmpty) return const Center(child: Text('No verified riders available'));
                return ListView.builder(
                  itemCount: riders.length,
                  itemBuilder: (context, index) {
                    final r = riders[index] as Map<String, dynamic>;
                    final riderId = int.tryParse('${r['id']}') ?? 0;
                    final rating = double.tryParse('${r['rating'] ?? 0}') ?? 0.0;
                    final isFixed = r['is_fixed_price'] == true || r['is_fixed_price'] == '1';
                    final priceLabel = isFixed
                        ? '\$${r['fixed_price'] ?? 0}'
                        : '\$${double.tryParse('${r['price_per_km'] ?? 1.5}') ?? 1.5}/km';
                    final isVerified = r['status'] == 'active' || r['status'] == 'approved';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Stack(
                              children: [
                                _buildRiderPhoto(r['photo_url'] as String?),
                                if (isVerified)
                                  const Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Icon(Icons.verified, color: Colors.green, size: 12),
                                  ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Text(r['full_name'] ?? 'Rider'),
                                if (isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, color: Colors.green, size: 14),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rating: ${rating.toStringAsFixed(1)}★'),
                                Text('Price: $priceLabel'),
                              ],
                            ),
                            trailing: IconButton(icon: const Icon(Icons.chat), onPressed: () => _openChat(widget.orderId, riderId)),
                            onTap: () => _selectRider(riderId),
                          ),
                          if (_selectedRiderId == riderId)
                            FutureBuilder<List<dynamic>>(
                              future: _couponsFuture,
                              builder: (context, couponSnapshot) {
                                if (!couponSnapshot.hasData || couponSnapshot.data!.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text('No coupons available for this rider'),
                                  );
                                }
                                final coupons = couponSnapshot.data!;
                                return Container(
                                  height: 80,
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
