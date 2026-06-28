// lib/screens/vendor/edit_product_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_product_screen.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;
  final String vendorId;

  const EditProductScreen({
    super.key,
    required this.productId,
    required this.vendorId,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _productData;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('products')
          .doc(widget.productId)
          .get();
      
      if (doc.exists) {
        setState(() {
          _productData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading product: $e')),
      );
    }
  }

  Future<void> _toggleProductStatus() async {
    if (_productData == null) return;
    
    try {
      bool currentStatus = _productData!['isActive'] ?? true;
      await _firestore.collection('products').doc(widget.productId).update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      setState(() {
        _productData!['isActive'] = !currentStatus;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentStatus ? 'Product activated' : 'Product deactivated',
          ),
          backgroundColor: !currentStatus ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating product: $e')),
      );
    }
  }

  Future<void> _deleteProduct() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${_productData?['name'] ?? 'this product'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestore.collection('products').doc(widget.productId).delete();
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Close screen with success
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting product: $e')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
        body: const Center(
          child: Text('Product not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Product',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
        actions: [
          IconButton(
            icon: Icon(
              _productData!['isActive'] == true ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
            onPressed: _toggleProductStatus,
            tooltip: _productData!['isActive'] == true ? 'Deactivate' : 'Activate',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteProduct,
          ),
        ],
      ),
      body: AddProductScreen(
        vendorId: widget.vendorId,
        productId: widget.productId,
        productData: _productData,
      ),
    );
  }
}