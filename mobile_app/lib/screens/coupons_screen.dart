import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  String _selectedType = 'restaurant';
  late Future<List<dynamic>> couponsFuture;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  void _loadCoupons() {
    couponsFuture = Provider.of<ApiService>(context, listen: false).fetchCoupons(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coupons & Offers'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'restaurant', label: Text('Restaurant')),
                ButtonSegment(value: 'delivery', label: Text('Delivery')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (v) => setState(() => _selectedType = v.first),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: couponsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final coupons = snapshot.data ?? [];
                if (coupons.isEmpty) return const Center(child: Text('No coupons available'));
                return ListView.builder(
                  itemCount: coupons.length,
                  itemBuilder: (context, index) {
                    final c = coupons[index] as Map<String, dynamic>;
                    final discount = (c['discount_percent'] ?? c['discount_amount'] ?? 0).toDouble();
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.local_offer, color: Colors.deepOrange),
                        title: Text(c['code'] ?? 'Coupon'),
                        subtitle: Text(c['description'] ?? 'Save ${discount}%'),
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