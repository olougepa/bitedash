import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api_service.dart';
import '../services/auth_provider.dart';

class DeliveryAgentScreen extends StatefulWidget {
  const DeliveryAgentScreen({super.key});

  @override
  State<DeliveryAgentScreen> createState() => _DeliveryAgentScreenState();
}

class _DeliveryAgentScreenState extends State<DeliveryAgentScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];
  int? _selectedOrderId;
  bool _locationSharing = true;
  Position? _currentPosition;
  Timer? _locationTimer;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
      _initLocation();
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      setState(() => _locationSharing = true);
      _updateLocation();
      _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) => _updateLocation());
    }
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);

      final api = Provider.of<ApiService>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token;
      if (token != null) {
        await api.updateDeliveryLocation({
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      }
    } catch (_) {}
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final orders = await api.fetchDeliveryOrders();
      setState(() => _orders = List<Map<String, dynamic>>.from(orders as List));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load orders: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acceptOrder(int orderId) async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.updateOrder(orderId, {'status': 'accepted'});
      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to accept order')));
    }
  }

  Future<void> _markDelivered(int orderId) async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      await api.updateOrder(orderId, {'status': 'delivered'});
      _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update order')));
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    for (final order in _orders.where((o) => o['status'] == 'accepted')) {
      final restaurant = order['restaurant'] as Map<String, dynamic>?;
      if (restaurant != null) {
        final lat = restaurant['latitude'] as double? ?? 37.7749;
        final lng = restaurant['longitude'] as double? ?? -122.4194;
        markers.add(Marker(
          markerId: MarkerId('restaurant-${order['id']}'),
          position: LatLng(lat, lng),
          infoWindow: const InfoWindow(title: 'Restaurant'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ));
      }

      final customerLoc = order['customer_location'] as Map<String, dynamic>?;
      final lat = customerLoc?['latitude'] as double? ?? (restaurant?['latitude'] as double? ?? 37.7749) + 0.01;
      final lng = customerLoc?['longitude'] as double? ?? (restaurant?['longitude'] as double? ?? -122.4194) + 0.01;
      markers.add(Marker(
        markerId: MarkerId('customer-${order['id']}'),
        position: LatLng(lat, lng),
        infoWindow: const InfoWindow(title: 'Customer'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    if (_currentPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        infoWindow: const InfoWindow(title: 'You'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isApproved) {
      return Scaffold(
        appBar: AppBar(title: const Text('Delivery Agent')),
        body: Center(child: Text('Account pending approval. You will be notified when approved.')),
      );
    }

    final isDeliveryAgent = auth.user?.role == 'delivery_agent';
    final isAdmin = auth.user?.role == 'admin';

    if (!isDeliveryAgent && !isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Delivery Agent')),
        body: const Center(child: Text('Access restricted to delivery agents.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Agent'),
        actions: [
          Switch(
            value: _locationSharing,
            onChanged: (v) => setState(() => _locationSharing = v),
          ),
          const SizedBox(width: 8),
          Text('Share location', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 16),
          Switch(
            value: _isOnline,
            onChanged: (v) => setState(() => _isOnline = v),
          ),
          const SizedBox(width: 8),
          Text('Online', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 16),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition != null
                          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                          : const LatLng(37.7749, -122.4194),
                      zoom: 14,
                    ),
                    markers: _buildMarkers(),
                    mapType: MapType.normal,
                    onMapCreated: (controller) {
                      if (!_mapController.isCompleted) {
                        _mapController.complete(controller);
                      }
                    },
                    myLocationEnabled: _locationSharing,
                    myLocationButtonEnabled: true,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  flex: 2,
                  child: _orders.isEmpty
                      ? const Center(child: Text('No active deliveries'))
                      : ListView.builder(
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            final isSelected = _selectedOrderId == order['id'];
                            return Card(
                              color: isSelected ? Colors.deepOrange.shade50 : null,
                              child: ListTile(
                                title: Text('Order #${order['id']}'),
                                subtitle: Text('Total: \$${order['total']} • Status: ${order['status']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (order['status'] == 'accepted')
                                      IconButton(
                                        icon: const Icon(Icons.check, color: Colors.green),
                                        onPressed: () => _markDelivered(order['id'] as int),
                                        tooltip: 'Mark delivered',
                                      ),
                                    if (order['status'] == 'pending')
                                      IconButton(
                                        icon: const Icon(Icons.play_arrow, color: Colors.blue),
                                        onPressed: () => _acceptOrder(order['id'] as int),
                                        tooltip: 'Accept order',
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  setState(() => _selectedOrderId = order['id'] as int?);
                                  _focusOnOrder(order);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _focusOnOrder(Map<String, dynamic> order) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;

    final restaurant = order['restaurant'] as Map<String, dynamic>?;
    if (restaurant != null) {
      final lat = restaurant['latitude'] as double? ?? 37.7749;
      final lng = restaurant['longitude'] as double? ?? -122.4194;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15));
    }
  }
}