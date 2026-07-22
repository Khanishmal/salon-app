// lib/screens/customer/ar_module/photo_makeup_tryon_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:animate_do/animate_do.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui; 
import '../../../models/makeup_configuration.dart';
import '../../../painters/static_photo_makeup_painter.dart';
import '../../../data/photo_makeup_palettes.dart';

class PhotoMakeupTryonScreen extends StatefulWidget {
  const PhotoMakeupTryonScreen({super.key});

  @override
  State<PhotoMakeupTryonScreen> createState() => _PhotoMakeupTryonScreenState();
}

class _PhotoMakeupTryonScreenState extends State<PhotoMakeupTryonScreen> with SingleTickerProviderStateMixin {
  File? _selectedImageFile;
  Size? _nativeFileImageSize;
  List<Face> _verifiedFaces = [];
  bool _isAnalyzing = false;
  bool _hideMakeupOverlay = false;
  String _selectedCategory = 'Lipstick';
  bool _isExporting = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  final MakeupConfiguration _currentConfig = MakeupConfiguration();

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
  }

  Future<void> _processAndVerifyPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 100);
    if (pickedFile == null) return;

    setState(() {
      _isAnalyzing = true;
      _selectedImageFile = null;
      _verifiedFaces = [];
    });

    try {
      final File file = File(pickedFile.path);
      final decodedImage = await decodeImageFromList(await file.readAsBytes());
      final Size nativeSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());

      final inputImage = InputImage.fromFile(file);
      final detectedFaces = await _faceDetector.processImage(inputImage);

      if (detectedFaces.isEmpty) {
        _showVerificationFailureDialog(
          "No Face Detected",
          "Our AI system could not locate a clear human face in this photo. Please ensure:\n• Face is clearly visible\n• Good lighting conditions\n• Face is looking directly at the camera"
        );
        setState(() => _isAnalyzing = false);
        return;
      }
      
      if (detectedFaces.length > 1) {
        _showVerificationFailureDialog(
          "Multiple Faces Detected",
          "Please select a photo with only one person. Multiple faces can interfere with accurate makeup application."
        );
        setState(() => _isAnalyzing = false);
        return;
      }

      setState(() {
        _selectedImageFile = file;
        _nativeFileImageSize = nativeSize;
        _verifiedFaces = detectedFaces;
        _isAnalyzing = false;
      });

    } catch (e) {
      _showVerificationFailureDialog("Processing Error", "Failed to process image: $e");
      setState(() => _isAnalyzing = false);
    }
  }

  void _showVerificationFailureDialog(String title, String description) {
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
          description,
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
      
      // Capture the rendered widget
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final File file = File('${directory.path}/makeup_look_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        _showSuccessDialog(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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
              'Your virtual makeup look is ready',
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
                    final savedFile = File('${directory.path}/makeup_look_${DateTime.now().millisecondsSinceEpoch}.png');
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
                      text: '✨ My Virtual Makeup Look ✨\nCreated with GlowSalon App\n💄 Try it now!',
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

  @override
  void dispose() {
    _faceDetector.close();
    _pulseController.dispose();
    super.dispose();
  }

  final GlobalKey _repaintBoundaryKey = GlobalKey();

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
                  child: _selectedImageFile == null 
                      ? _buildUploadSection()
                      : RepaintBoundary(
                          key: _repaintBoundaryKey,
                          child: _buildPhotoCanvasWorkspace(),
                        ),
                ),
              ),
              if (_selectedImageFile != null) _buildCosmeticsControlDeck(),
            ],
          ),
          if (_isAnalyzing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFFE28766),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Analyzing your photo...',
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
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
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
        'PHOTO STUDIO',
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
        if (_selectedImageFile != null)
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedImageFile = null;
                _verifiedFaces = [];
                _currentConfig.lipstickColor = Colors.transparent;
                _currentConfig.foundationColor = Colors.transparent;
                _currentConfig.blushColor = Colors.transparent;
                _currentConfig.eyeshadowColor = Colors.transparent;
                _currentConfig.eyelinerColor = Colors.transparent;
                _currentConfig.eyebrowColor = Colors.transparent;
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
                Icons.photo_camera_front,
                color: Color(0xFFE28766),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Upload a Photo',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Apply virtual makeup to any photo',
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
                    onTap: () => _processAndVerifyPhoto(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildUploadButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.blue,
                    onTap: () => _processAndVerifyPhoto(ImageSource.camera),
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

  Widget _buildPhotoCanvasWorkspace() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Image with Makeup
        AspectRatio(
          aspectRatio: _nativeFileImageSize!.width / _nativeFileImageSize!.height,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.file(
                  _selectedImageFile!,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: StaticPhotoMakeupPainter(
                    faces: _verifiedFaces,
                    config: _currentConfig,
                    originalImageSize: _nativeFileImageSize!,
                    hideMakeup: _hideMakeupOverlay,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Compare Button
        Positioned(
          top: 16,
          left: 16,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _hideMakeupOverlay = true),
            onTapUp: (_) => setState(() => _hideMakeupOverlay = false),
            onTapCancel: () => setState(() => _hideMakeupOverlay = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'HOLD TO COMPARE',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildCosmeticsControlDeck() {
    final categoryKeys = PhotoMakeupPalettes.allPalettes.keys.toList();
    
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
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category Chips
          Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: categoryKeys.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildCategoryChip(category, isSelected),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Color Shades Grid
          Container(
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: PhotoMakeupPalettes.allPalettes[_selectedCategory]!.length,
              itemBuilder: (context, index) {
                final shade = PhotoMakeupPalettes.allPalettes[_selectedCategory]![index];
                final isActive = _isColorActive(shade.color);
                return _buildShadeSwatch(shade, isActive);
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Opacity Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.opacity, color: Colors.white54, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _getCurrentOpacity(),
                    min: 0.0,
                    max: 1.0,
                    activeColor: const Color(0xFFE28766),
                    inactiveColor: Colors.white24,
                    onChanged: (value) {
                      _updateOpacity(value);
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(_getCurrentOpacity() * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected 
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
            color: isSelected 
              ? const Color(0xFFE28766) 
              : Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              PhotoMakeupPalettes.categoryIcons[category] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              PhotoMakeupPalettes.categoryLabels[category] ?? '',
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShadeSwatch(PhotoMakeupShade shade, bool isActive) {
    return GestureDetector(
      onTap: () => _applyColor(shade.color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: shade.color,
          border: Border.all(
            color: isActive ? const Color(0xFFE28766) : Colors.transparent,
            width: 3,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: const Color(0xFFE28766).withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: isActive
            ? const Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            : null,
      ),
    );
  }

  bool _isColorActive(Color color) {
    switch (_selectedCategory) {
      case 'Lipstick': return _currentConfig.lipstickColor == color;
      case 'Foundation': return _currentConfig.foundationColor == color;
      case 'Blush': return _currentConfig.blushColor == color;
      case 'Eyeshadow': return _currentConfig.eyeshadowColor == color;
      case 'Eyeliner': return _currentConfig.eyelinerColor == color;
      case 'Eyebrow': return _currentConfig.eyebrowColor == color;
      default: return false;
    }
  }

  void _applyColor(Color color) {
    setState(() {
      switch (_selectedCategory) {
        case 'Lipstick': _currentConfig.lipstickColor = color; break;
        case 'Foundation': _currentConfig.foundationColor = color; break;
        case 'Blush': _currentConfig.blushColor = color; break;
        case 'Eyeshadow': _currentConfig.eyeshadowColor = color; break;
        case 'Eyeliner': _currentConfig.eyelinerColor = color; break;
        case 'Eyebrow': _currentConfig.eyebrowColor = color; break;
      }
    });
  }

  double _getCurrentOpacity() {
    switch (_selectedCategory) {
      case 'Lipstick': return _currentConfig.lipstickOpacity;
      case 'Foundation': return _currentConfig.foundationOpacity;
      case 'Blush': return _currentConfig.blushOpacity;
      case 'Eyeshadow': return _currentConfig.eyeshadowOpacity;
      case 'Eyeliner': return _currentConfig.eyelinerOpacity;
      case 'Eyebrow': return _currentConfig.eyebrowOpacity;
      default: return 0.5;
    }
  }

  void _updateOpacity(double value) {
    setState(() {
      switch (_selectedCategory) {
        case 'Lipstick': _currentConfig.lipstickOpacity = value; break;
        case 'Foundation': _currentConfig.foundationOpacity = value; break;
        case 'Blush': _currentConfig.blushOpacity = value; break;
        case 'Eyeshadow': _currentConfig.eyeshadowOpacity = value; break;
        case 'Eyeliner': _currentConfig.eyelinerOpacity = value; break;
        case 'Eyebrow': _currentConfig.eyebrowOpacity = value; break;
      }
    });
  }
}