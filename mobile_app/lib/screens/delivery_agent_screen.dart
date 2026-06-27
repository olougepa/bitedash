import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

import '../services/api_service.dart';
import '../services/auth_provider.dart';

class DeliveryAgentScreen extends StatefulWidget {
  const DeliveryAgentScreen({super.key});

  @override
  State<DeliveryAgentScreen> createState() => _DeliveryAgentScreenState();
}

class _DeliveryAgentScreenState extends State<DeliveryAgentScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];
  int? _selectedOrderId;
  bool _locationSharing = true;
  Position? _currentPosition;
  Timer? _locationTimer;
  bool _isOnline = true;
  Map<String, dynamic>? _myAgent;
  List<LatLng> _routePoints = [];
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAgent();
      _loadOrders();
      _initLocation();
    });
  }

  Future<void> _loadAgent() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final agent = await api.fetchMyDeliveryAgent();
    if (mounted && agent != null) {
      setState(() {
        _myAgent = agent;
        _statsFuture = api.fetchDeliveryStats(int.tryParse('${agent['id']}') ?? 0);
      });
    }
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
      _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) => _updateLocation());
    }
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _currentPosition = position);
      }

      final api = Provider.of<ApiService>(context, listen: false);
      await api.updateDeliveryLocation({
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } catch (_) {}
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final orders = await api.fetchDeliveryOrders();
      if (!mounted) return;
      setState(() => _orders = List<Map<String, dynamic>>.from(orders as List));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load orders: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<LatLng>> _fetchRoute(double lat1, double lng1, double lat2, double lng2) async {
    final response = await http.get(
      Uri.parse('http://router.project-osrm.org/route/v1/driving/$lng1,$lat1;$lng2,$lat2?geometries=geojson'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List<dynamic>;
      return coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
    }
    return [];
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

  Future<void> _showRouteForOrder(Map<String, dynamic> order) async {
    if (_currentPosition == null) return;
    final restaurant = order['restaurant'] as Map<String, dynamic>?;
    final customerLoc = order['customer_location'] as Map<String, dynamic>?;
    
    if (restaurant != null || customerLoc != null) {
      final targetLat = customerLoc?['latitude'] ?? (restaurant?['latitude'] as double? ?? 37.7749);
      final targetLng = customerLoc?['longitude'] ?? (restaurant?['longitude'] as double? ?? -122.4194);
      
      final points = await _fetchRoute(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        targetLat,
        targetLng,
      );
      if (mounted) {
        setState(() => _routePoints = points);
      }
    }
  }

  void _editAgency() {
    if (_myAgent == null) return;
    showDialog(
      context: context,
      builder: (ctx) => _EditAgencyDialog(agent: _myAgent!, onSave: _loadAgent),
    );
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
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Stats',
            onPressed: () => _showStatsDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.local_offer),
            tooltip: 'Coupons',
            onPressed: () => Navigator.pushNamed(context, '/coupon-manager'),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepOrange),
              child: Text('Delivery Agent', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Deliveries'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Agency'),
              onTap: () {
                Navigator.pop(context);
                _editAgency();
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.location_on),
              title: const Text('Share location'),
              value: _locationSharing,
              onChanged: (v) => setState(() {
                _locationSharing = v;
                Navigator.pop(context);
              }),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.wifi),
              title: const Text('Online'),
              value: _isOnline,
              onChanged: (v) => setState(() {
                _isOnline = v;
                Navigator.pop(context);
              }),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                await auth.logout();
                if (mounted) Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          if (_myAgent != null && _myAgent!['price_per_km'] == null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.orange.shade50,
                padding: const EdgeInsets.all(12),
                child: const Text('Please set your price per km in Edit Agency', textAlign: TextAlign.center, style: TextStyle(color: Colors.orange)),
              ),
            ),
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(37.7749, -122.4194),
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
                    Polyline(points: _routePoints, color: Colors.deepOrange, strokeWidth: 4),
                  ],
                ),
              MarkerLayer(
                markers: _buildFlutterMarkers(),
              ),
              if (_locationSharing && _currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
                    ),
                  ],
                ),
            ],
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
              ),
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
                                    onPressed: () => _markDelivered(int.tryParse('${order['id']}') ?? 0),
                                    tooltip: 'Mark delivered',
                                  ),
                                if (order['status'] == 'pending')
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow, color: Colors.blue),
                                    onPressed: () => _acceptOrder(int.tryParse('${order['id']}') ?? 0),
                                    tooltip: 'Accept order',
                                  ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                _selectedOrderId = int.tryParse('${order['id']}') ?? 0;
                                _routePoints = [];
                              });
                              _showRouteForOrder(order);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showStatsDialog() async {
    final stats = await _statsFuture;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delivery Stats'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _buildStatCard('Today', '\$${stats['today_earnings'] ?? 0}', Icons.attach_money, Colors.green),
                    _buildStatCard('Deliveries', '${stats['total_deliveries'] ?? 0}', Icons.delivery_dining, Colors.orange),
                    _buildStatCard('Avg', '\$${stats['avg_earning'] ?? 0}', Icons.bar_chart, Colors.blue),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: _buildBarChart(stats['weekly_earnings'] ?? []),
                ),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<dynamic> weeklyEarnings) {
    if (weeklyEarnings.isEmpty) {
      return const Center(child: Text('No earnings data'));
    }
    final barGroups = weeklyEarnings.asMap().map((i, e) {
      final dayEarnings = double.tryParse('${e['earnings'] ?? 0}') ?? 0;
      return MapEntry(i, BarChartGroupData(x: i, barRods: [BarChartRodData(toY: dayEarnings, color: Colors.deepOrange, width: 16)]));
    }).values.toList();
    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Text(days[value.toInt() % days.length]);
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Marker> _buildFlutterMarkers() {
    final markers = <Marker>[];

    for (final order in _orders.where((o) => o['status'] == 'accepted')) {
      final restaurant = order['restaurant'] as Map<String, dynamic>?;
      final lat = restaurant?['latitude'] as double? ?? 37.7749;
      final lng = restaurant?['longitude'] as double? ?? -122.4194;
      markers.add(Marker(
        point: LatLng(lat, lng),
        child: const Icon(Icons.restaurant, color: Colors.orange, size: 40),
      ));

      final customerLoc = order['customer_location'] as Map<String, dynamic>?;
      final cLat = customerLoc?['latitude'] as double? ?? lat + 0.01;
      final cLng = customerLoc?['longitude'] as double? ?? lng + 0.01;
      markers.add(Marker(
        point: LatLng(cLat, cLng),
        child: const Icon(Icons.person, color: Colors.green, size: 40),
      ));
    }

    return markers;
  }
}

