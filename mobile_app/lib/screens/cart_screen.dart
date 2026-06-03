import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              final it = cart.items[index];
              return ListTile(
                title: Text(it.name),
                subtitle: Text('Qty: ${it.quantity}'),
                trailing: Text('\$${(it.price * it.quantity).toStringAsFixed(2)}'),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total: \$${cart.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/checkout'), child: const Text('Checkout')),
          ]),
        ),
      ]),
    );
  }
}
