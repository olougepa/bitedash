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
              return Dismissible(
                key: Key('cart-item-${it.id}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => cart.removeItem(it.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  title: Text(it.name),
                  subtitle: Text('Qty: ${it.quantity}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('\$${(it.price * it.quantity).toStringAsFixed(2)}'),
                    IconButton(icon: const Icon(Icons.remove, color: Colors.orange), onPressed: () {
                      if (it.quantity > 1) {
                        cart.updateQuantity(it.id, it.quantity - 1);
                      } else {
                        cart.removeItem(it.id);
                      }
                    }),
                    IconButton(icon: const Icon(Icons.add, color: Colors.green), onPressed: () {
                      cart.updateQuantity(it.id, it.quantity + 1);
                    }),
                  ]),
                ),
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