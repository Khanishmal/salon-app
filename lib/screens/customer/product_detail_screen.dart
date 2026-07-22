import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'vendor_chat_screen.dart';
import 'cart_screen.dart';
import '../../utils/product_image_helper.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String vendorId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.vendorId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _quantity = 1;
  Map<String, dynamic>? _productData;
  Map<String, dynamic>? _vendorData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load product
      DocumentSnapshot productDoc = await _firestore
          .collection('products')
          .doc(widget.productId)
          .get();
      
      if (productDoc.exists) {
        _productData = productDoc.data() as Map<String, dynamic>;
      }

      // Load vendor
      DocumentSnapshot vendorDoc = await _firestore
          .collection('users')
          .doc(widget.vendorId)
          .get();
      
      if (vendorDoc.exists) {
        _vendorData = vendorDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addToCart() async {
    if (_productData == null) return;

    try {
      final cartRef = _firestore.collection('carts').doc(user?.uid);
      final doc = await cartRef.get();
      
      // Get proper image
      String imageUrl = ProductImageHelper.getProductImage(_productData!);
      
      final Map<String, dynamic> item = {
        'productId': widget.productId,
        'name': _productData!['name'],
        'price': _productData!['price'],
        'imageUrl': imageUrl,
        'vendorId': widget.vendorId,
        'quantity': _quantity,
        'isDeal': _productData!['isDeal'] ?? false,
        'dealPrice': _productData!['dealPrice'],
      };
      
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        List items = data['items'] ?? [];
        
        bool exists = false;
        for (var existingItem in items) {
          if (existingItem['productId'] == widget.productId) {
            exists = true;
            existingItem['quantity'] = (existingItem['quantity'] ?? 0) + _quantity;
            break;
          }
        }
        
        if (!exists) {
          items.add(item);
        }
        
        await cartRef.update({
          'items': items,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await cartRef.set({
          'userId': user?.uid,
          'items': [item],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_productData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Product Not Found'),
          backgroundColor: const Color(0xFFF2845C),
        ),
        body: const Center(child: Text('Product not found')),
      );
    }

    String name = _productData!['name'] ?? 'Product';
    double price = (_productData!['price'] ?? 0).toDouble();
    int stock = _productData!['stock'] ?? 0;
    String description = _productData!['description'] ?? '';
    String category = _productData!['category'] ?? 'Other';
    String brand = _productData!['brand'] ?? '';
    String vendorName = _vendorData?['businessName'] ?? _vendorData?['name'] ?? 'Vendor';
    String vendorId = widget.vendorId;
    double vendorRating = (_vendorData?['rating'] ?? 0).toDouble();
    bool isDeal = _productData!['isDeal'] ?? false;
    double? dealPrice = _productData!['dealPrice'] as double?;
    double? discount = _productData!['discount'] as double?;
    
    // Get proper image
    String imageUrl = ProductImageHelper.getProductImage(_productData!);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          name,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 300,
              width: double.infinity,
              color: const Color(0xFFFDEEE9),
              child: imageUrl.isNotEmpty
                  ? Image(
                      image: imageUrl.startsWith('http')
                          ? NetworkImage(imageUrl)
                          : AssetImage(imageUrl) as ImageProvider,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.image, size: 60, color: Colors.grey),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 60, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3A4B),
                          ),
                        ),
                      ),
                      if (isDeal) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rs. ${NumberFormat('#,###').format(dealPrice ?? price)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF2845C),
                              ),
                            ),
                            Text(
                              'Rs. ${NumberFormat('#,###').format(price)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            if (discount != null && discount! > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${discount!.toInt()}% OFF',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'Rs. ${NumberFormat('#,###').format(price)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF2845C),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Brand & Category
                  Wrap(
                    spacing: 8,
                    children: [
                      if (brand.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            brand,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                          ),
                        ),
                      if (category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: stock > 10 ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          stock > 10 ? 'In Stock' : 'Low Stock',
                          style: TextStyle(
                            color: stock > 10 ? Colors.green.shade700 : Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (isDeal)
                        Container(
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Vendor Info with Chat Button
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDEEE9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFF2845C),
                          child: Text(
                            vendorName.isNotEmpty ? vendorName[0].toUpperCase() : 'V',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vendorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3A4B),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    vendorRating.toStringAsFixed(1),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Chat with Vendor Button
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VendorChatScreen(
                                  vendorId: vendorId,
                                  vendorName: vendorName,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description (Optional)
                  if (description.isNotEmpty) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3A4B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Quantity Selector
                  Row(
                    children: [
                      const Text(
                        'Quantity:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3A4B),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                _quantity.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _quantity < stock
                                  ? () => setState(() => _quantity++)
                                  : null,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: stock > 0 ? _addToCart : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stock > 0 ? const Color(0xFFF2845C) : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        stock > 0 
                            ? 'Add to Cart - Rs. ${NumberFormat('#,###').format((isDeal ? (dealPrice ?? price) : price) * _quantity)}'
                            : 'Out of Stock',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
}