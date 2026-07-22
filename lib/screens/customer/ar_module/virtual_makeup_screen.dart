// lib/screens/customer/ar_module/virtual_makeup_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/makeup_configuration.dart';
import '../../../providers/makeup_provider.dart';
import '../../../painters/makeup_painter.dart';
import '../../../data/makeup_palettes.dart';

class VirtualMakeupScreen extends StatefulWidget {
  const VirtualMakeupScreen({super.key});

  @override
  State<VirtualMakeupScreen> createState() => _VirtualMakeupScreenState();
}

class _VirtualMakeupScreenState extends State<VirtualMakeupScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  bool _isBusy = false;
  List<Face> _detectedFaces = [];
  bool _isInitialized = false;
  String _selectedCategory = 'Lipstick';
  double _compareSliderX = 0.5;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isCapturing = false;
  bool _showSuccess = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupARPipeline();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _setupARPipeline() async {
    await [Permission.camera, Permission.storage].request();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    try {
      final cameras = await availableCameras();
      final frontCam = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
      _cameraController = CameraController(
        frontCam, 
        ResolutionPreset.medium, 
        enableAudio: false, 
        imageFormatGroup: ImageFormatGroup.yuv420
      );
      
      await _cameraController!.initialize();
      await _cameraController!.startImageStream((img) => _processFrame(img, frontCam));
      setState(() => _isInitialized = true);
    } catch (_) {}
  }

  void _processFrame(CameraImage img, CameraDescription cam) async {
    if (_isBusy || _isCapturing) return;
    _isBusy = true;

    try {
      final Uint8List bytes = Uint8List.fromList(
        img.planes.expand((plane) => plane.bytes).toList()
      );

      final rotation = InputImageRotationValue.fromRawValue(cam.sensorOrientation) ?? InputImageRotation.rotation0deg;
      final format = InputImageFormatValue.fromRawValue(img.format.group.index) ?? InputImageFormat.nv21;

      final metadata = InputImageMetadata(
        size: Size(img.width.toDouble(), img.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: img.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
      final faces = await _faceDetector.processImage(inputImage);

      if (mounted && !_isCapturing) {
        setState(() => _detectedFaces = faces);
      }
    } catch (_) {} finally {
      _isBusy = false;
    }
  }

  Future<void> _captureAndSave() async {
    if (_isCapturing) return;
    
    try {
      setState(() {
        _isCapturing = true;
        _showSuccess = false;
      });
      
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final File file = File('${directory.path}/makeup_look_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        setState(() => _showSuccess = true);
        
        // Show success with share and save options
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
        setState(() {
          _isCapturing = false;
        });
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
                  label: 'Save to Gallery',
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

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE28766)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Camera Preview with Makeup
          RepaintBoundary(
            key: _repaintBoundaryKey,
            child: Stack(
              children: [
                Positioned.fill(child: CameraPreview(_cameraController!)),
                Positioned.fill(
                  child: Consumer<MakeupProvider>(
                    builder: (context, provider, child) {
                      return CustomPaint(
                        painter: MakeupPainter(
                          faces: _detectedFaces,
                          config: provider.config,
                          absoluteImageSize: _cameraController!.value.previewSize!,
                          compareSliderX: _compareSliderX,
                          isCompareMode: provider.isCompareMode,
                          isCapturing: _isCapturing,
                        ),
                      );
                    },
                  ),
                ),
                if (_isCapturing)
                  Container(
                    color: Colors.black.withOpacity(0.6),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Capturing your look...',
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
          ),

          // Split Mode Overlay
          if (context.watch<MakeupProvider>().isCompareMode && !_isCapturing)
            Positioned.fill(
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _compareSliderX = (details.localPosition.dx / MediaQuery.of(context).size.width)
                        .clamp(0.0, 1.0);
                  });
                },
                child: Stack(
                  children: [
                    Positioned(
                      left: MediaQuery.of(context).size.width * _compareSliderX - 1,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: Colors.white,
                        child: Center(
                          child: Container(
                            height: 44,
                            width: 44,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black45)],
                            ),
                            child: const Icon(
                              Icons.unfold_more_rounded,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

          // Capture Button with Pulse Animation
          Positioned(
            bottom: 220,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: GestureDetector(
                      onTap: _captureAndSave,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFE28766),
                              const Color(0xFFE28766).withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE28766).withOpacity(0.4),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Category Selection Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildCategoryPanel(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'VIRTUAL TRY-ON',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 3,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Consumer<MakeupProvider>(
          builder: (context, provider, child) {
            return Row(
              children: [
                IconButton(
                  icon: Icon(
                    provider.isCompareMode ? Icons.splitscreen : Icons.compare_arrows,
                    color: Colors.white,
                  ),
                  onPressed: () => provider.toggleCompareMode(),
                ),
                IconButton(
                  icon: const Icon(Icons.clear_all, color: Colors.white),
                  onPressed: () {
                    provider.clearMakeover();
                    _showToast('Makeup cleared');
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryPanel() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.98),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category Chips with Icons
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: MakeupPalettes.colorPalettes.keys.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildCategoryChip(category, isSelected),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Color Palette Grid - Professional Grid Layout
          Container(
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: MakeupPalettes.colorPalettes[_selectedCategory]!.length,
              itemBuilder: (context, index) {
                final shade = MakeupPalettes.colorPalettes[_selectedCategory]![index];
                final isActive = _isColorActive(shade.color);
                
                return _buildColorSwatch(shade, isActive);
              },
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Intensity Slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.opacity, color: Colors.white54, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer<MakeupProvider>(
                    builder: (context, provider, child) {
                      return Slider(
                        value: _getCurrentOpacity(),
                        min: 0.0,
                        max: 1.0,
                        activeColor: const Color(0xFFE28766),
                        inactiveColor: Colors.white24,
                        onChanged: (value) {
                          _updateOpacity(value);
                        },
                      );
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
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.05),
                ],
              ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected 
              ? const Color(0xFFE28766) 
              : Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Use asset image if available, fallback to emoji
            Image.asset(
              MakeupPalettes.categoryImagePaths[category]!,
              width: 18,
              height: 18,
              errorBuilder: (context, error, stackTrace) => Text(
                MakeupPalettes.categoryIcons[category] ?? '',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              MakeupPalettes.categoryLabels[category] ?? '',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
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

  Widget _buildColorSwatch(MakeupShade shade, bool isActive) {
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
              color: const Color(0xFFE28766).withOpacity(0.5),
              blurRadius: 16,
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
    final config = context.read<MakeupProvider>().config;
    switch (_selectedCategory) {
      case 'Lipstick': return config.lipstickColor == color;
      case 'Foundation': return config.foundationColor == color;
      case 'Blush': return config.blushColor == color;
      case 'Eyeshadow': return config.eyeshadowColor == color;
      case 'Eyeliner': return config.eyelinerColor == color;
      case 'Eyebrow': return config.eyebrowColor == color;
      case 'Highlighter': return config.highlighterColor == color;
      case 'Bronzer': return config.bronzerColor == color;
      default: return false;
    }
  }

  void _applyColor(Color color) {
    context.read<MakeupProvider>().updateColor(_selectedCategory, color);
  }

  double _getCurrentOpacity() {
    final config = context.read<MakeupProvider>().config;
    switch (_selectedCategory) {
      case 'Lipstick': return config.lipstickOpacity;
      case 'Foundation': return config.foundationOpacity;
      case 'Blush': return config.blushOpacity;
      case 'Eyeshadow': return config.eyeshadowOpacity;
      case 'Eyeliner': return config.eyelinerOpacity;
      case 'Eyebrow': return config.eyebrowOpacity;
      case 'Highlighter': return config.highlighterOpacity;
      case 'Bronzer': return config.bronzerOpacity;
      default: return 0.5;
    }
  }

  void _updateOpacity(double value) {
    context.read<MakeupProvider>().updateOpacity(_selectedCategory, value);
  }
}