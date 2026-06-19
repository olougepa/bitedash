import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  int? _selectedOrderId;
  bool _showMap = false;
  final Completer<GoogleMapController> _mapController = Completer();

  @override
  void initState() {
    super.initState();
    _ordersFuture = Provider.of<ApiService>(context, listen: false).fetchOwnerOrders();
  }

  Set<Marker> _buildMarkers(List<dynamic> orders) {
    final markers = <Marker>{};
    for (final order in orders) {
      if (order['status'] != 'accepted' && order['status'] != 'delivering') continue;
      
      final restaurant = order['restaurant'] as Map<String, dynamic>?;
      final lat = restaurant?['latitude'] as double? ?? 37.7749;
      final lng = restaurant?['longitude'] as double? ?? -122.4194;
      
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
          position: LatLng(loc['latitude'] as double? ?? lat + 0.01, loc['longitude'] as double? ?? lng + 0.01),
          infoWindow: const InfoWindow(title: 'Customer'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ));
      }
    }
    return markers;
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
      appBar: AppBar(
        title: const Text('Restaurant POS'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
        ],
      ),
      body: _showMap ? _buildMapView() : _buildOrderList(),
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

        return Column(
          children: [
            Expanded(
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(37.7749, -122.4194),
                  zoom: 12,
                ),
                markers: _buildMarkers(orders),
                mapType: MapType.normal,
                onMapCreated: (controller) {
                  if (!_mapController.isCompleted) {
                    _mapController.complete(controller);
                  }
                },
              ),
            ),
          ],
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
        final orders = snapshot.data ?? [];
        return orders.isEmpty
            ? const Center(child: Text('No pending orders'))
            : ListView.builder(
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
                            await api.updateOrder(order['id'] as int, {'status': 'accepted'});
                            setState(() {
                              _ordersFuture = api.fetchOwnerOrders();
                            });
                          } catch (_) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to accept order')));
                          }
                        },
                        child: const Text('Accept'),
                      ),
                      onTap: () {
                        setState(() => _selectedOrderId = order['id'] as int?);
                      },
                    ),
                  );
                },
              );
      },
    );
  }
}