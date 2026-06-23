import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class RidersScreen extends StatefulWidget {
  const RidersScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Riders'),
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
          if (riders.isEmpty) return const Center(child: Text('No riders available'));
          return ListView.builder(
            itemCount: riders.length,
            itemBuilder: (context, index) {
              final r = riders[index] as Map<String, dynamic>;
              final rating = double.tryParse('${r['rating'] ?? 0}') ?? 0.0;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.delivery_dining, color: Colors.deepOrange)),
                  title: Text(r['full_name'] ?? 'Rider'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('★ ${rating.toStringAsFixed(1)}'),
                      Text('Price list: Base fare \$2.99 + \$${r['price_per_km'] ?? 1.5}/km'),
                    ],
                  ),
                  trailing: IconButton(icon: const Icon(Icons.chat), onPressed: () {}),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}