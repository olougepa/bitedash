import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _loading = false;
  String _paymentMethod = 'cash';
  String _cardNumber = '';
  String _cardExpiry = '';
  String _guestPhone = '';
  String _deliveryLocation = '';
  bool _useCurrentLocation = false;
  List<dynamic> _riders = [];
  int? _selectedRiderId;
  double _defaultPricePerKm = 1.50;
  bool _deliveryFeeFixed = false;
  double _fixedDeliveryFee = 0.0;

  Future<void> _loadRiders() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final riders = await api.fetchNearbyRiders(37.7749, -122.4194);
    final settings = await api.fetchSystemSettings();
    setState(() {
      _riders = riders;
      if (settings['default_price_per_km'] != null) {
        _defaultPricePerKm = double.tryParse('${settings['default_price_per_km']}') ?? 1.50;
        _deliveryFeeFixed = settings['delivery_fee_fixed'] == true || settings['delivery_fee_fixed'] == '1';
        _fixedDeliveryFee = double.tryParse('${settings['fixed_delivery_fee'] ?? 0}') ?? 0.0;
      }
    });
  }

  double _calculateDeliveryFee() {
    if (_deliveryFeeFixed && _fixedDeliveryFee > 0) return _fixedDeliveryFee;
    final selectedRider = _selectedRiderId != null
        ? _riders.firstWhere((r) => int.tryParse('${r['id']}') == _selectedRiderId, orElse: () => null)
        : null;
    final distance = 5.0;
    if (selectedRider != null) {
      final riderFixed = selectedRider['delivery_fee_fixed'] == true || selectedRider['delivery_fee_fixed'] == '1';
      if (riderFixed) return double.tryParse('${selectedRider['fixed_delivery_fee'] ?? 0}') ?? _defaultPricePerKm * distance;
      return (double.tryParse('${selectedRider['price_per_km'] ?? 1.5}') ?? _defaultPricePerKm) * distance;
    }
    return _defaultPricePerKm * distance;
  }

  Widget _buildTotalRow(double subtotal) {
    final deliveryFee = _calculateDeliveryFee();
    final total = subtotal + deliveryFee;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Subtotal'),
          Text('\$${subtotal.toStringAsFixed(2)}'),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_deliveryFeeFixed ? 'Delivery Fee (Fixed)' : 'Delivery Fee (estimated)'),
          Text('\$${deliveryFee.toStringAsFixed(2)}'),
        ]),
        const Text('Est. ~5km distance', style: TextStyle(color: Colors.grey, fontSize: 11)),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ],
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _loading = true);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final deliveryFee = _calculateDeliveryFee();
    final items = cart.items
        .map((e) => {'menu_item_id': e.id, 'quantity': e.quantity, 'unit_price': e.price})
        .toList();
    final total = cart.total + deliveryFee;
    final payload = {
      'order_type': 'delivery',
      'restaurant_id': cart.items.isNotEmpty ? cart.items.first.restaurantId : 1,
      'items': items,
      'sub_total': cart.total,
      'delivery_fee': deliveryFee,
      'total': total,
      'payment_method': _paymentMethod,
      'payment_stub': {
        'method': _paymentMethod,
        'card_number': _paymentMethod == 'card' && _cardNumber.length >= 4
            ? '**** **** **** ${_cardNumber.substring(_cardNumber.length - 4)}'
            : _paymentMethod == 'wallet'
                ? 'Mobile Money'
                : 'cash',
        'expiry': _paymentMethod == 'card' ? _cardExpiry : null,
      },
      'delivery_location': _useCurrentLocation ? null : _deliveryLocation,
      if (!auth.isAuthenticated) 'guest_phone': _guestPhone,
      if (_selectedRiderId != null) 'delivery_agent_id': _selectedRiderId,
    };
    try {
      final res = await api.submitOrder(payload);
      cart.clear();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/order-confirmation', arguments: res);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRiders();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ListView(children: [
              const Text('Your Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...cart.items.map((e) => Dismissible(
                key: Key('cart-item-${e.id}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => cart.removeItem(e.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  title: Text(e.name),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('\$${e.price.toStringAsFixed(2)}'),
                    const SizedBox(width: 8),
                    Text('x${e.quantity}'),
                    IconButton(icon: const Icon(Icons.remove, color: Colors.orange), onPressed: () {
                      if (e.quantity > 1) {
                        cart.updateQuantity(e.id, e.quantity - 1);
                      } else {
                        cart.removeItem(e.id);
                      }
                    }),
                    IconButton(icon: const Icon(Icons.add, color: Colors.green), onPressed: () {
                      cart.updateQuantity(e.id, e.quantity + 1);
                    }),
                  ]),
                ),
              )),
              const SizedBox(height: 16),
              const Text('Delivery Location', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.my_location),
                title: const Text('Use current location'),
                trailing: Switch(value: _useCurrentLocation, onChanged: (v) => setState(() => _useCurrentLocation = v)),
              ),
              if (!_useCurrentLocation)
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Enter delivery address',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _deliveryLocation = v),
                ),
              const SizedBox(height: 16),
              const Text('Rider Selection', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _riders.isEmpty
                  ? const Text('No riders available')
                  : Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Any rider'),
                          selected: _selectedRiderId == null,
                          onSelected: (_) => setState(() => _selectedRiderId = null),
                        ),
                        ..._riders.map<Widget>((r) {
                          final riderId = int.tryParse('${r['id']}') ?? 0;
                          final rating = double.tryParse('${r['rating'] ?? 0}') ?? 0.0;
                          final pricePerKm = double.tryParse('${r['price_per_km'] ?? 1.5}') ?? _defaultPricePerKm;
                          return ChoiceChip(
                            label: Text('Rider $riderId (${rating.toStringAsFixed(1)}★) \$${pricePerKm}/km'),
                            selected: _selectedRiderId == riderId,
                            onSelected: (selected) {
                              setState(() => _selectedRiderId = selected ? riderId : null);
                            },
                          );
                        }).toList(),
                      ],
                    ),
              if (!auth.isAuthenticated) ...[
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Phone for order updates',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (v) => setState(() => _guestPhone = v),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'card', child: Text('Card')),
                  DropdownMenuItem(value: 'wallet', child: Text('Mobile Money')),
                ],
                onChanged: (value) => setState(() => _paymentMethod = value ?? 'cash'),
                decoration: const InputDecoration(labelText: 'Payment method'),
              ),
              if (_paymentMethod == 'card') ...[
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: 'Card number'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() => _cardNumber = v),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
                  keyboardType: TextInputType.datetime,
                  onChanged: (v) => setState(() => _cardExpiry = v),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'CVV'),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  onChanged: (_) {},
                ),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          _buildTotalRow(cart.total),
          const SizedBox(height: 12),
          _loading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _placeOrder,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                  child: const Text('Place Order'),
                ),
        ]),
      ),
    );
  }
}
