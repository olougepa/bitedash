import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';

class DeliveryTrackingScreen extends StatefulWidget {
  const DeliveryTrackingScreen({super.key});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
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

  Future<void> _loadOrderAndInitialize() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    int? orderId;
    if (args is int) {
      orderId = args;
    } else if (args is Map<String, dynamic> && args['id'] is int) {
      orderId = args['id'] as int;
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
          _moveCameraToDriver();
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

  Set<Marker> get _markers {
    return {
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLocation,
        infoWindow: const InfoWindow(title: 'Restaurant'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: _dropoffLocation,
        infoWindow: const InfoWindow(title: 'Delivery address'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('driver'),
        position: _driverLocation,
        infoWindow: const InfoWindow(title: 'Rider'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    };
  }

  Set<Polyline> get _polylines {
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: Colors.deepOrange,
        width: 5,
      ),
    };
  }

  Future<void> _moveCameraToDriver() async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLng(_driverLocation));
  }

  String get _etaText {
    final remaining = _routePoints.length - 1 - _driverIndex;
    final minutes = remaining * 3;
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: AppBar(title: Text('Delivery Tracking')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Delivery Tracking')),
        body: Center(child: Text('Unable to load tracking: $_errorMessage')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Tracking')),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _driverLocation, zoom: 14),
              markers: _markers,
              polylines: _polylines,
              mapType: MapType.normal,
              onMapCreated: (controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
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
}
