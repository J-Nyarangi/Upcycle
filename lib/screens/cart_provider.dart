import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;

  void addToCart(Map<String, dynamic> item) {
    int existingIndex = _cartItems.indexWhere((element) => element['id'] == item['id']);
    if (existingIndex >= 0) {
      _cartItems[existingIndex]['quantity']++;
    } else {
      Map<String, dynamic> newItem = Map.from(item);
      newItem['quantity'] = 1;
      _cartItems.add(newItem);
    }
    notifyListeners();
  }

  void removeFromCart(String id) {
    _cartItems.removeWhere((item) => item['id'] == id);
    notifyListeners();
  }

  void updateQuantity(String id, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(id);
      return;
    }
    int index = _cartItems.indexWhere((item) => item['id'] == id);
    if (index >= 0) {
      _cartItems[index]['quantity'] = newQuantity;
    }
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}