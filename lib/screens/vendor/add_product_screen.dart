import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/product_image_helper.dart';

class AddProductScreen extends StatefulWidget {
  final String vendorId;
  final String? productId;
  final Map<String, dynamic>? productData;
  final bool isDeal;

  const AddProductScreen({
    super.key,
    required this.vendorId,
    this.productId,
    this.productData,
    this.isDeal = false,
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
  final _discountController = TextEditingController();
  final _dealPriceController = TextEditingController();
  
  File? _imageFile;
  bool _isUploading = false;
  String? _imageUrl;
  bool _isEditing = false;
  bool _isImagePicking = false;
  bool _isDeal = false;
  bool _useDefaultImage = true;
  String? _selectedCategory;
  
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // All categories including Makeup Deals
  final List<String> _categories = [
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
    'Makeup Deals',  // Added Makeup Deals category
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _isDeal = widget.isDeal;
    _isEditing = widget.productId != null && widget.productData != null;
    
    if (_isEditing && widget.productData != null) {
      _nameController.text = widget.productData!['name'] ?? '';
      _priceController.text = widget.productData!['price']?.toString() ?? '';
      _descriptionController.text = widget.productData!['description'] ?? '';
      _categoryController.text = widget.productData!['category'] ?? '';
      _stockController.text = widget.productData!['stock']?.toString() ?? '';
      _brandController.text = widget.productData!['brand'] ?? '';
      _discountController.text = widget.productData!['discount']?.toString() ?? '';
      _dealPriceController.text = widget.productData!['dealPrice']?.toString() ?? '';
      _imageUrl = widget.productData!['imageUrl'];
      _useDefaultImage = widget.productData!['useDefaultImage'] ?? true;
      _selectedCategory = widget.productData!['category'];
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
    _discountController.dispose();
    _dealPriceController.dispose();
    super.dispose();
  }

  Future<bool> _hasGalleryPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.photos.isGranted) {
        return true;
      }
      if (await Permission.storage.isGranted) {
        return true;
      }
      return false;
    } else {
      if (await Permission.photos.isGranted) {
        return true;
      }
      return false;
    }
  }

  Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.photos.request().isGranted) {
        return;
      }
      if (await Permission.storage.request().isGranted) {
        return;
      }
      if (await Permission.photos.isPermanentlyDenied || 
          await Permission.storage.isPermanentlyDenied) {
        _showPermissionDeniedDialog();
      }
    } else {
      if (await Permission.photos.request().isGranted) {
        return;
      }
      if (await Permission.photos.isPermanentlyDenied) {
        _showPermissionDeniedDialog();
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('Please allow gallery access to upload product images.'),
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

  Future<void> _pickImage() async {
    setState(() => _isImagePicking = true);

    try {
      bool hasPermission = await _hasGalleryPermission();
      
      if (!hasPermission) {
        await _requestPermission();
        hasPermission = await _hasGalleryPermission();
        if (!hasPermission) {
          setState(() => _isImagePicking = false);
          return;
        }
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _imageUrl = null;
          _useDefaultImage = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isImagePicking = false);
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
      
      UploadTask uploadTask = ref.putFile(
        _imageFile!,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'vendorId': widget.vendorId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      setState(() {
        _imageUrl = downloadUrl;
        _isUploading = false;
      });
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Storage Error: ${e.code} - ${e.message}');
      setState(() {
        _isUploading = false;
      });
      
      String errorMessage = 'Error uploading image: ';
      if (e.code == 'storage/object-not-found') {
        errorMessage += 'Storage path not found. Please check Firebase Storage rules.';
      } else if (e.code == 'storage/unauthorized') {
        errorMessage += 'You are not authorized to upload. Please check security rules.';
      } else if (e.code == 'storage/canceled') {
        errorMessage += 'Upload was canceled.';
      } else {
        errorMessage += e.message ?? 'Unknown error occurred.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return null;
    } catch (e) {
      print('Upload error: $e');
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  String _getDefaultImageForCategory(String category) {
    return ProductImageHelper.getImageForCategory(category);
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploading = true;
      });

      try {
        String? imageUrl = _imageUrl;
        
        if (_imageFile != null) {
          imageUrl = await _uploadImage();
          if (imageUrl == null) {
            setState(() => _isUploading = false);
            return;
          }
        }

        String category = _categoryController.text.trim();
        
        // If no custom image uploaded, use default category image
        if (imageUrl == null || imageUrl.isEmpty) {
          imageUrl = _getDefaultImageForCategory(category);
          _useDefaultImage = true;
        }

        final Map<String, dynamic> productData = {
          'vendorId': widget.vendorId,
          'name': _nameController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'description': _descriptionController.text.trim(),
          'category': category,
          'stock': int.parse(_stockController.text.trim().isEmpty ? '0' : _stockController.text.trim()),
          'brand': _brandController.text.trim(),
          'imageUrl': imageUrl,
          'useDefaultImage': _useDefaultImage,
          'isDeal': _isDeal || category == 'Makeup Deals', // Auto-mark as deal if category is Makeup Deals
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add deal-specific fields if it's a deal
        if (_isDeal || category == 'Makeup Deals') {
          productData['discount'] = double.tryParse(_discountController.text.trim()) ?? 0.0;
          productData['dealPrice'] = double.tryParse(_dealPriceController.text.trim()) ?? 
              double.parse(_priceController.text.trim());
          productData['originalPrice'] = double.parse(_priceController.text.trim());
        }

        if (_isEditing && widget.productId != null) {
          await _firestore.collection('products').doc(widget.productId).update(productData);
        } else {
          productData['createdAt'] = FieldValue.serverTimestamp();
          productData['isActive'] = true;
          productData['salesCount'] = 0;
          productData['rating'] = 0.0;
          productData['reviewCount'] = 0;
          await _firestore.collection('products').add(productData);
        }

        if (mounted) {
          setState(() {
            _isUploading = false;
          });
          Navigator.pop(context, true);
        }
      } catch (e) {
        print('Save error: $e');
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if selected category is Makeup Deals
    bool isDealCategory = _categoryController.text.trim() == 'Makeup Deals';
    bool showDealFields = _isDeal || isDealCategory;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing 
            ? (showDealFields ? 'Edit Deal' : 'Edit Product')
            : (showDealFields ? 'Add New Deal' : 'Add New Product'),
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
                onTap: _isImagePicking || _isUploading ? null : _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _imageFile != null || (_imageUrl != null && _imageUrl!.isNotEmpty)
                          ? const Color(0xFFF2845C)
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : (_imageUrl != null && _imageUrl!.isNotEmpty && !_useDefaultImage
                            ? DecorationImage(
                                image: NetworkImage(_imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null),
                  ),
                  child: (_imageFile == null && (_imageUrl == null || _imageUrl!.isEmpty || _useDefaultImage))
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isImagePicking
                                ? const SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2845C)),
                                    ),
                                  )
                                : Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 50,
                                    color: const Color(0xFFF2845C).withOpacity(0.5),
                                  ),
                            const SizedBox(height: 8),
                            Text(
                              _isImagePicking ? 'Loading gallery...' : 'Tap to upload product image',
                              style: TextStyle(
                                color: _isImagePicking ? const Color(0xFFF2845C) : Colors.grey.shade600,
                              ),
                            ),
                            if (_useDefaultImage && _imageUrl != null && _imageUrl!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Using default category image',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Stack(
                          children: [
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                                      onPressed: _pickImage,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                      onPressed: () {
                                        setState(() {
                                          _imageFile = null;
                                          _imageUrl = null;
                                          _useDefaultImage = true;
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: showDealFields ? 'Deal Name *' : 'Product Name *',
                  hintText: showDealFields ? 'e.g., Summer Makeup Kit' : 'e.g., Matte Lipstick',
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
                  labelText: showDealFields ? 'Original Price (Rs) *' : 'Price (Rs) *',
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

              // Deal-specific fields (shown when isDeal is true OR category is Makeup Deals)
              if (showDealFields) ...[
                TextFormField(
                  controller: _discountController,
                  decoration: InputDecoration(
                    labelText: 'Discount (%)',
                    hintText: 'e.g., 20',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.local_offer),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _dealPriceController,
                  decoration: InputDecoration(
                    labelText: 'Deal Price (Rs) *',
                    hintText: 'e.g., 960',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter deal price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
              ],

              // Category Dropdown - Now includes Makeup Deals
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  hintText: 'Select category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Row(
                      children: [
                        Image.asset(
                          ProductImageHelper.getImageForCategory(category),
                          height: 24,
                          width: 24,
                          errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.image, size: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(category),
                        if (category == 'Makeup Deals')
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _categoryController.text = value ?? '';
                    // Auto-assign default image when category changes
                    if (_useDefaultImage && value != null) {
                      _imageUrl = _getDefaultImageForCategory(value);
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
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

              // Description (Optional)
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter product details...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                  helperText: 'Provide additional details about the product',
                  helperStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                          _isEditing 
                            ? (showDealFields ? 'Update Deal' : 'Update Product')
                            : (showDealFields ? 'Add Deal' : 'Add Product'),
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
}