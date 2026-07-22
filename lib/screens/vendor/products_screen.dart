import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import '../../utils/product_image_helper.dart';

class VendorProductsScreen extends StatefulWidget {
  const VendorProductsScreen({super.key});

  @override
  State<VendorProductsScreen> createState() => _VendorProductsScreenState();
}

class _VendorProductsScreenState extends State<VendorProductsScreen> with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  bool _showDealsOnly = false;

  final List<String> _categories = [
    'All',
    'Lipsticks',
    'Foundations',
    'Eyeliners',
    'Eyeshadow',
    'Blush',
    'Bronzer',
    'Highlighter',
    'Eyebrow',
    'Jewellery',
    'Hair Accessories',
    'Mehndi Templates',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _showDealsOnly = _tabController.index == 1;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Products',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Makeup Deals'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _addProduct(isDeal: _showDealsOnly),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _showDealsOnly ? 'Search deals...' : 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          // Category Filter - Horizontal Scroll (only show for products, not deals)
          if (!_showDealsOnly)
            Container(
              height: 45,
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
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (category != 'All')
                            Image.asset(
                              ProductImageHelper.getImageForCategory(category),
                              height: 16,
                              width: 16,
                              errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.image, size: 16),
                            ),
                          if (category != 'All') const SizedBox(width: 4),
                          Text(category),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.grey.shade100,
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
          // Products/Deals Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('products')
                  .where('vendorId', isEqualTo: user?.uid)
                  .orderBy('createdAt', descending: true)
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
                          'Error loading items',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
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
                        Icon(
                          _showDealsOnly ? Icons.local_offer : Icons.inventory_2_outlined,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showDealsOnly ? 'No Deals Yet' : 'No Products Yet',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _showDealsOnly 
                            ? 'Tap the + button to add your first deal'
                            : 'Tap the + button to add your first product',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var items = snapshot.data!.docs;

                // Filter by deals/products
                if (_showDealsOnly) {
                  items = items.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return data['isDeal'] == true;
                  }).toList();
                } else {
                  items = items.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return data['isDeal'] != true;
                  }).toList();
                }

                // Filter by category (only for products)
                if (!_showDealsOnly && _selectedCategory != 'All') {
                  items = items.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String productCategory = data['category'] ?? '';
                    return productCategory.toLowerCase() == _selectedCategory.toLowerCase();
                  }).toList();
                }

                // Filter by search
                if (_searchQuery.isNotEmpty) {
                  items = items.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String name = (data['name'] ?? '').toString().toLowerCase();
                    String category = (data['category'] ?? '').toString().toLowerCase();
                    String brand = (data['brand'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) || 
                           category.contains(_searchQuery) || 
                           brand.contains(_searchQuery);
                  }).toList();
                }

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          _showDealsOnly ? 'No deals found' : 'No products found',
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
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var doc = items[index];
                    var data = doc.data() as Map<String, dynamic>;
                    return _buildProductCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addProduct(isDeal: _showDealsOnly),
        backgroundColor: const Color(0xFFF2845C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductCard(String productId, Map<String, dynamic> data) {
    String name = data['name'] ?? 'Product';
    double price = (data['price'] ?? 0).toDouble();
    int stock = data['stock'] ?? 0;
    String imageUrl = data['imageUrl'] ?? '';
    bool isActive = data['isActive'] ?? true;
    String category = data['category'] ?? '';
    bool isDeal = data['isDeal'] ?? false;
    double? dealPrice = data['dealPrice'] as double?;
    double? discount = data['discount'] as double?;

    // Use default image if no custom image
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      imageUrl = ProductImageHelper.getImageForCategory(category);
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditProductScreen(
              productId: productId,
              vendorId: user?.uid ?? '',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
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
            // Image
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDEEE9),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    image: imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: imageUrl.startsWith('http')
                                ? NetworkImage(imageUrl)
                                : AssetImage(imageUrl) as ImageProvider,
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
                // Deal badge
                if (isDeal)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF4757)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_offer, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'DEAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!isActive)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (category.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12),
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
                  if (isDeal) ...[
                    Row(
                      children: [
                        Text(
                          'Rs. ${NumberFormat('#,###').format(dealPrice ?? price)}',
                          style: const TextStyle(
                            color: Color(0xFFF2845C),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rs. ${NumberFormat('#,###').format(price)}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        if (discount != null && discount! > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${discount!.toInt()}%',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Rs. ${NumberFormat('#,###').format(price)}',
                      style: const TextStyle(
                        color: Color(0xFFF2845C),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        size: 14,
                        color: stock > 10 ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$stock in stock',
                        style: TextStyle(
                          fontSize: 12,
                          color: stock > 10 ? Colors.green : Colors.orange,
                        ),
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
  }

  void _addProduct({bool isDeal = false}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(
          vendorId: user?.uid ?? '',
          isDeal: isDeal,
        ),
      ),
    );
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDeal ? 'Deal added successfully!' : 'Product added successfully!',
          ),
          backgroundColor: const Color(0xFFF2845C),
        ),
      );
    }
  }
}