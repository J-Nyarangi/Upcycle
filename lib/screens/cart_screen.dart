import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'cart_provider.dart';
import 'orders_screen.dart';
import 'package:upcycle/services/mpesa_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  double getCartTotal(List<Map<String, dynamic>> cartItems) {
    return cartItems.fold(0, (total, item) => total + (item['price'] * item['quantity']));
  }

  void proceedToCheckout(BuildContext context) {
    // Show informational dialog before proceeding to the checkout sheet
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Checkout Information',
          style: TextStyle(
            color: Colors.green[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'You will be prompted to enter your M-Pesa phone number to complete the payment. Ensure you have sufficient funds in your M-Pesa account.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: Text(
              'CANCEL',
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              // Proceed to the checkout sheet
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                builder: (context) => _buildCheckoutSheet(context),
              );
            },
            child: Text(
              'CONTINUE',
              style: TextStyle(color: Colors.green[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSheet(BuildContext context) {
    final TextEditingController phoneController = TextEditingController();
    bool isProcessing = false;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checkout with M-Pesa',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.phone, color: Colors.green[800]),
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        '+254 ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    hintText: 'e.g., 712345678',
                    labelText: 'M-Pesa Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    errorText: _validatePhoneNumber(phoneController.text),
                  ),
                  enabled: !isProcessing,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          final phone = "254${phoneController.text.trim()}";
                          if (_validatePhoneNumber(phoneController.text) != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter a valid 9-digit phone number (e.g., 712345678)')),
                            );
                            return;
                          }

                          setModalState(() {
                            isProcessing = true;
                          });

                          final cartProvider = Provider.of<CartProvider>(context, listen: false);
                          final total = getCartTotal(cartProvider.cartItems);

                          // Initiate M-Pesa payment
                          final result = await MpesaService.initiateStkPush(
                            phoneNumber: phone,
                            amount: total,
                          );

                          setModalState(() {
                            isProcessing = false;
                          });

                          Navigator.pop(context);

                          if (result != null && result['ResponseCode'] == '0') {
                            // Show the M-Pesa payment dialog
                            _showMpesaPaymentDialog(context, phone, result['CheckoutRequestID'], cartProvider);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Payment initiation failed: ${result?['CustomerMessage'] ?? 'Unknown error'}',
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'PAY WITH M-PESA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _validatePhoneNumber(String value) {
    if (value.length != 9) {
      return 'Enter a valid 9-digit phone number (e.g., 712345678)';
    }
    return null;
  }

  void _showMpesaPaymentDialog(BuildContext context, String phoneNumber, String transactionId, CartProvider cartProvider) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Icon(
            Icons.phone_android,
            color: Colors.green[800],
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'M-Pesa Payment Initiated',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.green[900],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        'An M-Pesa payment request (Transaction ID: $transactionId) has been sent to $phoneNumber. Please enter your PIN on your phone to complete the transaction.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () async {
            print('Payment Completed pressed');
            final user = FirebaseAuth.instance.currentUser;

            if (user == null) {
              print('No user logged in!');
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please log in to complete the order')),
                );
                Navigator.of(dialogContext).pop();
              }
              return;
            }

            try {
              if (cartProvider.cartItems.isEmpty) {
                throw Exception("Cart is empty. Cannot place an order.");
              }

              // Save the order to Firestore
              final orderRef = await FirebaseFirestore.instance.collection('orders').add({
                'userId': user.uid,
                'items': cartProvider.cartItems,
                'total': getCartTotal(cartProvider.cartItems),
                'phoneNumber': phoneNumber,
                'timestamp': FieldValue.serverTimestamp(),
                'status': 'placed',
              });

              print('Order saved successfully with ID: ${orderRef.id} for user: ${user.uid}');

              // Clear the cart
              cartProvider.clearCart();
              print('Cart cleared successfully');

              // Close the dialog first
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }

              // Ensure navigation only happens if context is still valid
              if (!context.mounted) {
                print('Context is not mounted, cannot navigate to OrdersScreen');
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrdersScreen()),
              );
              print('Navigation to OrdersScreen successful');
            } catch (e) {
              print('Error: $e');
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Failed to save order: $e')),
                );
                Navigator.of(dialogContext).pop(); // Close dialog on error
              }
            }
          },
          child: Text(
            'PAYMENT COMPLETED',
            style: TextStyle(color: Colors.green[800]),
          ),
        ),
      ],
    ),
  );
}


  @override
Widget build(BuildContext context) {
  final cartProvider = Provider.of<CartProvider>(context);
  final cartItems = cartProvider.cartItems;

  print('Cart items in build: $cartItems'); // Debug: Log cart items on build

  return Scaffold(
    backgroundColor: Colors.grey[50],
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.green[800]),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Your Cart',
        style: TextStyle(
          color: Colors.green[900],
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.history, color: Colors.green[800]), // Icon for orders (e.g., history icon)
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OrdersScreen()),
            );
          },
          tooltip: 'View Orders', // Accessibility hint
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your cart is empty',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text(
                          'Continue Shopping',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(item['image']),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\Shs${item['price'].toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () =>
                                                  cartProvider.updateQuantity(item['id'], item['quantity'] - 1),
                                              child: const Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Icon(Icons.remove, size: 16),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text(
                                                '${item['quantity']}',
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () =>
                                                  cartProvider.updateQuantity(item['id'], item['quantity'] + 1),
                                              child: const Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Icon(Icons.add, size: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                                        onPressed: () => cartProvider.removeFromCart(item['id']),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (cartItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\Shs${getCartTotal(cartItems).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => proceedToCheckout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'CHECKOUT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Back to Marketplace',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
}