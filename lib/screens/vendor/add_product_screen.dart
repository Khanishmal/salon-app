// lib/screens/vendor/add_product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class AddProductScreen extends StatefulWidget {
  final String vendorId;
  final String? productId; // For editing
  final Map<String, dynamic>? productData; // For editing

  const AddProductScreen({
    super.key,
    required this.vendorId,
    this.productId,
    this.productData,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  
  File? _imageFile;
  bool _isUploading = false;
  String? _imageUrl;
  bool _isEditing = false;
  
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.productId != null && widget.productData != null;
    if (_isEditing && widget.productData != null) {
      _nameController.text = widget.productData!['name'] ?? '';
      _priceController.text = widget.productData!['price']?.toString() ?? '';
      _descriptionController.text = widget.productData!['description'] ?? '';
      _categoryController.text = widget.productData!['category'] ?? '';
      _stockController.text = widget.productData!['stock']?.toString() ?? '';
      _brandController.text = widget.productData!['brand'] ?? '';
      _imageUrl = widget.productData!['imageUrl'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Request permission
    PermissionStatus status = await Permission.storage.request();
    if (status.isGranted) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _imageUrl = null; // Reset URL when new image is selected
        });
      }
    } else if (status.isDenied) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text('Please allow storage permission to upload product images.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _imageUrl;
    
    setState(() {
      _isUploading = true;
    });

    try {
      String fileName = 'products/${widget.vendorId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);
      
      UploadTask uploadTask = ref.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      setState(() {
        _imageUrl = downloadUrl;
        _isUploading = false;
      });
      
      return downloadUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      // Upload image first if selected
      String? imageUrl = _imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) return;
      }

      setState(() {
        _isUploading = true;
      });

      try {
        final Map<String, dynamic> productData = {
          'vendorId': widget.vendorId,
          'name': _nameController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'description': _descriptionController.text.trim(),
          'category': _categoryController.text.trim(),
          'stock': int.parse(_stockController.text.trim() == '' ? '0' : _stockController.text.trim()),
          'brand': _brandController.text.trim(),
          'imageUrl': imageUrl ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (_isEditing && widget.productId != null) {
          // Update existing product
          await _firestore.collection('products').doc(widget.productId).update(productData);
        } else {
          // Add new product
          productData['createdAt'] = FieldValue.serverTimestamp();
          productData['isActive'] = true;
          productData['salesCount'] = 0;
          await _firestore.collection('products').add(productData);
        }

        if (mounted) {
          setState(() {
            _isUploading = false;
          });
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Product' : 'Add New Product',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF2845C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Product Image Upload
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : (_imageUrl != null && _imageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null),
                  ),
                  child: (_imageFile == null && (_imageUrl == null || _imageUrl!.isEmpty))
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 50,
                              color: const Color(0xFFF2845C).withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload product image',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              if (_isUploading) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(
                  color: Color(0xFFF2845C),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Uploading image...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 20),

              // AI Price Guide (only for new products)
              if (!_isEditing)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDEEE9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFF2845C)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Price Guide',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Get AI recommendations for pricing',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _showAIPriceGuide,
                        child: const Text(
                          'Check',
                          style: TextStyle(color: Color(0xFFF2845C)),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'e.g., Matte Lipstick',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price (Rs)',
                  hintText: 'e.g., 1200',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Category
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g., Lipstick, Foundation',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Brand
              TextFormField(
                controller: _brandController,
                decoration: InputDecoration(
                  labelText: 'Brand',
                  hintText: 'e.g., Maybelline, L\'Oreal',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.branding_watermark),
                ),
              ),
              const SizedBox(height: 15),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter product details...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 15),

              // Stock
              TextFormField(
                controller: _stockController,
                decoration: InputDecoration(
                  labelText: 'Stock Quantity',
                  hintText: 'e.g., 50',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF2845C),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Product' : 'Add Product',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAIPriceGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Price Guide 🤖'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Based on market analysis:'),
            const SizedBox(height: 10),
            _buildAIPriceRow('Suggested Price', 'Rs. 1,200 - 1,500'),
            _buildAIPriceRow('Competitor Avg', 'Rs. 1,350'),
            _buildAIPriceRow('Demand Level', '🔥 High'),
            _buildAIPriceRow('Profit Margin', '35-40%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildAIPriceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Color(0xFFF2845C))),
        ],
      ),
    );
  }
}