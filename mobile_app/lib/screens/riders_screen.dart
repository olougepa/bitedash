import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'chat_screen.dart';

class RidersScreen extends StatefulWidget {
  final int? orderId;
  const RidersScreen({super.key, this.orderId});

  @override
  State<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends State<RidersScreen> {
  late Future<List<dynamic>> ridersFuture;

  @override
  void initState() {
    super.initState();
    ridersFuture = Provider.of<ApiService>(context, listen: false).fetchNearbyRiders(37.7749, -122.4194);
  }

  Future<void> _refresh() async {
    setState(() {
      ridersFuture = Provider.of<ApiService>(context, listen: false).fetchNearbyRiders(37.7749, -122.4194);
    });
  }

  void _openChat(int? orderId, int riderId) {
    if (orderId != null && orderId > 0) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(orderId: orderId)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat available after placing an order')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verified Delivery Riders'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ridersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final riders = snapshot.data ?? [];
          if (riders.isEmpty) return const Center(child: Text('No verified riders available'));
          return ListView.builder(
            itemCount: riders.length,
            itemBuilder: (context, index) {
              final r = riders[index] as Map<String, dynamic>;
              final rating = double.tryParse('${r['rating'] ?? 0}') ?? 0.0;
              final pricePerKm = double.tryParse('${r['price_per_km'] ?? 1.5}') ?? 1.5;
              final isVerified = r['status'] == 'active' || r['status'] == 'approved';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Stack(
                    children: [
                      const CircleAvatar(child: Icon(Icons.delivery_dining, color: Colors.deepOrange)),
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
                      Text('★ ${rating.toStringAsFixed(1)}'),
                      Text('Price: \$${pricePerKm}/km'),
                    ],
                  ),
                  trailing: IconButton(icon: const Icon(Icons.chat), onPressed: () => _openChat(widget.orderId, r['id'] as int)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}