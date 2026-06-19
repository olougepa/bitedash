import 'package:flutter/material.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    final Map<String, dynamic> order = args is Map<String, dynamic> ? args : {};
    return Scaffold(
      appBar: AppBar(title: const Text('Order Confirmed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 96),
            const SizedBox(height: 16),
            const Text('Thank you! Your order has been placed.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Order: ${order['id'] ?? '—'}'),
            if (order['payment_stub'] != null) ...[
              const SizedBox(height: 8),
              Text('Payment details: ${order['payment_stub']}', textAlign: TextAlign.center),
            ],
            if (order['guest_token'] != null) ...[
              const SizedBox(height: 8),
              Text('Guest lookup code: ${order['guest_token']}', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Save this code to track your order later.', textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/delivery-tracking', arguments: order),
              child: const Text('Track delivery'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/')), child: const Text('Back to home')),
          ]),
        ),
      ),
    );
  }
}
