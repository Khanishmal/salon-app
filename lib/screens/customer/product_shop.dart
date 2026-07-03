// lib/screens/customer/product_shop.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'vendor_chat_screen.dart';

class ProductShopScreen extends StatefulWidget {
  const ProductShopScreen({super.key});

  @override
  State<ProductShopScreen> createState() => _ProductShopScreenState();
}

class _ProductShopScreenState extends State<ProductShopScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedCategory = 'All';
  String _selectedVendor = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, String> _vendorMap = {};
  Map<String, dynamic> _vendorDataMap = {};

  final List<String> _categories = [
    'All',
    'Lipsticks',
    'Foundations',
    'Eyeliners',
    'Jewellery',
    'Hair Accessories',
    'Mehndi Templates',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Glow Store',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF2845C),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFF2845C)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
            ),
          ),
          // Category Filter
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFFFDEEE9),
                    checkmarkColor: const Color(0xFFF2845C),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFFF2845C) : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          // Content: Vendors or Products
          Expanded(
            child: _selectedVendor == 'All'
                ? _buildVendorList()
                : _buildProductsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: 'Vendor')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2845C)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading vendors',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2845C),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No Vendors Available',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for new vendors',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          );
        }

        // Show all vendors
        final vendors = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: vendors.length,
          itemBuilder: (context, index) {
            var doc = vendors[index];
            var data = doc.data() as Map<String, dynamic>;
            String vendorId = doc.id;
            String vendorName = data['businessName'] ?? data['name'] ?? 'Vendor';
            double rating = (data['rating'] ?? 0).toDouble();
            
            _vendorMap[vendorId] = vendorName;
            _vendorDataMap[vendorId] = data;

            return _buildVendorCard(
              vendorId: vendorId,
              name: vendorName,
              rating: rating,
              data: data,
            );
          },
        );
      },
    );
  }

  Widget _buildVendorCard({
    required String vendorId,
    required String name,
    required double rating,
    required Map<String, dynamic> data,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVendor = name;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFDEEE9),
                image: data['profileImage'] != null && data['profileImage'].toString().isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(data['profileImage']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: data['profileImage'] == null || data['profileImage'].toString().isEmpty
                  ? Icon(
                      Icons.storefront,
                      size: 40,
                      color: const Color(0xFFF2845C).withOpacity(0.6),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF2D3A4B),
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2845C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'View Products',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFF2845C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Chat with Vendor Button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VendorChatScreen(
                          vendorId: vendorId,
                          vendorName: name,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.blue[700],
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Chat',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    return Column(
      children: [
        // Header with back button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFF2845C)),
                onPressed: () {
                  setState(() {
                    _selectedVendor = 'All';
                  });
                },
              ),
              Expanded(
                child: Text(
                  'Products from $_selectedVendor',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3A4B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Color(0xFFF2845C)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('products')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2845C)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
                      const SizedBox(height: 8),
                      const Text('Error loading products'),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No Products Available',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This vendor has no products yet',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                );
              }

              var products = snapshot.data!.docs;

              // Filter by vendor
              String? vendorId;
              for (var entry in _vendorMap.entries) {
                if (entry.value == _selectedVendor) {
                  vendorId = entry.key;
                  break;
                }
              }

              if (vendorId != null) {
                products = products.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return data['vendorId'] == vendorId;
                }).toList();
              }

              // Filter by category
              if (_selectedCategory != 'All') {
                products = products.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String category = data['category'] ?? '';
                  return category.toLowerCase() == _selectedCategory.toLowerCase();
                }).toList();
              }

              // Filter by search
              if (_searchQuery.isNotEmpty) {
                products = products.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = (data['name'] ?? '').toString().toLowerCase();
                  String category = (data['category'] ?? '').toString().toLowerCase();
                  String brand = (data['brand'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || 
                         category.contains(_searchQuery) || 
                         brand.contains(_searchQuery);
                }).toList();
              }

              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No products found',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  var doc = products[index];
                  var data = doc.data() as Map<String, dynamic>;
                  return _buildProductCard(doc.id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(String productId, Map<String, dynamic> data) {
    String name = data['name'] ?? 'Product';
    double price = (data['price'] ?? 0).toDouble();
    int stock = data['stock'] ?? 0;
    String imageUrl = data['imageUrl'] ?? '';
    String vendorId = data['vendorId'] ?? '';
    String brand = data['brand'] ?? '';
    String category = data['category'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              productId: productId,
              vendorId: vendorId,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFDEEE9),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                image: imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl.isEmpty
                  ? Center(
                      child: Icon(
                        Icons.image,
                        size: 40,
                        color: const Color(0xFFF2845C).withOpacity(0.5),
                      ),
                    )
                  : null,
            ),
            // Product Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2D3A4B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Rs. ${NumberFormat('#,###').format(price)}',
                          style: const TextStyle(
                            color: Color(0xFFF2845C),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        size: 12,
                        color: stock > 10 ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stock > 0 ? '$stock in stock' : 'Out of stock',
                        style: TextStyle(
                          fontSize: 10,
                          color: stock > 10 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: stock > 0
                          ? () => _addToCart(productId, name, price, imageUrl, vendorId)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stock > 0 ? const Color(0xFFF2845C) : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        stock > 0 ? 'Add to Cart' : 'Out of Stock',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(String productId, String name, double price, String imageUrl, String vendorId) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to add items to cart'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final cartRef = _firestore.collection('carts').doc(user!.uid);
      final doc = await cartRef.get();
      
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        List items = data['items'] ?? [];
        
        bool exists = false;
        for (var item in items) {
          if (item['productId'] == productId) {
            exists = true;
            item['quantity'] = (item['quantity'] ?? 1) + 1;
            break;
          }
        }
        
        if (!exists) {
          items.add({
            'productId': productId,
            'name': name,
            'price': price,
            'imageUrl': imageUrl,
            'vendorId': vendorId,
            'quantity': 1,
          });
        }
        
        await cartRef.update({
          'items': items,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await cartRef.set({
          'userId': user!.uid,
          'items': [
            {
              'productId': productId,
              'name': name,
              'price': price,
              'imageUrl': imageUrl,
              'vendorId': vendorId,
              'quantity': 1,
            }
          ],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added to cart!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to cart: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}