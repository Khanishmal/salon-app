import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import '../../utils/product_image_helper.dart';

class ProductShopScreen extends StatefulWidget {
  const ProductShopScreen({super.key});

  @override
  State<ProductShopScreen> createState() => _ProductShopScreenState();
}

class _ProductShopScreenState extends State<ProductShopScreen> with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showGrid = true;
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: '🔥 Deals'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showGrid ? Icons.view_list : Icons.grid_view),
            color: Colors.white,
            onPressed: () {
              setState(() => _showGrid = !_showGrid);
            },
          ),
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
                  hintText: _showDealsOnly ? 'Search deals...' : 'Search products...',
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
          // Category Filter (only for products)
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
          // Products Grid/List
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
                        Icon(
                          _showDealsOnly ? Icons.local_offer : Icons.inventory_2_outlined,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showDealsOnly ? 'No Deals Available' : 'No Products Available',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _showDealsOnly 
                            ? 'Check back later for great deals'
                            : 'Check back later for new products',
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

                // Filter by deals/products
                if (_showDealsOnly) {
                  products = products.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return data['isDeal'] == true;
                  }).toList();
                } else {
                  products = products.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return data['isDeal'] != true;
                  }).toList();
                }

                // Filter by category (only for products)
                if (!_showDealsOnly && _selectedCategory != 'All') {
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
                          _showDealsOnly ? 'No deals found' : 'No products found',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _showGrid
                    ? _buildGridProducts(products)
                    : _buildListProducts(products);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridProducts(List<QueryDocumentSnapshot> products) {
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
  }

  Widget _buildListProducts(List<QueryDocumentSnapshot> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (context, index) {
        var doc = products[index];
        var data = doc.data() as Map<String, dynamic>;
        return _buildProductListItem(doc.id, data);
      },
    );
  }

  // FIXED: Reduced height and padding to prevent overflow
  Widget _buildProductCard(String productId, Map<String, dynamic> data) {
    String name = data['name'] ?? 'Product';
    double price = (data['price'] ?? 0).toDouble();
    int stock = data['stock'] ?? 0;
    String vendorId = data['vendorId'] ?? '';
    String category = data['category'] ?? 'Other';
    bool isDeal = data['isDeal'] ?? false;
    double? dealPrice = data['dealPrice'] as double?;
    double? discount = data['discount'] as double?;
    
    String imageUrl = ProductImageHelper.getProductImage(data);

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
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image - Reduced height
            Stack(
              children: [
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDEEE9),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
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
                            size: 30,
                            color: const Color(0xFFF2845C).withOpacity(0.5),
                          ),
                        )
                      : null,
                ),
                if (isDeal)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF4757)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'DEAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (category.isNotEmpty)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Product Details - Reduced padding
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF2D3A4B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (isDeal) ...[
                    Row(
                      children: [
                        Text(
                          'Rs. ${NumberFormat('#,###').format(dealPrice ?? price)}',
                          style: const TextStyle(
                            color: Color(0xFFF2845C),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Rs. ${NumberFormat('#,###').format(price)}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[400],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        if (discount != null && discount! > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '-${discount!.toInt()}%',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 7,
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
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        size: 9,
                        color: stock > 10 ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        stock > 0 ? '$stock' : 'Out',
                        style: TextStyle(
                          fontSize: 8,
                          color: stock > 10 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // FIXED: Smaller button to prevent overflow
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: stock > 0
                          ? () => _addToCart(productId, name, price, imageUrl, vendorId)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stock > 0 ? const Color(0xFFF2845C) : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        minimumSize: const Size(double.infinity, 24),
                      ),
                      child: Text(
                        stock > 0 ? 'Add to Cart' : 'Out of Stock',
                        style: const TextStyle(fontSize: 9),
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

  Widget _buildProductListItem(String productId, Map<String, dynamic> data) {
    String name = data['name'] ?? 'Product';
    double price = (data['price'] ?? 0).toDouble();
    int stock = data['stock'] ?? 0;
    String vendorId = data['vendorId'] ?? '';
    String category = data['category'] ?? 'Other';
    bool isDeal = data['isDeal'] ?? false;
    double? dealPrice = data['dealPrice'] as double?;
    double? discount = data['discount'] as double?;
    
    String imageUrl = ProductImageHelper.getProductImage(data);

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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDEEE9),
                    borderRadius: BorderRadius.circular(10),
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
                      ? const Icon(Icons.image, color: Color(0xFFF2845C))
                      : null,
                ),
                if (isDeal)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF4757)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DEAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF2D3A4B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (isDeal) ...[
                    Row(
                      children: [
                        Text(
                          'Rs. ${NumberFormat('#,###').format(dealPrice ?? price)}',
                          style: const TextStyle(
                            color: Color(0xFFF2845C),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Rs. ${NumberFormat('#,###').format(price)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        if (discount != null && discount! > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${discount!.toInt()}%',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 8,
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
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        size: 10,
                        color: stock > 10 ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stock > 0 ? '$stock in stock' : 'Out of stock',
                        style: TextStyle(
                          fontSize: 9,
                          color: stock > 10 ? Colors.green : Colors.orange,
                        ),
                      ),
                      if (category.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 7,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: stock > 0
                          ? () => _addToCart(productId, name, price, imageUrl, vendorId)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stock > 0 ? const Color(0xFFF2845C) : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        minimumSize: const Size(100, 24),
                      ),
                      child: Text(
                        stock > 0 ? 'Add to Cart' : 'Out of Stock',
                        style: const TextStyle(fontSize: 9),
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