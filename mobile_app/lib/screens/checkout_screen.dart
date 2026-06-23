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
  List<dynamic> _riders = [];
  int? _selectedRiderId;

  Future<void> _loadRiders() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final riders = await api.fetchNearbyRiders(37.7749, -122.4194);
    setState(() => _riders = riders);
  }

  Future<void> _placeOrder() async {
    setState(() => _loading = true);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final items = cart.items
        .map((e) => {'menu_item_id': e.id, 'quantity': e.quantity, 'unit_price': e.price})
        .toList();
    final payload = {
      'order_type': 'delivery',
      'restaurant_id': cart.items.isNotEmpty ? cart.items.first.restaurantId : 1,
      'items': items,
      'sub_total': cart.total,
      'delivery_fee': 2.99,
      'total': cart.total + 2.99,
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
        child: Column(children: [
          Expanded(
            child: ListView(children: [
              ...cart.items.map((e) => ListTile(title: Text(e.name), trailing: Text('x${e.quantity}'))),
              const SizedBox(height: 16),
              const Text('Rider Selection', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _riders.isEmpty
                  ? const Text('No riders available')
                  : Wrap(
                      spacing: 8,
                      children: _riders.map<Widget>((r) {
                        final riderId = int.tryParse('${r['id']}') ?? 0;
                        final rating = double.tryParse('${r['rating'] ?? 0}') ?? 0.0;
                        return ChoiceChip(
                          label: Text('Rider $riderId (${rating.toStringAsFixed(1)}★)'),
                          selected: _selectedRiderId == riderId,
                          onSelected: (_) => setState(() => _selectedRiderId = riderId),
                        );
                      }).toList(),
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
          Text('Total: \$${cart.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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