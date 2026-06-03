import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';

class OwnerPosScreen extends StatefulWidget {
  const OwnerPosScreen({super.key});

  @override
  State<OwnerPosScreen> createState() => _OwnerPosScreenState();
}

class _OwnerPosScreenState extends State<OwnerPosScreen> {
  late Future<List<dynamic>> _ordersFuture;
  final TextEditingController _itemController = TextEditingController(text: 'Espresso');
  final TextEditingController _tableController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _ordersFuture = Provider.of<ApiService>(context, listen: false).fetchOwnerOrders();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.user?.role != 'restaurant_owner') {
      return Scaffold(
        appBar: AppBar(title: const Text('Restaurant POS')),
        body: const Center(child: Text('Access restricted to restaurant owners.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant POS')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick in-store sale', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _itemController,
                      decoration: const InputDecoration(labelText: 'Item'),
                    ),
                    TextField(
                      controller: _tableController,
                      decoration: const InputDecoration(labelText: 'Table / Register'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quick sale added to POS order')));
                      },
                      child: const Text('Add sale'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final orders = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index] as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text('Order #${order['id']}'),
                          subtitle: Text('Total: \$${order['total']} · Status: ${order['status']}'),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              try {
                                final api = Provider.of<ApiService>(context, listen: false);
                                await api.updateOrder(order['id'] as int, {
                                  ...order,
                                  'status': 'accepted',
                                });
                                setState(() {
                                  _ordersFuture = api.fetchOwnerOrders();
                                });
                              } catch (_) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to accept order')));
                              }
                            },
                            child: const Text('Accept'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
