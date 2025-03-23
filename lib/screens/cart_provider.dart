import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;

  void addToCart(Map<String, dynamic> item) { // Fixed syntax: removed extra '>'
    final existingItemIndex = _cartItems.indexWhere((cartItem) => cartItem['id'] == item['id']);
    if (existingItemIndex != -1) {
      _cartItems[existingItemIndex]['quantity'] += 1;
    } else {
      _cartItems.add({...item, 'quantity': 1});
    }
    print('Item added to cart. Cart items: $_cartItems');
    notifyListeners();
  }

  void updateQuantity(String id, int newQuantity) {
    final itemIndex = _cartItems.indexWhere((item) => item['id'] == id);
    if (itemIndex != -1) {
      if (newQuantity <= 0) {
        _cartItems.removeAt(itemIndex);
      } else {
        _cartItems[itemIndex]['quantity'] = newQuantity;
      }
      print('Quantity updated for item $id. Cart items: $_cartItems');
      notifyListeners();
    }
  }

  void removeFromCart(String id) {
    _cartItems.removeWhere((item) => item['id'] == id);
    print('Item $id removed from cart. Cart items: $_cartItems');
    notifyListeners();
  }

  void clearCart() {
    print('Clearing cart. Before: $_cartItems');
    _cartItems = [];
    print('Cart cleared. After: $_cartItems');
    notifyListeners();
  }
}