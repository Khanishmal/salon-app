// lib/screens/customer/ar_module/ar_jewelry_screen.dart
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:animate_do/animate_do.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/jewelry_models.dart';
import '../../../painters/jewelry_painter.dart';
import '../../../services/jewelry_asset_loader.dart';

class ArJewelryScreen extends StatefulWidget {
  const ArJewelryScreen({super.key});

  @override
  State<ArJewelryScreen> createState() => _ArJewelryScreenState();
}

class _ArJewelryScreenState extends State<ArJewelryScreen> with SingleTickerProviderStateMixin {
  File? _selectedImage;
  Size? _nativeImageSize;
  List<Face> _detectedFaces = [];
  bool _isAnalyzing = false;
  bool _isExporting = false;
  
  // Selected jewelry - allow multiple items
  List<String> _selectedJewelryIds = [];
  Map<String, ui.Image?> _loadedImages = {};
  Map<String, JewelryAsset> _jewelryAssets = {};
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  final GlobalKey _repaintBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _loadAllJewelryAssets();
  }

  Future<void> _loadAllJewelryAssets() async {
    final assets = JewelryAssets.all;
    final Map<String, ui.Image?> images = {};
    final Map<String, JewelryAsset> assetMap = {};
    
    for (final asset in assets) {
      images[asset.assetPath] = await JewelryAssetLoader.loadAsset(asset.assetPath);
      assetMap[asset.id] = asset;
    }
    
    setState(() {
      _loadedImages = images;
      _jewelryAssets = assetMap;
    });
  }

  Future<void> _pickAndVerifyImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 100);
    if (pickedFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _selectedImage = null;
      _detectedFaces = [];
    });

    try {
      final File file = File(pickedFile.path);
      final decodedImage = await decodeImageFromList(await file.readAsBytes());
      final Size nativeSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());

      final inputImage = InputImage.fromFile(file);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _showErrorDialog(
          "No Face Detected",
          "Our AI could not detect a clear face. Please ensure good lighting and a front-facing photo."
        );
        setState(() => _isAnalyzing = false);
        return;
      }

      if (faces.length > 1) {
        _showErrorDialog(
          "Multiple Faces",
          "Please upload a photo with only one person for accurate jewelry placement."
        );
        setState(() => _isAnalyzing = false);
        return;
      }

      setState(() {
        _selectedImage = file;
        _nativeImageSize = nativeSize;
        _detectedFaces = faces;
        _isAnalyzing = false;
        // Select default jewelry set
        _applyJewelrySet('gold_bridal');
      });

    } catch (e) {
      setState(() => _isAnalyzing = false);
      _showErrorDialog("Error", "Failed to process image: $e");
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE28766), width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFE28766)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE28766),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportResult() async {
    if (_isExporting) return;
    
    try {
      setState(() => _isExporting = true);
      
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final File file = File('${directory.path}/jewelry_look_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        _showSuccessDialog(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showSuccessDialog(File file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 320,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(
              Icons.check_circle,
              color: Color(0xFFE28766),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              '✨ Look Captured!',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your jewelry look is ready',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.save_alt,
                  label: 'Save',
                  color: const Color(0xFFE28766),
                  onTap: () async {
                    final directory = await getApplicationDocumentsDirectory();
                    final savedFile = File('${directory.path}/jewelry_look_${DateTime.now().millisecondsSinceEpoch}.png');
                    await file.copy(savedFile.path);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('💾 Saved to gallery!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    Share.shareXFiles(
                      [XFile(file.path)],
                      text: '✨ My Virtual Jewelry Look ✨\nCreated with GlowSalon App\n💎 Try it now!',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyJewelrySet(String setId) {
    final set = JewelrySets.getById(setId);
    if (set != null) {
      setState(() {
        _selectedJewelryIds = set.assetIds;
      });
    }
  }

  void _toggleJewelry(String id) {
    setState(() {
      if (_selectedJewelryIds.contains(id)) {
        _selectedJewelryIds.remove(id);
      } else {
        _selectedJewelryIds.add(id);
      }
    });
  }

  bool _isJewelrySelected(String id) {
    return _selectedJewelryIds.contains(id);
  }

  @override
  void dispose() {
    _faceDetector.close();
    _pulseController.dispose();
    JewelryAssetLoader.clearCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: _selectedImage == null
                      ? _buildUploadSection()
                      : RepaintBoundary(
                          key: _repaintBoundaryKey,
                          child: _buildJewelryPreview(),
                        ),
                ),
              ),
              if (_selectedImage != null) _buildJewelryControls(),
            ],
          ),
          if (_isAnalyzing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFE28766)),
                    SizedBox(height: 20),
                    Text(
                      'Detecting face...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isExporting)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Exporting your look...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'AR JEWELRY STUDIO',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 3,
        ),
      ),
      backgroundColor: const Color(0xFF0A0A0A),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_selectedImage != null)
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedImage = null;
                _detectedFaces = [];
                _selectedJewelryIds = [];
              });
            },
          ),
      ],
    );
  }

  Widget _buildUploadSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF0D0D0D),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFE28766).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE28766).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.diamond,
                color: Color(0xFFE28766),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Try On Jewelry',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a photo to try on jewelry virtually',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildUploadButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: const Color(0xFFE28766),
                    onTap: () => _pickAndVerifyImage(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildUploadButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.blue,
                    onTap: () => _pickAndVerifyImage(ImageSource.camera),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildRequirementItem(
                    Icons.face,
                    'Clear face',
                    'Face should be visible and front-facing',
                  ),
                  const Divider(color: Colors.white10),
                  _buildRequirementItem(
                    Icons.light_mode,
                    'Good lighting',
                    'Even lighting without harsh shadows',
                  ),
                  const Divider(color: Colors.white10),
                  _buildRequirementItem(
                    Icons.person_pin,
                    'Single person',
                    'Only one person in the photo',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[500], size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJewelryPreview() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _nativeImageSize!.width / _nativeImageSize!.height,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: JewelryPainter(
                    faces: _detectedFaces,
                    originalImageSize: _nativeImageSize!,
                    selectedJewelryIds: _selectedJewelryIds,
                    loadedImages: _loadedImages,
                    jewelryAssets: _jewelryAssets,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Export Button
        Positioned(
          bottom: 80,
          right: 16,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: FloatingActionButton(
                  onPressed: _exportResult,
                  backgroundColor: const Color(0xFFE28766),
                  child: const Icon(Icons.download, color: Colors.white),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJewelryControls() {
    // Group jewelry by category for better organization
    final categories = JewelryAssets.categories;
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Jewelry Sets
          Container(
            height: 44,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: JewelrySets.all.map((set) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildSetChip(set),
                );
              }).toList(),
            ),
          ),
          
          // Individual Jewelry Items by Category
          ...categories.map((category) {
            final items = JewelryAssets.getByCategory(category);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    category,
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Container(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: items.map((asset) {
                      final isSelected = _isJewelrySelected(asset.id);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildJewelryChip(asset, isSelected),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSetChip(JewelrySet set) {
    final isActive = set.assetIds.every((id) => _selectedJewelryIds.contains(id));
    
    return GestureDetector(
      onTap: () => _applyJewelrySet(set.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive
            ? LinearGradient(
                colors: [
                  const Color(0xFFE28766),
                  const Color(0xFFE28766).withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.02),
                ],
              ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive 
              ? const Color(0xFFE28766) 
              : Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(set.icon, color: isActive ? Colors.white : Colors.white60, size: 16),
            const SizedBox(width: 8),
            Text(
              set.name,
              style: GoogleFonts.poppins(
                color: isActive ? Colors.white : Colors.white60,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJewelryChip(JewelryAsset asset, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleJewelry(asset.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
            ? LinearGradient(
                colors: [
                  const Color(0xFFE28766).withOpacity(0.8),
                  const Color(0xFFE28766).withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.02),
                ],
              ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
              ? const Color(0xFFE28766) 
              : Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(asset.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              asset.name,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_circle, color: Colors.white, size: 12),
            ],
          ],
        ),
      ),
    );
  }
}