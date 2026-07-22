import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/mehndi_models.dart';

class ArMehndiScreen extends StatefulWidget {
  const ArMehndiScreen({super.key});

  @override
  State<ArMehndiScreen> createState() => _ArMehndiScreenState();
}

class _ArMehndiScreenState extends State<ArMehndiScreen>
    with SingleTickerProviderStateMixin {
  
  File? _selectedImage;
  bool _isImageLoading = false;
  String? _selectedPatternId;
  int _selectedTab = 0;

  final ImagePicker _picker = ImagePicker();
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  // 4 Mehndi Patterns with applied hand images
  final List<String> _patternIds = [
    'arabic_leaves',
    'mandala_flower',
    'bridal_full',
    'geometric_lines',
  ];

  @override
  void initState() {
    super.initState();
    // Set default pattern
    _selectedPatternId = _patternIds.first;
  }

  Future<void> _pickImage() async {
    setState(() => _isImageLoading = true);
    
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 800,
      maxHeight: 800,
    );
    
    setState(() => _isImageLoading = false);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      _showSnackBar('Hand image uploaded! Select a mehndi design.', Colors.green);
    }
  }

  void _showSnackBar(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildTryOnTab(isMobile, screenHeight),
          _buildHistoryTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'MEHNDI STUDIO',
        style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2),
      ),
      backgroundColor: const Color(0xFF0A0A0A),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedTab,
      backgroundColor: const Color(0xFF0A0A0A),
      selectedItemColor: const Color(0xFFE28766),
      unselectedItemColor: Colors.white54,
      elevation: 0,
      onTap: (index) => setState(() => _selectedTab = index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.brush, size: 22), label: 'Try-On'),
        BottomNavigationBarItem(icon: Icon(Icons.history, size: 22), label: 'History'),
      ],
    );
  }

  Widget _buildTryOnTab(bool isMobile, double screenHeight) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 10 : 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Display
          Container(
            height: isMobile ? screenHeight * 0.35 : 320,
            width: double.infinity,
            child: _buildImageDisplay(),
          ),
          const SizedBox(height: 10),
          
          // Upload Button - Only Gallery
          _buildSourceButton(isMobile),
          
          const SizedBox(height: 14),
          
          // Pattern Selection - Fixed overflow with smaller height
          _buildPatternSelection(isMobile),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (_isImageLoading) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.white.withOpacity(0.04),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFFE28766), strokeWidth: 2.5),
                SizedBox(height: 12),
                Text(
                  'Loading image...',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If image is selected and pattern is selected, show applied mehndi from assets
    if (_selectedImage != null && _selectedPatternId != null) {
      final pattern = MehndiPatterns.getById(_selectedPatternId!);
      if (pattern != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: RepaintBoundary(
            key: _repaintBoundaryKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Show the applied mehndi image from assets
                Image.asset(
                  pattern.assetPath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.white.withOpacity(0.05),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported, size: 50, color: Colors.white24),
                          const SizedBox(height: 8),
                          Text(
                            'Design not available',
                            style: GoogleFonts.poppins(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Pattern name overlay at bottom
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE28766),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            pattern.category.toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pattern.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.check_circle,
                          color: const Color(0xFFE28766),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Default: Show upload placeholder
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.white.withOpacity(0.04),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.brush, size: 50, color: Colors.white.withOpacity(0.15)),
              const SizedBox(height: 12),
              Text(
                'Upload hand photo',
                style: GoogleFonts.poppins(
                  color: Colors.white30,
                  fontSize: 14,
                ),
              ),
              Text(
                'Then select a mehndi design',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.15),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Choose Image', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE28766),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton(bool isMobile) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, color: Colors.white54, size: 18),
            const SizedBox(width: 6),
            Text(
              'Upload Hand Image',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternSelection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.grid_view, color: const Color(0xFFE28766), size: 18),
            const SizedBox(width: 8),
            Text(
              'Select Mehndi Design',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Fixed overflow by reducing height
        SizedBox(
          height: 70, // Reduced from 85 to 70 to fix overflow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _patternIds.length,
            itemBuilder: (context, index) {
              final patternId = _patternIds[index];
              final pattern = MehndiPatterns.getById(patternId);
              if (pattern == null) return const SizedBox();
              
              final isSelected = _selectedPatternId == patternId;
              return GestureDetector(
                onTap: () => setState(() => _selectedPatternId = patternId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 70,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE28766).withOpacity(0.15)
                        : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFE28766) : Colors.white.withOpacity(0.08),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFE28766).withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pattern.icon,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pattern.name,
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 7,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(top: 1),
                          width: 12,
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE28766),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 60,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'History Coming Soon',
            style: GoogleFonts.poppins(
              color: Colors.white30,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saved designs will appear here',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.2),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}