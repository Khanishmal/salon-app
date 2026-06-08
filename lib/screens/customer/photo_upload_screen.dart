// lib/screens/customer_modules/photo_upload.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class PhotoUploadScreen extends StatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isUploading = false;
  int _selectedCategory = 0;

  final List<String> _categories = ['Face', 'Hair', 'Nails', 'Full Body'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Photo Gallery",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickMultipleImages,
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _pickImage,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(
            child: _selectedImages.isEmpty && !_isUploading
                ? _buildEmptyState()
                : _buildImageGrid(),
          ),
          if (_selectedImages.isNotEmpty) _buildUploadButton(),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      color: Colors.white,
      child: Row(
        children: List.generate(_categories.length, (index) {
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedCategory == index
                          ? const Color(0xFFF2845C)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  _categories[index],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: _selectedCategory == index
                        ? const Color(0xFFF2845C)
                        : Colors.grey[600],
                    fontWeight: _selectedCategory == index
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            "No Photos Yet",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Tap the camera icon to upload photos",
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.photo_library,
                label: "Gallery",
                onTap: _pickMultipleImages,
              ),
              const SizedBox(width: 20),
              _buildActionButton(
                icon: Icons.camera_alt,
                label: "Camera",
                onTap: _pickImage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFDEEE9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFF2845C), size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins()),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _selectedImages.length + (_isUploading ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isUploading && index == 0) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFF2845C)),
            ),
          );
        }
        int imageIndex = _isUploading ? index - 1 : index;
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: FileImage(_selectedImages[imageIndex]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImages.removeAt(imageIndex);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUploadButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isUploading ? null : _uploadImages,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF2845C),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: _isUploading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Text(
                  "Upload ${_selectedImages.length} Photo${_selectedImages.length > 1 ? 's' : ''}",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  Future<void> _pickMultipleImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      setState(() {
        _selectedImages.addAll(images.map((e) => File(e.path)));
      });
    }
  }

  Future<void> _uploadImages() async {
    setState(() => _isUploading = true);

    try {
      for (var image in _selectedImages) {
        String fileName = '${user?.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = FirebaseStorage.instance.ref().child('user_photos/$fileName');
        
        await ref.putFile(image);
        String downloadUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('user_photos').add({
          'userId': user?.uid,
          'imageUrl': downloadUrl,
          'category': _categories[_selectedCategory],
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        _selectedImages.clear();
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photos uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}