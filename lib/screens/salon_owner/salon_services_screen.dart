// lib/screens/salon_owner/salon_services_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class SalonServicesScreen extends StatefulWidget {
  const SalonServicesScreen({super.key});

  @override
  State<SalonServicesScreen> createState() => _SalonServicesScreenState();
}

class _SalonServicesScreenState extends State<SalonServicesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color get _accentColor => const Color(0xFFE28766);
  Color get _primaryTextColor => Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1A1A1A);
  Color get _secondaryTextColor => Theme.of(context).brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _cardColor => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _borderColor => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D2D2D) : const Color(0xFFEAE6DF);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDarkMode
              ? [
                  const Color(0xFF0D0D0D),
                  const Color(0xFF1A0A0A),
                ]
              : [
                  const Color(0xFFFAF9F6),
                  const Color(0xFFFFF5F0),
                ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF222222) : const Color(0xFFF0EFFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  width: 0.5,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 13, color: _primaryTextColor),
                decoration: InputDecoration(
                  hintText: "Search services...",
                  hintStyle: TextStyle(color: _secondaryTextColor, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: _accentColor, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: _secondaryTextColor, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
            ),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Services',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.w800,
                          color: _primaryTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Manage your service offerings',
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: isMobile ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddServiceDialog(context),
                  icon: Icon(Icons.add, size: isMobile ? 14 : 16),
                  label: Text(isMobile ? '' : 'Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 14,
                      vertical: isMobile ? 10 : 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    minimumSize: isMobile ? const Size(40, 40) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('services')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE28766)),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 40, color: Colors.red[300]),
                          const SizedBox(height: 10),
                          Text(
                            'Error loading services',
                            style: TextStyle(color: _secondaryTextColor),
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
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.spa,
                              size: 50,
                              color: _accentColor.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Services Available',
                            style: TextStyle(
                              color: _primaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap "Add" to create your first service',
                            style: TextStyle(
                              color: _secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  var services = snapshot.data!.docs;

                  if (_searchQuery.isNotEmpty) {
                    services = services.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String name = (data['name'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery);
                    }).toList();
                  }

                  if (services.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 40, color: _secondaryTextColor),
                          const SizedBox(height: 8),
                          Text(
                            'No services found',
                            style: TextStyle(color: _secondaryTextColor),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : 3,
                      crossAxisSpacing: isMobile ? 8 : 12,
                      mainAxisSpacing: isMobile ? 8 : 12,
                      childAspectRatio: isMobile ? 0.85 : 0.75,
                    ),
                    itemCount: services.length,
                    padding: EdgeInsets.only(bottom: isMobile ? 8 : 16),
                    itemBuilder: (context, index) {
                      var doc = services[index];
                      var data = doc.data() as Map<String, dynamic>;
                      return _buildServiceCard(doc.id, data, isDarkMode, isMobile);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(String serviceId, Map<String, dynamic> data, bool isDarkMode, bool isMobile) {
    final isActive = data['isActive'] ?? true;
    final name = data['name'] ?? 'Service';
    final price = data['price'] ?? 0;
    final duration = data['duration'] ?? 0;
    final bookings = data['totalBookings'] ?? 0;
    final imageUrl = data['imageUrl'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? _borderColor.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: _buildServiceImage(imageUrl, isDarkMode),
                  ),
                ),
                if (!isActive)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'INACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primaryTextColor,
                          fontSize: isMobile ? 12 : 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: isMobile ? 10 : 12,
                            color: _secondaryTextColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${duration}m',
                            style: TextStyle(
                              color: _secondaryTextColor,
                              fontSize: isMobile ? 10 : 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.people_outline,
                            size: isMobile ? 10 : 12,
                            color: _secondaryTextColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$bookings',
                            style: TextStyle(
                              color: _secondaryTextColor,
                              fontSize: isMobile ? 10 : 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs.$price',
                        style: TextStyle(
                          color: _accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: isMobile ? 28 : 32,
                            height: isMobile ? 28 : 32,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _firestore
                                      .collection('services')
                                      .doc(serviceId)
                                      .update({'isActive': !isActive});
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: Icon(
                                    isActive ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.white,
                                    size: isMobile ? 16 : 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: isMobile ? 28 : 32,
                            height: isMobile ? 28 : 32,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showEditServiceDialog(context, serviceId, data),
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: isMobile ? 16 : 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: isMobile ? 28 : 32,
                            height: isMobile ? 28 : 32,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _confirmDeleteService(serviceId),
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: isMobile ? 16 : 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceImage(String? imageUrl, bool isDarkMode) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('data:image')) {
        try {
          final base64String = imageUrl.split(',').last;
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: _accentColor.withOpacity(0.08),
                child: Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 30,
                    color: _accentColor.withOpacity(0.3),
                  ),
                ),
              );
            },
          );
        } catch (e) {
          return _buildPlaceholderImage();
        }
      } else if (imageUrl.startsWith('http')) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: _accentColor.withOpacity(0.08),
              child: Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 30,
                  color: _accentColor.withOpacity(0.3),
                ),
              ),
            );
          },
        );
      } else {
        return Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: _accentColor.withOpacity(0.08),
              child: Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 30,
                  color: _accentColor.withOpacity(0.3),
                ),
              ),
            );
          },
        );
      }
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: _accentColor.withOpacity(0.08),
      child: Center(
        child: Icon(
          Icons.spa,
          size: 40,
          color: _accentColor.withOpacity(0.3),
        ),
      ),
    );
  }

  // FIXED: Complete _showAddServiceDialog with proper constraints
  void _showAddServiceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    final categoryController = TextEditingController();
    File? imageFile;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final isMobile = MediaQuery.of(context).size.width < 600;
          
          return AlertDialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            // FIXED: Add constraints to prevent overflow
            constraints: BoxConstraints(
              maxWidth: isMobile ? 340 : 420,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            title: Row(
              children: [
                Icon(Icons.add, color: _accentColor),
                const SizedBox(width: 8),
                const Text('Add Service'),
              ],
            ),
            content: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: isUploading ? null : () async {
                      final ImageSource? source = await showModalBottomSheet<ImageSource>(
                        context: context,
                        backgroundColor: _cardColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Select Image Source',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildImageSourceOption(
                                    context,
                                    Icons.photo_library,
                                    'Gallery',
                                    ImageSource.gallery,
                                    (source) {
                                      Navigator.pop(context, source);
                                    },
                                  ),
                                  _buildImageSourceOption(
                                    context,
                                    Icons.camera_alt,
                                    'Camera',
                                    ImageSource.camera,
                                    (source) {
                                      Navigator.pop(context, source);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (source != null) {
                        try {
                          final XFile? pickedFile = await _imagePicker.pickImage(
                            source: source,
                            maxWidth: 500,
                            maxHeight: 500,
                            imageQuality: 70,
                          );
                          if (pickedFile != null) {
                            setState(() {
                              imageFile = File(pickedFile.path);
                            });
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error picking image: $e')),
                          );
                        }
                      }
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF222222) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _borderColor,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                imageFile!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 100,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.broken_image, size: 40),
                                  );
                                },
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 40,
                                  color: _secondaryTextColor,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to add image (optional)',
                                  style: TextStyle(
                                    color: _secondaryTextColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: _primaryTextColor),
                    decoration: InputDecoration(
                      labelText: 'Service Name *',
                      hintText: 'e.g., Hair Styling',
                      labelStyle: TextStyle(color: _secondaryTextColor),
                      hintStyle: TextStyle(color: _secondaryTextColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _borderColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _accentColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    style: TextStyle(color: _primaryTextColor),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the service',
                      labelStyle: TextStyle(color: _secondaryTextColor),
                      hintStyle: TextStyle(color: _secondaryTextColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _borderColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _accentColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          style: TextStyle(color: _primaryTextColor),
                          decoration: InputDecoration(
                            labelText: 'Price *',
                            hintText: 'e.g., 1500',
                            prefixText: 'Rs. ',
                            labelStyle: TextStyle(color: _secondaryTextColor),
                            hintStyle: TextStyle(color: _secondaryTextColor),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _borderColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _accentColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: durationController,
                          style: TextStyle(color: _primaryTextColor),
                          decoration: InputDecoration(
                            labelText: 'Duration (min) *',
                            hintText: 'e.g., 45',
                            labelStyle: TextStyle(color: _secondaryTextColor),
                            hintStyle: TextStyle(color: _secondaryTextColor),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _borderColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _accentColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: categoryController,
                    style: TextStyle(color: _primaryTextColor),
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      hintText: 'e.g., Hair, Makeup',
                      labelStyle: TextStyle(color: _secondaryTextColor),
                      hintStyle: TextStyle(color: _secondaryTextColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _borderColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _accentColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  if (isUploading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 4),
                    Text(
                      'Processing image...',
                      style: TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isUploading ? null : () async {
                  if (nameController.text.isEmpty ||
                      priceController.text.isEmpty ||
                      durationController.text.isEmpty ||
                      categoryController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all required fields'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  setState(() => isUploading = true);

                  try {
                    String? imageUrl;

                    if (imageFile != null) {
                      final bytes = await imageFile!.readAsBytes();
                      imageUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                    }

                    final Map<String, dynamic> serviceData = {
                      'name': nameController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'price': double.parse(priceController.text.trim()),
                      'duration': int.parse(durationController.text.trim()),
                      'category': categoryController.text.trim(),
                      'isActive': true,
                      'rating': 0.0,
                      'totalBookings': 0,
                      'createdAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (imageUrl != null) {
                      serviceData['imageUrl'] = imageUrl;
                    }

                    await _firestore.collection('services').add(serviceData);

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Service added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => isUploading = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Add Service'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditServiceDialog(BuildContext context, String serviceId, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final descriptionController = TextEditingController(text: data['description'] ?? '');
    final priceController = TextEditingController(text: data['price']?.toString() ?? '');
    final durationController = TextEditingController(text: data['duration']?.toString() ?? '');
    final categoryController = TextEditingController(text: data['category'] ?? '');
    String? currentImageUrl = data['imageUrl'];
    File? imageFile;
    bool isUploading = false;
    bool removeImage = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          final isMobile = MediaQuery.of(context).size.width < 600;
          
          return AlertDialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            constraints: BoxConstraints(
              maxWidth: isMobile ? 340 : 420,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            title: Row(
              children: [
                Icon(Icons.edit, color: _accentColor),
                const SizedBox(width: 8),
                const Text('Edit Service'),
              ],
            ),
            content: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: isUploading ? null : () async {
                      final ImageSource? source = await showModalBottomSheet<ImageSource>(
                        context: context,
                        backgroundColor: _cardColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Select Image Source',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildImageSourceOption(
                                    context,
                                    Icons.photo_library,
                                    'Gallery',
                                    ImageSource.gallery,
                                    (source) {
                                      Navigator.pop(context, source);
                                    },
                                  ),
                                  _buildImageSourceOption(
                                    context,
                                    Icons.camera_alt,
                                    'Camera',
                                    ImageSource.camera,
                                    (source) {
                                      Navigator.pop(context, source);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (source != null) {
                        try {
                          final XFile? pickedFile = await _imagePicker.pickImage(
                            source: source,
                            maxWidth: 500,
                            maxHeight: 500,
                            imageQuality: 70,
                          );
                          if (pickedFile != null) {
                            setState(() {
                              imageFile = File(pickedFile.path);
                              currentImageUrl = null;
                              removeImage = false;
                            });
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error picking image: $e')),
                          );
                        }
                      }
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF222222) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _borderColor,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _buildEditImageDisplay(
                        imageFile,
                        currentImageUrl,
                        removeImage,
                        isDarkMode,
                      ),
                    ),
                  ),
                  if (currentImageUrl?.isNotEmpty == true && !removeImage) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: isUploading ? null : () {
                        setState(() {
                          removeImage = true;
                          currentImageUrl = null;
                          imageFile = null;
                        });
                      },
                      child: const Text(
                        'Remove Image',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: _primaryTextColor),
                    decoration: InputDecoration(
                      labelText: 'Service Name *',
                      hintText: 'e.g., Hair Styling',
                      labelStyle: TextStyle(color: _secondaryTextColor),
                      hintStyle: TextStyle(color: _secondaryTextColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _borderColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _accentColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    style: TextStyle(color: _primaryTextColor),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe the service',
                      labelStyle: TextStyle(color: _secondaryTextColor),
                      hintStyle: TextStyle(color: _secondaryTextColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _borderColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _accentColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          style: TextStyle(color: _primaryTextColor),
                          decoration: InputDecoration(
                            labelText: 'Price *',
                            hintText: 'e.g., 1500',
                            prefixText: 'Rs. ',
                            labelStyle: TextStyle(color: _secondaryTextColor),
                            hintStyle: TextStyle(color: _secondaryTextColor),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _borderColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _accentColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: durationController,
                          style: TextStyle(color: _primaryTextColor),
                          decoration: InputDecoration(
                            labelText: 'Duration (min) *',
                            hintText: 'e.g., 45',
                            labelStyle: TextStyle(color: _secondaryTextColor),
                            hintStyle: TextStyle(color: _secondaryTextColor),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _borderColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: _accentColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: categoryController,
                    style: TextStyle(color: _primaryTextColor),
                    decoration: InputDecoration(
                      labelText: 'Category *',
                      hintText: 'e.g., Hair, Makeup',
                      labelStyle: TextStyle(color: _secondaryTextColor),
                      hintStyle: TextStyle(color: _secondaryTextColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _borderColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _accentColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  if (isUploading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 4),
                    Text(
                      'Processing image...',
                      style: TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isUploading ? null : () async {
                  if (nameController.text.isEmpty ||
                      priceController.text.isEmpty ||
                      durationController.text.isEmpty ||
                      categoryController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all required fields'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  setState(() => isUploading = true);

                  try {
                    final Map<String, dynamic> updateData = {
                      'name': nameController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'price': double.parse(priceController.text.trim()),
                      'duration': int.parse(durationController.text.trim()),
                      'category': categoryController.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (imageFile != null) {
                      final bytes = await imageFile!.readAsBytes();
                      updateData['imageUrl'] = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                    } else if (removeImage) {
                      updateData['imageUrl'] = null;
                    }

                    await _firestore.collection('services').doc(serviceId).update(updateData);

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Service updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => isUploading = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Update Service'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditImageDisplay(File? imageFile, String? currentImageUrl, bool removeImage, bool isDarkMode) {
    if (imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          imageFile,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 100,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image, size: 40),
            );
          },
        ),
      );
    }

    if (currentImageUrl?.isNotEmpty == true && !removeImage) {
      if (currentImageUrl!.startsWith('data:image')) {
        try {
          final base64String = currentImageUrl.split(',').last;
          final bytes = base64Decode(base64String);
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 100,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: _accentColor.withOpacity(0.08),
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 40,
                      color: _secondaryTextColor,
                    ),
                  ),
                );
              },
            ),
          );
        } catch (e) {
          return _buildPlaceholderImage();
        }
      } else if (currentImageUrl.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            currentImageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 100,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: _accentColor.withOpacity(0.08),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: _accentColor.withOpacity(0.08),
                child: Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 40,
                    color: _secondaryTextColor,
                  ),
                ),
              );
            },
          ),
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            currentImageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 100,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: _accentColor.withOpacity(0.08),
                child: Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 40,
                    color: _secondaryTextColor,
                  ),
                ),
              );
            },
          ),
        );
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 40,
          color: _secondaryTextColor,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to change image (optional)',
          style: TextStyle(
            color: _secondaryTextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSourceOption(
    BuildContext context,
    IconData icon,
    String label,
    ImageSource source,
    void Function(ImageSource) onSelected,
  ) {
    return InkWell(
      onTap: () => onSelected(source),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: _accentColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: _primaryTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteService(String serviceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service? This will also remove all related bookings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final DocumentSnapshot doc = await _firestore
                    .collection('services')
                    .doc(serviceId)
                    .get();

                if (doc.exists) {
                  final Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
                  final String? imageUrl = docData['imageUrl'];

                  final bookingsSnapshot = await _firestore
                      .collection('service_bookings')
                      .where('serviceId', isEqualTo: serviceId)
                      .get();

                  final batch = _firestore.batch();
                  for (var booking in bookingsSnapshot.docs) {
                    batch.delete(booking.reference);
                  }
                  await batch.commit();

                  await _firestore.collection('services').doc(serviceId).delete();

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Service and related bookings deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting service: ${e.toString()}')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}