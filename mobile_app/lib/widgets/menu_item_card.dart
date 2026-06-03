import 'package:flutter/material.dart';

class MenuItemCard extends StatelessWidget {
  final String title;
  final String description;
  final double price;
  final bool available;
  final VoidCallback onTap;

  const MenuItemCard({
    required this.title,
    required this.description,
    required this.price,
    required this.available,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(title),
        subtitle: Text(description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('\$\$price'),
            Text(available ? 'Available' : 'Sold out', style: TextStyle(color: available ? Colors.green : Colors.red)),
          ],
        ),
        onTap: available ? onTap : null,
      ),
    );
  }
}
