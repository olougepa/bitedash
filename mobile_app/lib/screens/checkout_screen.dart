import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
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
  String _cardCvv = '';
  String _guestEmail = '';

  Future<void> _placeOrder() async {
    setState(() => _loading = true);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);
    final items = cart.items
        .map((e) => {'menu_item_id': e.id, 'quantity': e.quantity, 'unit_price': e.price})
        .toList();
    final payload = {
      'order_type': 'delivery',
      'items': items,
      'sub_total': cart.total,
      'delivery_fee': 0,
      'total': cart.total,
      'payment_method': _paymentMethod,
      'payment_stub': {
        'method': _paymentMethod,
        'card_number': _paymentMethod == 'card' && _cardNumber.length >= 4
            ? '**** **** **** ${_cardNumber.substring(_cardNumber.length - 4)}'
            : 'cash',
        'expiry': _paymentMethod == 'card' ? _cardExpiry : null,
      },
      if (!Provider.of<AuthProvider>(context, listen: false).isAuthenticated)
        'guest_email': _guestEmail,
    };
    try {
      final res = await api.submitOrder(payload);
      cart.clear();
      Navigator.pushReplacementNamed(context, '/order-confirmation', arguments: res);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order failed')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Expanded(child: ListView(children: cart.items.map((e) => ListTile(title: Text(e.name), trailing: Text('x${e.quantity}'))).toList())),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Payment stub', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                    DropdownMenuItem(value: 'wallet', child: Text('Mobile wallet')),
                  ],
                  onChanged: (value) => setState(() => _paymentMethod = value ?? 'cash'),
                  decoration: const InputDecoration(labelText: 'Payment method'),
                ),
                if (_paymentMethod == 'card') ...[
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Card number'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() => _cardNumber = value),
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'),
                    keyboardType: TextInputType.datetime,
                    onChanged: (value) => setState(() => _cardExpiry = value),
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'CVV'),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    onChanged: (value) => setState(() => _cardCvv = value),
                  ),
                ],
                if (!Provider.of<AuthProvider>(context, listen: false).isAuthenticated) ...[
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Email for order updates (optional)'),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) => setState(() => _guestEmail = value),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Payment stub preview', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(_paymentMethod == 'card'
                      ? 'Card ending ${_cardNumber.length >= 4 ? _cardNumber.substring(_cardNumber.length - 4) : '****'}'
                      : _paymentMethod == 'wallet'
                          ? 'Mobile wallet'
                          : 'Cash'),
                  subtitle: Text(_paymentMethod == 'card'
                      ? 'Expires ${_cardExpiry.isNotEmpty ? _cardExpiry : 'MM/YY'}'
                      : 'Payment method: ${_paymentMethod[0].toUpperCase()}${_paymentMethod.substring(1)}'),
                  trailing: Text('Total: \$${cart.total.toStringAsFixed(2)}'),
                ),
              ]),
            ),
          Text('Total: \$${cart.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _placeOrder, child: const Text('Place Order')),
        ]),
      ),
    );
  }
}
