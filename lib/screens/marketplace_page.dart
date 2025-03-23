import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'marketplace_screen.dart';
import 'cart_provider.dart';
import 'product_details_screen.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({Key? key}) : super(key: key);

  @override
  _MarketplacePageState createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> listings = [];
  List<Map<String, dynamic>> featuredListings = [];
  bool isLoading = true;
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    fetchProjects();
    fetchFeaturedProjects();
  }

  void fetchProjects({String filter = 'all'}) async {
    setState(() {
      isLoading = true;
    });

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('marketplace_listings');

      switch (filter) {
        case 'popular':
          query = query.orderBy('purchases', descending: true).limit(10);
          break;
        case 'new':
          query = query.orderBy('createdAt', descending: true).limit(10);
          break;
        case 'sale':
          query = query.where('isOnSale', isEqualTo: true);
          break;
        case 'all':
        default:
          break;
      }

      final querySnapshot = await query.get();
      setState(() {
        listings = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'],
            'price': data['price'],
            'originalPrice': data['originalPrice'] ?? data['price'],
            'isOnSale': data['isOnSale'] ?? false,
            'image': data['image'],
            'description': data['description'],
            'quantity': data['quantity'],
            'createdAt': data['createdAt']?.toDate(),
            'purchases': data['purchases'] ?? 0,
          };
        }).toList();
        isLoading = false;
        selectedFilter = filter;
      });
    } catch (e) {
      print('Error fetching projects: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load projects: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void fetchFeaturedProjects() async {
    try {
      final querySnapshot = await _firestore
          .collection('marketplace_listings')
          .where('isFeatured', isEqualTo: true)
          .limit(3)
          .get();
      setState(() {
        featuredListings = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'],
            'price': data['price'],
            'originalPrice': data['originalPrice'] ?? data['price'],
            'isOnSale': data['isOnSale'] ?? false,
            'image': data['image'],
            'description': data['description'],
            'quantity': data['quantity'],
            'createdAt': data['createdAt']?.toDate(),
            'purchases': data['purchases'] ?? 0,
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching featured projects: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Marketplace',
          style: TextStyle(
            color: Colors.green[900],
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.green[800], size: 28),
            onPressed: () {
              Navigator.pushNamed(context, '/upload_project').then((_) {
                fetchProjects(filter: selectedFilter);
                fetchFeaturedProjects();
              });
            },
            tooltip: 'Add Product',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined, color: Colors.green[800], size: 28),
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
              ),
              if (cartProvider.cartItems.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cartProvider.cartItems.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFilterButton('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Popular', 'popular'),
                  const SizedBox(width: 8),
                  _buildFilterButton('New', 'new'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Sale', 'sale'),
                ],
              ),
            ),
          ),
          // Listings
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : listings.isEmpty
                    ? Center(child: Text('No $selectedFilter items available'))
                    : MarketplaceScreen(
                        listings: listings,
                        onShowProductDetails: (item) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsScreen(item: item),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildFilterButton(String label, String filter) {
    return ElevatedButton(
      onPressed: () => fetchProjects(filter: filter),
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedFilter == filter ? Colors.green[800] : Colors.grey[300],
        foregroundColor: selectedFilter == filter ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green[800],
          unselectedItemColor: Colors.grey[600],
          currentIndex: 2,
          selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 28),
              activeIcon: Icon(Icons.home_filled, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined, size: 28),
              activeIcon: Icon(Icons.camera_alt, size: 28),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined, size: 28),
              activeIcon: Icon(Icons.shopping_bag, size: 28),
              label: 'Market',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined, size: 28),
              activeIcon: Icon(Icons.menu_book, size: 28),
              label: 'Learn',
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (Route<dynamic> route) => false,
                );
                break;
              case 1:
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/capture_item',
                  (Route<dynamic> route) => false,
                );
                break;
              case 2:
                break;
              case 3:
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/learning',
                  (Route<dynamic> route) => false,
                );
                break;
            }
          },
        ),
      ),
    );
  }
}