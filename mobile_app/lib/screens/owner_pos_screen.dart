import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/auth_provider.dart';
import 'chat_screen.dart';

class OwnerPosScreen extends StatefulWidget {
  const OwnerPosScreen({super.key});

  @override
  State<OwnerPosScreen> createState() => _OwnerPosScreenState();
}

class _OwnerPosScreenState extends State<OwnerPosScreen> {
  late Future<List<dynamic>> _ordersFuture;
  late Future<List<dynamic>> _menuItemsFuture;
  int? _selectedOrderId;
  bool _showMap = false;
  final Completer<GoogleMapController> _mapController = Completer();

  @override
  void initState() {
    super.initState();
    final api = Provider.of<ApiService>(context, listen: false);
    _ordersFuture = api.fetchOwnerOrders();
    _menuItemsFuture = api.fetchAllMenuItems();
  }

  Future<void> _refreshOrders() async {
    final api = Provider.of<ApiService>(context, listen: false);
    setState(() => _ordersFuture = api.fetchOwnerOrders());
  }

  Future<void> _acceptOrder(int orderId) async {
    final api = Provider.of<ApiService>(context, listen: false);
    await api.updateOrder(orderId, {'status': 'accepted'});
    _refreshOrders();
  }

  Future<void> _openChat(int orderId) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(orderId: orderId)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isApproved) {
      return Scaffold(
        appBar: AppBar(title: const Text('Restaurant POS')),
        body: Center(child: Text('Account pending approval. You will be notified when approved.')),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Restaurant POS'),
          bottom: const TabBar(tabs: [Tab(icon: Icon(Icons.receipt_long), text: 'Orders'), Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu')]),
          actions: [
            IconButton(
              icon: Icon(_showMap ? Icons.list : Icons.map),
              onPressed: () => setState(() => _showMap = !_showMap),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _showMap ? _buildMapView() : _buildOrderList(),
            _buildMenuView(),
          ],
        ),
        floatingActionButton: !_showMap && _selectedOrderId != null
            ? FloatingActionButton(
                backgroundColor: Colors.deepOrange,
                onPressed: () => _openChat(_selectedOrderId!),
                child: const Icon(Icons.chat),
              )
            : null,
      ),
    );
  }

  Widget _buildMapView() {
    return FutureBuilder<List<dynamic>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final orders = snapshot.data ?? [];
        final markers = <Marker>{};
        for (final order in orders) {
          if (order['status'] != 'accepted' && order['status'] != 'delivering') continue;
          final restaurant = order['restaurant'] as Map<String, dynamic>?;
          final lat = double.tryParse('${restaurant?['latitude'] ?? 37.7749}') ?? 37.7749;
          final lng = double.tryParse('${restaurant?['longitude'] ?? -122.4194}') ?? -122.4194;
          markers.add(Marker(
            markerId: MarkerId('restaurant-${order['id']}'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: 'Restaurant - Order #${order['id']}'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          ));
          if (order['customer_location'] != null) {
            final loc = order['customer_location'] as Map<String, dynamic>;
            markers.add(Marker(
              markerId: MarkerId('customer-${order['id']}'),
              position: LatLng(double.tryParse('${loc['latitude']}') ?? lat + 0.01, double.tryParse('${loc['longitude']}') ?? lng + 0.01),
              infoWindow: const InfoWindow(title: 'Customer'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ));
          }
        }
        return GoogleMap(
          initialCameraPosition: const CameraPosition(target: LatLng(37.7749, -122.4194), zoom: 12),
          markers: markers,
          mapType: MapType.normal,
          onMapCreated: (controller) {
            if (!_mapController.isCompleted) _mapController.complete(controller);
          },
        );
      },
    );
  }

  Widget _buildOrderList() {
    return FutureBuilder<List<dynamic>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        var orders = snapshot.data ?? [];
        if (orders.isEmpty) return const Center(child: Text('No pending orders'));
        return RefreshIndicator(
          onRefresh: _refreshOrders,
          child: ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index] as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.deepOrange),
                  title: Text('Order #${order['id']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total: \$${order['total'] ?? '0.00'}'),
                      Text('Status: ${order['status'] ?? 'pending'}'),
                    ],
                  ),
                  trailing: order['status'] == 'pending'
                      ? ElevatedButton(onPressed: () => _acceptOrder(order['id'] as int), child: const Text('Accept'))
                      : order['status'] == 'completed'
                          ? const Icon(Icons.check, color: Colors.green)
                          : const SizedBox.shrink(),
                  onTap: () {
                    setState(() => _selectedOrderId = order['id'] as int?);
                    _openChat(order['id'] as int);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMenuView() {
    return FutureBuilder<List<dynamic>>(
      future: _menuItemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var items = snapshot.data ?? [];
        return items.isEmpty
            ? const Center(child: Text('No menu items'))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index] as Map<String, dynamic>;
                  final price = double.tryParse('${item['price'] ?? 0}') ?? 0;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.restaurant_menu, color: Colors.deepOrange)),
                      title: Text(item['name'] ?? 'Item'),
                      subtitle: Text('\$${price.toStringAsFixed(2)}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}),
                      ]),
                    ),
                  );
                },
              );
      },
    );
  }
}