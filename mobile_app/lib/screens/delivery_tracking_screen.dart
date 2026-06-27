import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api_service.dart';
import 'chat_screen.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  const DeliveryTrackingScreen({super.key});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  late List<LatLng> _routePoints;
  late LatLng _pickupLocation;
  late LatLng _dropoffLocation;
  int _driverIndex = 0;
  Timer? _timer;
  bool _trackingActive = true;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int? _orderId;
  Map<String, dynamic>? _orderData;
  bool _locationSharing = false;
  Position? _customerLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderAndInitialize();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initLocationSharing() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      setState(() => _locationSharing = true);
      final position = await Geolocator.getCurrentPosition();
      setState(() => _customerLocation = position);

      if (_orderId != null) {
        final api = Provider.of<ApiService>(context, listen: false);
        await api.updateCustomerLocation(_orderId!, {
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      }
    }
  }

  Future<void> _loadOrderAndInitialize() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    int? orderId;
    if (args is int) {
      orderId = args;
    } else if (args is Map<String, dynamic>) {
      orderId = int.tryParse('${args['id']}') ?? 0;
      _orderData = args;
    }
    setState(() {
      _orderId = orderId;
    });

    try {
      if (_orderData == null && orderId != null) {
        final api = Provider.of<ApiService>(context, listen: false);
        final order = await api.fetchOrder(orderId);
        _orderData = order as Map<String, dynamic>?;
      }
      _initializeRoutePoints();
      _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (!_trackingActive) return;
        if (_driverIndex < _routePoints.length - 1) {
          setState(() {
            _driverIndex += 1;
          });
        } else {
          _timer?.cancel();
        }
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeRoutePoints() {
    _pickupLocation = _getRestaurantLocation(_orderData?['restaurant_id'] as int?);
    _dropoffLocation = _getDropoffLocation(_pickupLocation);
    _routePoints = [
      _pickupLocation,
      LatLng((_pickupLocation.latitude + _dropoffLocation.latitude) / 2, (_pickupLocation.longitude + _dropoffLocation.longitude) / 2),
      _dropoffLocation,
    ];
  }

  LatLng _getRestaurantLocation(int? restaurantId) {
    switch (restaurantId) {
      case 1:
        return const LatLng(37.7749, -122.4194);
      case 2:
        return const LatLng(34.0522, -118.2437);
      case 3:
        return const LatLng(40.7128, -74.0060);
      default:
        return const LatLng(37.7749, -122.4194);
    }
  }

  LatLng _getDropoffLocation(LatLng restaurantLocation) {
    return LatLng(restaurantLocation.latitude + 0.008, restaurantLocation.longitude + 0.006);
  }

  LatLng get _driverLocation => _routePoints[_driverIndex];

  List<Marker> get _markers {
    final markers = <Marker>[
      Marker(point: _pickupLocation, child: const Icon(Icons.restaurant, color: Colors.orange, size: 40)),
      Marker(point: _dropoffLocation, child: const Icon(Icons.person, color: Colors.green, size: 40)),
      Marker(point: _driverLocation, child: const Icon(Icons.my_location, color: Colors.blue, size: 40)),
    ];

    if (_customerLocation != null) {
      markers.add(Marker(
        point: LatLng(_customerLocation!.latitude, _customerLocation!.longitude),
        child: const Icon(Icons.person_pin, color: Colors.red, size: 40),
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Delivery Tracking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Delivery Tracking')),
        body: Center(child: Text('Unable to load tracking: $_errorMessage')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Tracking'),
        centerTitle: true,
        actions: [
          if (_orderId != null)
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(orderId: _orderId!))),
            ),
          Switch(
            value: _locationSharing,
            onChanged: (v) async {
              if (v) {
                await _initLocationSharing();
              } else {
                setState(() => _locationSharing = false);
              }
            },
          ),
          const SizedBox(width: 8),
          const Text('Share location', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _driverLocation,
                initialZoom: 14,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'bitedash',
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(points: _routePoints, color: Colors.deepOrange, strokeWidth: 5),
                    ],
                  ),
                MarkerLayer(markers: _markers),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Live delivery status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rider ETA', style: TextStyle(color: Colors.grey)),
                        Text(_etaText, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Chip(
                      label: Text(_trackingActive ? 'On route' : 'Paused'),
                      backgroundColor: _trackingActive ? Colors.green.shade100 : Colors.grey.shade300,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Tracking order #${_orderId ?? 'unknown'}', style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _trackingActive = !_trackingActive;
                    });
                  },
                  icon: Icon(_trackingActive ? Icons.pause_circle : Icons.play_circle),
                  label: Text(_trackingActive ? 'Pause updates' : 'Resume updates'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _etaText {
    final remaining = _routePoints.length - 1 - _driverIndex;
    final minutes = remaining * 3;
    return '$minutes min';
  }
}