class _EditAgencyDialog extends StatefulWidget {
  final Map<String, dynamic> agent;
  final VoidCallback onSave;
  const _EditAgencyDialog({required this.agent, required this.onSave});

  @override
  State<_EditAgencyDialog> createState() => _EditAgencyDialogState();
}

class _EditAgencyDialogState extends State<_EditAgencyDialog> {
  late TextEditingController _nameController;
  late TextEditingController _pricePerKmController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.agent['agency_name'] ?? '');
    _pricePerKmController = TextEditingController(text: '${widget.agent['price_per_km'] ?? '1.50'}');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pricePerKmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDefaultName = (widget.agent['agency_name'] ?? '').toString().contains(' Agency');
    return AlertDialog(
      title: const Text('Edit Agency Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDefaultName)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.orange.shade50,
                child: const Text('Please change the default agency name', style: TextStyle(color: Colors.orange)),
              ),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Agency Name')),
            TextField(controller: _pricePerKmController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price per km')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final api = Provider.of<ApiService>(context, listen: false);
            await api.updateDeliveryAgent(int.tryParse('${widget.agent['id']}') ?? 0, {
              'agency_name': _nameController.text,
              'price_per_km': double.tryParse(_pricePerKmController.text) ?? 1.50,
            });
            widget.onSave();
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}