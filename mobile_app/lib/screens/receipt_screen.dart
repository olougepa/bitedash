import 'package:flutter/material.dart';

class ReceiptScreen extends StatelessWidget {
  final Map<String, dynamic>? order;
  const ReceiptScreen({this.order, super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final Map<String, dynamic> order = this.order ?? (args is Map<String, dynamic> ? args : {});
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt'), backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: const Icon(Icons.receipt_long, size: 80, color: Colors.deepOrange)),
          const SizedBox(height: 20),
          Text('Order #${order['id'] ?? '—'}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Divider(),
          const SizedBox(height: 12),
          if (order['items'] != null) ...[
            const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...(order['items'] as List<dynamic>).map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${item['quantity'] ?? 1}x ${item['name'] ?? 'Item'}'),
                Text('\$${((item['quantity'] ?? 1) * (double.tryParse('${item['unit_price'] ?? 0}') ?? 0)).toStringAsFixed(2)}'),
              ]),
            )),
            const Divider(),
          ],
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Subtotal:'),
            Text('\$${order['sub_total'] ?? '0.00'}'),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Delivery Fee:'),
            Text('\$${order['delivery_fee'] ?? '0.00'}'),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Tax:'),
            Text('\$${order['tax'] ?? '0.00'}'),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Discount:'),
            Text('- \$${order['discount'] ?? '0.00'}'),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('\$${order['total'] ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange)),
          ]),
          const SizedBox(height: 24),
          const Text('Payment: Cash on Delivery', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/')),
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
            ),
          ),
        ]),
      ),
    );
  }
}