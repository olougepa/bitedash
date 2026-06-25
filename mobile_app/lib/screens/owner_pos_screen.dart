import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  late Future<Map<String, dynamic>?> _restaurantFuture;
  int? _selectedOrderId;
  bool _showMap = false;
  int? _restaurantId;

  @override
  void initState() {
    super.initState();
    final api = Provider.of<ApiService>(context, listen: false);
    _restaurantFuture = api.fetchMyRestaurant().then((restaurant) {
      if (restaurant != null) {
        _restaurantId = restaurant['id'] as int?;
        _menuItemsFuture = api.fetchMenuForRestaurant(restaurant['id'] as int);
      }
      return restaurant;
    });
    _ordersFuture = api.fetchOwnerOrders();
  }

  Future<void> _refreshOrders() async {
    final api = Provider.of<ApiService>(context, listen: false);
    setState(() {
      _ordersFuture = api.fetchOwnerOrders();
      _menuItemsFuture = _restaurantId != null ? api.fetchMenuForRestaurant(_restaurantId!) : Future.value([]);
    });
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
          centerTitle: true,
          bottom: const TabBar(tabs: [Tab(icon: Icon(Icons.receipt_long), text: 'Orders'), Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu')]),
          actions: [
            IconButton(
              icon: Icon(_showMap ? Icons.list : Icons.map),
              onPressed: () => setState(() => _showMap = !_showMap),
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
                child: Text('Restaurant Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
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
                leading: const Icon(Icons.receipt_long),
                title: const Text('Orders'),
                onTap: () {
                  Navigator.pop(context);
                  DefaultTabController.maybeOf(context)?.animateTo(0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.restaurant_menu),
                title: const Text('Menu Items'),
                onTap: () {
                  Navigator.pop(context);
                  DefaultTabController.maybeOf(context)?.animateTo(1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_offer),
                title: const Text('Coupons'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/coupons');
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Restaurant'),
                onTap: () {
                  Navigator.pop(context);
                  _editRestaurant();
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.map),
                title: const Text('Map View'),
                value: _showMap,
                onChanged: (v) => setState(() {
                  _showMap = v;
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
        body: TabBarView(
          children: [
            _showMap ? _buildMapView() : _buildOrderList(),
            _buildMenuView(),
          ],
        ),
        floatingActionButton: _showMap
            ? null
            : DefaultTabController.maybeOf(context)?.index == 1
                ? FloatingActionButton(
                    backgroundColor: Colors.deepOrange,
                    onPressed: _addMenuItem,
                    child: const Icon(Icons.add),
                  )
                : _selectedOrderId != null
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
        return FlutterMap(
          options: MapOptions(
            initialCenter: const LatLng(37.7749, -122.4194),
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'bitedash',
            ),
            MarkerLayer(markers: _buildMapMarkers(orders)),
          ],
        );
      },
    );
  }

  List<Marker> _buildMapMarkers(List<dynamic> orders) {
    final markers = <Marker>[];
    for (final order in orders) {
      if (order['status'] != 'accepted' && order['status'] != 'delivering') continue;
      final restaurant = order['restaurant'] as Map<String, dynamic>?;
      final lat = restaurant?['latitude'] as double? ?? 37.7749;
      final lng = restaurant?['longitude'] as double? ?? -122.4194;
      markers.add(Marker(
        point: LatLng(lat, lng),
        child: const Icon(Icons.restaurant, color: Colors.orange, size: 40),
      ));
      if (order['customer_location'] != null) {
        final loc = order['customer_location'] as Map<String, dynamic>;
        markers.add(Marker(
          point: LatLng(double.tryParse('${loc['latitude']}') ?? lat + 0.01, double.tryParse('${loc['longitude']}') ?? lng + 0.01),
          child: const Icon(Icons.person, color: Colors.green, size: 40),
        ));
      }
    }
    return markers;
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
    return FutureBuilder<Map<String, dynamic>?>(
      future: _restaurantFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final restaurant = snapshot.data;
        return FutureBuilder<List<dynamic>>(
          future: _menuItemsFuture,
          builder: (context, menuSnapshot) {
            if (menuSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            var items = menuSnapshot.data ?? [];
            final isDefaultRestaurant = restaurant?['name'] == 'My Restaurant';
            final hasNoItems = items.isEmpty;

            if (hasNoItems) {
              return Column(
                children: [
                  if (isDefaultRestaurant)
                    Container(
                      width: double.infinity,
                      color: Colors.orange.shade50,
                      padding: const EdgeInsets.all(12),
                      child: const Text('Please edit your restaurant name and add logo/banner', textAlign: TextAlign.center, style: TextStyle(color: Colors.orange)),
                    ),
                  if (hasNoItems)
                    Container(
                      width: double.infinity,
                      color: Colors.orange.shade50,
                      padding: const EdgeInsets.all(12),
                      child: const Text('Add menu items to your restaurant', textAlign: TextAlign.center, style: TextStyle(color: Colors.orange)),
                    ),
                  const Expanded(child: Center(child: Text('Tap + to add items'))),
                ],
              );
            }

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index] as Map<String, dynamic>;
                final price = double.tryParse('${item['price'] ?? 0}') ?? 0;
                final qty = item['quantity'];
                final stockQty = item['stock_quantity'];
                final currentQty = qty ?? stockQty ?? 0;
                final isAvailable = item['is_available'] == 1 || item['is_available'] == true;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (currentQty > 0 || qty == null) && isAvailable ? Colors.green.shade100 : Colors.red.shade100,
                      child: Icon((isAvailable && (currentQty > 0 || qty == null)) ? Icons.restaurant_menu : Icons.remove_shopping_cart, color: Colors.deepOrange),
                    ),
                    title: Text(item['name'] ?? 'Item'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('\$${price.toStringAsFixed(2)}'),
                        Text('Stock: ${qty == null ? 'Unlimited' : currentQty} | Available: ${isAvailable ? 'Yes' : 'No'}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editMenuItem(item)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {}),
                    ]),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _addMenuItem() async {
    final restaurantId = _restaurantId;
    if (restaurantId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurant not found. Please contact support.')));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => _AddMenuItemDialog(restaurantId: restaurantId, onSave: _refreshOrders),
    );
  }

  void _editMenuItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => _EditMenuItemDialog(item: item, onSave: _refreshOrders),
    );
  }

  void _editRestaurant() async {
    final restaurant = await _restaurantFuture;
    if (restaurant == null) return;
    showDialog(
      context: context,
      builder: (ctx) => _EditRestaurantDialog(restaurant: restaurant, onSave: _refreshOrders),
    );
  }
}

class _EditMenuItemDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onSave;
  const _EditMenuItemDialog({required this.item, required this.onSave});

  @override
  State<_EditMenuItemDialog> createState() => _EditMenuItemDialogState();
}

class _EditMenuItemDialogState extends State<_EditMenuItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _qtyController;
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item['name'] ?? '');
    _priceController = TextEditingController(text: '${widget.item['price'] ?? ''}');
    _descController = TextEditingController(text: widget.item['description'] ?? '');
    _qtyController = TextEditingController(text: '${widget.item['quantity'] ?? widget.item['stock_quantity'] ?? ''}');
    _isAvailable = widget.item['is_available'] == 1 || widget.item['is_available'] == true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Menu Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Item Name')),
          TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
          TextField(controller: _descController, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
          TextField(controller: _qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity (leave empty for unlimited)')),
          SwitchListTile(title: const Text('Available'), value: _isAvailable, onChanged: (v) => setState(() => _isAvailable = v)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final api = Provider.of<ApiService>(context, listen: false);
            final qty = _qtyController.text.isEmpty ? null : int.tryParse(_qtyController.text) ?? 0;
            await api.updateMenuItem(widget.item['id'] as int, {
              'name': _nameController.text,
              'price': double.tryParse(_priceController.text) ?? 0,
              'description': _descController.text,
              'quantity': qty,
              'is_available': _isAvailable ? 1 : 0,
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

class _AddMenuItemDialog extends StatefulWidget {
  final int restaurantId;
  final VoidCallback onSave;
  const _AddMenuItemDialog({required this.restaurantId, required this.onSave});

  @override
  State<_AddMenuItemDialog> createState() => _AddMenuItemDialogState();
}

class _AddMenuItemDialogState extends State<_AddMenuItemDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _qtyController = TextEditingController();
  bool _isAvailable = true;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Menu Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Item Name')),
          TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
          TextField(controller: _descController, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
          TextField(controller: _qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity (leave empty for unlimited)')),
          SwitchListTile(title: const Text('Available'), value: _isAvailable, onChanged: (v) => setState(() => _isAvailable = v)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final api = Provider.of<ApiService>(context, listen: false);
            final qty = _qtyController.text.isEmpty ? null : int.tryParse(_qtyController.text) ?? 0;
            await api.createMenuItem({
              'restaurant_id': widget.restaurantId,
              'name': _nameController.text,
              'price': double.tryParse(_priceController.text) ?? 0,
              'description': _descController.text,
              'quantity': qty,
              'is_available': _isAvailable ? 1 : 0,
            });
            widget.onSave();
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _EditRestaurantDialog extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  final VoidCallback onSave;
  const _EditRestaurantDialog({required this.restaurant, required this.onSave});

  @override
  State<_EditRestaurantDialog> createState() => _EditRestaurantDialogState();
}

class _EditRestaurantDialogState extends State<_EditRestaurantDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _logoController;
  late TextEditingController _bannerController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.restaurant['name'] ?? '');
    _descController = TextEditingController(text: widget.restaurant['description'] ?? '');
    _logoController = TextEditingController(text: widget.restaurant['logo_url'] ?? '');
    _bannerController = TextEditingController(text: widget.restaurant['banner_url'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _logoController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Restaurant'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.restaurant['name'] == 'My Restaurant')
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.orange.shade50,
                child: const Text('Please change the default restaurant name and add logo/banner', style: TextStyle(color: Colors.orange)),
              ),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Restaurant Name')),
            TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
            TextField(controller: _logoController, decoration: const InputDecoration(labelText: 'Logo URL (optional)')),
            TextField(controller: _bannerController, decoration: const InputDecoration(labelText: 'Banner URL (optional)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final api = Provider.of<ApiService>(context, listen: false);
            await api.updateRestaurant(widget.restaurant['id'] as int, {
              'name': _nameController.text,
              'description': _descController.text,
              'logo_url': _logoController.text,
              'banner_url': _bannerController.text,
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