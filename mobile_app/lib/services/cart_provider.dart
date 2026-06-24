import 'package:flutter/material.dart';

class CartItem {
  final int id;
  final String name;
  final double price;
  final int restaurantId;
  int quantity;

  CartItem({required this.id, required this.name, required this.price, required this.restaurantId, this.quantity = 1});
}

class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  int get itemCount => _items.length;

  void addItem(int id, String name, double price, {int? restaurantId}) {
    if (_items.containsKey(id)) {
      _items[id]!.quantity += 1;
    } else {
      _items[id] = CartItem(id: id, name: name, price: price, restaurantId: restaurantId ?? 1);
    }
    notifyListeners();
  }

  void removeItem(int id) {
    _items.remove(id);
    notifyListeners();
  }

  void updateQuantity(int id, int quantity) {
    if (_items.containsKey(id)) {
      _items[id]!.quantity = quantity;
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  double get total => _items.values.fold(0.0, (s, it) => s + it.price * it.quantity);
}
