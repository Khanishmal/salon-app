// lib/screens/customer/ar_module/ar_makeup_screen.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'package:camera/camera.dart';

// =============================================================================
// ENUMS
// =============================================================================

enum LipFinish { matte, gloss, satin, metallic }
enum EyeshadowStyle { gradient, smoky, cutCrease }
enum EyelinerStyle { natural, winged, dramatic }
enum BridalStyle { traditional, modern, royal, minimal, dramatic }

// =============================================================================
// BRIDAL LOOK CONFIGURATION
// =============================================================================

class BridalLookConfig {
  // Makeup
  Color lipstickColor = const Color(0xFFD91A5B);
  double lipstickOpacity = 0.85;
  LipFinish lipFinish = LipFinish.matte;
  
  Color blushColor = const Color(0xFFE8736E);
  double blushOpacity = 0.55;
  
  Color eyeshadowColor = const Color(0xFF4A0020);
  double eyeshadowOpacity = 0.65;
  EyeshadowStyle eyeshadowStyle = EyeshadowStyle.gradient;
  bool eyeshadowShimmer = true;
  
  Color eyelinerColor = const Color(0xFF1A0A0A);
  double eyelinerOpacity = 0.90;
  EyelinerStyle eyelinerStyle = EyelinerStyle.winged;
  
  Color foundationColor = const Color(0xFFFFE0BD);
  double foundationOpacity = 0.35;
  
  Color highlighterColor = const Color(0xFFFFF0D0);
  double highlighterOpacity = 0.55;
  
  Color eyebrowColor = const Color(0xFF3D2314);
  double eyebrowOpacity = 0.75;
  
  // Jewelry
  bool showMaangTikka = true;
  bool showNath = true;
  bool showNecklace = true;
  bool showEarrings = true;
  Color jewelryColor = const Color(0xFFFFD700);
  
  // Style
  BridalStyle style = BridalStyle.traditional;
  String selectedLook = 'Bridal Classic';
}

// =============================================================================
// BRIDAL MAKEUP SCREEN
// =============================================================================

class ArMakeupScreen extends StatefulWidget {
  const ArMakeupScreen({super.key});

  @override
  State<ArMakeupScreen> createState() => _ArMakeupScreenState();
}

class _ArMakeupScreenState extends State<ArMakeupScreen>
    with WidgetsBindingObserver {
  // ===========================================================================
  // ENGINE & CAMERA
  // ===========================================================================

  late CameraController _cameraController;
  bool _cameraReady = false;
  Face? _detectedFace;
  final _previewKey = GlobalKey();
  bool _capturing = false;
  bool _isProcessing = false;

  // ===========================================================================
  // BRIDAL LOOK STATE
  // ===========================================================================

  final _cfg = BridalLookConfig();
  int _tab = 0;
  bool _isPhotoMode = false;
  File? _uploadedImage;
  String? _processedImageUrl;
  String? _aiAnalysisResult;
  bool _showBeforeAfter = false;
  String? _originalImageBase64;

  // ===========================================================================
  // PRESET BRIDAL LOOKS
  // ===========================================================================

  final List<Map<String, dynamic>> _bridalLooks = [
    {
      'name': 'Bridal Classic',
      'icon': '👰',
      'description': 'Traditional red bridal look',
      'lipColor': const Color(0xFFD91A5B),
      'blushColor': const Color(0xFFE8736E),
      'eyeColor': const Color(0xFF4A0020),
      'jewelry': 'Gold',
      'style': 'Traditional',
    },
    {
      'name': 'Royal Heritage',
      'icon': '👑',
      'description': 'Royal regal bridal look',
      'lipColor': const Color(0xFF8B0000),
      'blushColor': const Color(0xFFD4505A),
      'eyeColor': const Color(0xFF2A1A3A),
      'jewelry': 'Kundan',
      'style': 'Royal',
    },
    {
      'name': 'Modern Fusion',
      'icon': '✨',
      'description': 'Contemporary modern bridal',
      'lipColor': const Color(0xFFC44A6E),
      'blushColor': const Color(0xFFF0A0A0),
      'eyeColor': const Color(0xFFC8A080),
      'jewelry': 'Rose Gold',
      'style': 'Modern',
    },
    {
      'name': 'Minimal Elegance',
      'icon': '🌹',
      'description': 'Minimal elegant bridal',
      'lipColor': const Color(0xFFD4956A),
      'blushColor': const Color(0xFFFFB6C1),
      'eyeColor': const Color(0xFFD4A0A0),
      'jewelry': 'Platinum',
      'style': 'Minimal',
    },
    {
      'name': 'Dramatic Glam',
      'icon': '💫',
      'description': 'Bold dramatic bridal',
      'lipColor': const Color(0xFFE8203A),
      'blushColor': const Color(0xFFFF4D6D),
      'eyeColor': const Color(0xFF1A0080),
      'jewelry': 'Silver',
      'style': 'Dramatic',
    },
    {
      'name': 'Golden Hour',
      'icon': '🌅',
      'description': 'Warm golden bridal',
      'lipColor': const Color(0xFFFF6080),
      'blushColor': const Color(0xFFFF9E80),
      'eyeColor': const Color(0xFFFFD700),
      'jewelry': 'Gold',
      'style': 'Modern',
    },
  ];

  // ===========================================================================
  // COLOR PALETTES
  // ===========================================================================

  static const List<Color> _lipColors = [
    Color(0xFFD91A5B), Color(0xFF8B0000), Color(0xFFC8384E),
    Color(0xFFFF6080), Color(0xFFD4956A), Color(0xFFC44A6E),
    Color(0xFF7A1030), Color(0xFFE8203A), Color(0xFFFF4060),
  ];

  static const List<Color> _blushColors = [
    Color(0xFFE8736E), Color(0xFFF0A0A0), Color(0xFFD4505A),
    Color(0xFFFFB6C1), Color(0xFFFF9E80), Color(0xFFE0809A),
  ];

  static const List<Color> _eyeColors = [
    Color(0xFF4A0020), Color(0xFF8B4A6E), Color(0xFF2A1A3A),
    Color(0xFFC8A080), Color(0xFFD4A0A0), Color(0xFF1A0080),
    Color(0xFFFFD700), Color(0xFF8B0000), Color(0xFF4A305A),
  ];

  static const List<Color> _jewelryColors = [
    Color(0xFFFFD700), // Gold
    Color(0xFFC0C0C0), // Silver
    Color(0xFFE8C07A), // Rose Gold
    Color(0xFFFFC0CB), // Pink Gold
    Color(0xFFFFF8E7), // Platinum
  ];

  static const List<Color> _foundationColors = [
    Color(0xFFFFF5E6), Color(0xFFFFE0BD), Color(0xFFFFD4A8),
    Color(0xFFFFC898), Color(0xFFFFB880), Color(0xFFFFA870),
  ];

  static const List<Color> _highlightColors = [
    Color(0xFFFFF5E6), Color(0xFFFFF0D0), Color(0xFFFFE8C0),
    Color(0xFFFFFFFF), Color(0xFFFFF8F0),
  ];

  static const List<Color> _browColors = [
    Color(0xFF1A0A05), Color(0xFF3D2314), Color(0xFF5C3A1E),
    Color(0xFF7A5230), Color(0xFF2C1810),
  ];

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      // Handle pause
    } else if (state == AppLifecycleState.resumed) {
      // Handle resume
    }
  }

  // ===========================================================================
  // CAMERA INITIALIZATION
  // ===========================================================================

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController.initialize();
      setState(() => _cameraReady = true);
      
      // Start image stream for face detection
      _cameraController.startImageStream(_processCameraImage);
      
    } catch (e) {
      print('Camera initialization error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _processCameraImage(CameraImage image) {
    // Face detection would go here
    // For now, we'll just use a mock face for demo
    // In production, integrate with google_mlkit_face_detection
  }

  // ===========================================================================
  // CAPTURE & SAVE
  // ===========================================================================

  Future<void> _capture() async {
    if (_capturing) return;
    setState(() => _capturing = true);

    try {
      final XFile image = await _cameraController.takePicture();
      final File file = File(image.path);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Bridal look saved!'),
            backgroundColor: Color(0xFF2D1B4E),
          ),
        );
      }
    } catch (e) {
      print('Capture error: $e');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  // ===========================================================================
  // APPLY PRESET LOOK
  // ===========================================================================

  void _applyPresetLook(Map<String, dynamic> look) {
    setState(() {
      _cfg.lipstickColor = look['lipColor'];
      _cfg.blushColor = look['blushColor'];
      _cfg.eyeshadowColor = look['eyeColor'];
      _cfg.lipstickOpacity = 0.85;
      _cfg.blushOpacity = 0.55;
      _cfg.eyeshadowOpacity = 0.65;
      _cfg.selectedLook = look['name'];
      
      // Jewelry color based on style
      final jewelry = look['jewelry'] as String;
      if (jewelry == 'Gold') {
        _cfg.jewelryColor = const Color(0xFFFFD700);
      } else if (jewelry == 'Rose Gold') {
        _cfg.jewelryColor = const Color(0xFFE8C07A);
      } else if (jewelry == 'Silver') {
        _cfg.jewelryColor = const Color(0xFFC0C0C0);
      } else if (jewelry == 'Kundan') {
        _cfg.jewelryColor = const Color(0xFFFFD700);
      } else if (jewelry == 'Platinum') {
        _cfg.jewelryColor = const Color(0xFFFFF8E7);
      }
      
      _cfg.showMaangTikka = true;
      _cfg.showNath = true;
      _cfg.showNecklace = true;
      _cfg.showEarrings = true;
      _cfg.eyelinerStyle = EyelinerStyle.winged;
      _cfg.eyeshadowStyle = EyeshadowStyle.gradient;
      _cfg.eyeshadowShimmer = true;
      _cfg.foundationOpacity = 0.35;
      _cfg.highlighterOpacity = 0.55;
      _cfg.eyebrowOpacity = 0.75;
    });
  }

  // ===========================================================================
  // PHOTO UPLOAD & AI PROCESSING
  // ===========================================================================

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        _uploadedImage = File(image.path);
        _originalImageBase64 = base64Encode(bytes);
        _isPhotoMode = true;
        _processedImageUrl = null;
        _aiAnalysisResult = null;
        _showBeforeAfter = false;
        _isProcessing = false;
      });
    }
  }

  Future<void> _applyAIBridalLook() async {
    if (_uploadedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a photo first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final bytes = await _uploadedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prompt = _buildAIBridalPrompt();

      // Simulate AI processing (replace with actual API call)
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _processedImageUrl = _originalImageBase64;
        _aiAnalysisResult = _getBridalDescription();
        _showBeforeAfter = true;
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Bridal look applied successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _processedImageUrl = _originalImageBase64;
        _aiAnalysisResult = _getBridalDescription();
        _showBeforeAfter = true;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _buildAIBridalPrompt() {
    return '''
You are a professional bridal makeup artist. Apply a complete bridal look to this photo.

Style: ${_cfg.style.toString().split('.').last}
Lipstick: ${_cfg.lipstickColor.toString()}
Eyeshadow: ${_cfg.eyeshadowColor.toString()}
Jewelry: ${_cfg.jewelryColor.toString()}

Include makeup, jewelry, and hairstyle recommendations.
''';
  }

  String _getBridalDescription() {
    return '''
✨ **Bridal Look Applied!**

💄 **Makeup:**
- Foundation: Matched to your skin tone
- Blush: Soft rose glow
- Eyeshadow: Rich shimmer with winged liner
- Lipstick: Bold bridal red

👑 **Jewelry:**
- Maang Tikka, Nath, Necklace, Earrings

💇 **Hairstyle:**
Soft waves with flowers

Perfect for your special day! 👰
''';
  }

  // ===========================================================================
  // RESET
  // ===========================================================================

  void _resetAll() {
    setState(() {
      _cfg.lipstickColor = const Color(0xFFD91A5B);
      _cfg.blushColor = const Color(0xFFE8736E);
      _cfg.eyeshadowColor = const Color(0xFF4A0020);
      _cfg.eyelinerColor = const Color(0xFF1A0A0A);
      _cfg.foundationColor = const Color(0xFFFFE0BD);
      _cfg.highlighterColor = const Color(0xFFFFF0D0);
      _cfg.eyebrowColor = const Color(0xFF3D2314);
      _cfg.jewelryColor = const Color(0xFFFFD700);
      _cfg.lipstickOpacity = 0.85;
      _cfg.blushOpacity = 0.55;
      _cfg.eyeshadowOpacity = 0.65;
      _cfg.eyelinerStyle = EyelinerStyle.winged;
      _cfg.eyeshadowStyle = EyeshadowStyle.gradient;
      _cfg.eyeshadowShimmer = true;
      _cfg.showMaangTikka = true;
      _cfg.showNath = true;
      _cfg.showNecklace = true;
      _cfg.showEarrings = true;
      _cfg.selectedLook = 'Bridal Classic';
      _isPhotoMode = false;
      _uploadedImage = null;
      _processedImageUrl = null;
      _aiAnalysisResult = null;
      _showBeforeAfter = false;
    });
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(child: _cameraReady ? _buildView() : _buildLoader()),
          _buildPanel(),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOADER
  // ===========================================================================

  Widget _buildLoader() {
    return Container(
      color: const Color(0xFF0E0A14),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFD91A5B),
              strokeWidth: 2,
            ),
            SizedBox(height: 16),
            Text(
              'Initialising Camera…',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // VIEW
  // ===========================================================================

  Widget _buildView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          key: _previewKey,
          child: _isPhotoMode && _uploadedImage != null
              ? _buildPhotoView()
              : _buildCameraView(),
        ),
        _buildTopBar(),
        if (!_isPhotoMode) _buildPresetLooksBar(),
        if (_isProcessing) _buildProcessingOverlay(),
      ],
    );
  }

  // ===========================================================================
  // CAMERA VIEW
  // ===========================================================================

  Widget _buildCameraView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(-1.0, 1.0),
          child: CameraPreview(_cameraController),
        ),
        if (_detectedFace != null)
          LayoutBuilder(
            builder: (_, box) => CustomPaint(
              size: box.biggest,
              painter: BridalMakeupPainter(
                face: _detectedFace!,
                imageSize: _cameraController.value.previewSize!,
                rotation: InputImageRotation.rotation0deg,
                config: _cfg,
              ),
            ),
          ),
        if (_detectedFace == null)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Align face in frame',
                style: TextStyle(color: Colors.white60),
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // PHOTO VIEW
  // ===========================================================================

  Widget _buildPhotoView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_showBeforeAfter && _originalImageBase64 != null && _processedImageUrl != null)
          _buildBeforeAfterComparison()
        else
          Image.file(
            _uploadedImage!,
            fit: BoxFit.cover,
          ),
        if (_aiAnalysisResult != null && !_showBeforeAfter)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _aiAnalysisResult!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // BEFORE/AFTER COMPARISON
  // ===========================================================================

  Widget _buildBeforeAfterComparison() {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              Image.memory(
                base64Decode(_originalImageBase64!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  'BEFORE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 2,
          color: const Color(0xFFFFD700),
        ),
        Expanded(
          child: Stack(
            children: [
              Image.memory(
                base64Decode(_processedImageUrl!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stack) =>
                    Image.memory(
                      base64Decode(_originalImageBase64!),
                      fit: BoxFit.cover,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  'AFTER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TOP BAR
  // ===========================================================================

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: Row(
              children: [
                _iconBtn(Icons.arrow_back_ios_rounded,
                    () => Navigator.pop(context)),
                const SizedBox(width: 10),
                Text(
                  'Bridal Makeover',
                  style: GoogleFonts.cormorantGaramond(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (!_isPhotoMode) ...[
                  _iconBtn(Icons.photo_rounded, _uploadPhoto),
                  const SizedBox(width: 8),
                ],
                _iconBtn(Icons.refresh_rounded, _resetAll),
                const SizedBox(width: 8),
                if (!_isPhotoMode)
                  _iconBtn(
                    _capturing
                        ? Icons.hourglass_top
                        : Icons.camera_alt_rounded,
                    _capture,
                  ),
                if (_isPhotoMode && _uploadedImage != null)
                  _iconBtn(
                    _isProcessing
                        ? Icons.hourglass_top
                        : Icons.auto_awesome,
                    _applyAIBridalLook,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PRESET LOOKS BAR
  // ===========================================================================

  Widget _buildPresetLooksBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 44,
        margin: const EdgeInsets.only(bottom: 4),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: _bridalLooks.map((look) {
            final isSelected = _cfg.selectedLook == look['name'];
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => _applyPresetLook(look),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFD91A5B)
                        : Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFD91A5B)
                          : Colors.white24,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        look['icon'] as String,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        look['name'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ===========================================================================
  // PROCESSING OVERLAY
  // ===========================================================================

  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFD91A5B),
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'Creating your bridal look...',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'AI is applying makeup and jewelry',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM PANEL
  // ===========================================================================

  Widget _buildPanel() {
    if (_isPhotoMode) return const SizedBox.shrink();

    const List<Map<String, dynamic>> tabs = [
      {'icon': Icons.format_color_fill_rounded, 'label': 'Lips'},
      {'icon': Icons.remove_red_eye_rounded, 'label': 'Eyes'},
      {'icon': Icons.face_rounded, 'label': 'Face'},
      {'icon': Icons.diamond_rounded, 'label': 'Jewelry'},
    ];

    return Container(
      color: const Color(0xFF100A1A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            child: Row(
              children: List.generate(
                tabs.length,
                (i) {
                  final sel = _tab == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: sel
                                  ? const Color(0xFFD91A5B)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tabs[i]['icon'] as IconData,
                              size: 16,
                              color: sel
                                  ? const Color(0xFFD91A5B)
                                  : Colors.white30,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tabs[i]['label'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: sel
                                    ? const Color(0xFFD91A5B)
                                    : Colors.white30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case 0:
        return _lipsTab();
      case 1:
        return _eyesTab();
      case 2:
        return _faceTab();
      case 3:
        return _jewelryTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ===========================================================================
  // LIPS TAB
  // ===========================================================================

  Widget _lipsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _makeupRow(
          label: 'Lipstick',
          isOn: true,
          onToggle: (v) {},
          colors: _lipColors,
          selected: _cfg.lipstickColor,
          onColor: (c) => setState(() => _cfg.lipstickColor = c),
          opacity: _cfg.lipstickOpacity,
          onOpacity: (v) => setState(() => _cfg.lipstickOpacity = v),
          extra: _finishRow(),
        ),
      ],
    );
  }

  Widget _finishRow() {
    const List<Map<String, dynamic>> opts = [
      {'finish': LipFinish.matte, 'label': 'Matte'},
      {'finish': LipFinish.gloss, 'label': 'Gloss'},
      {'finish': LipFinish.satin, 'label': 'Satin'},
      {'finish': LipFinish.metallic, 'label': 'Metallic'},
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: opts.map((o) {
          final finish = o['finish'] as LipFinish;
          final label = o['label'] as String;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _cfg.lipFinish = finish),
              child: _chip(label, _cfg.lipFinish == finish),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // EYES TAB
  // ===========================================================================

  Widget _eyesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _makeupRow(
          label: 'Eye Shadow',
          isOn: true,
          onToggle: (v) {},
          colors: _eyeColors,
          selected: _cfg.eyeshadowColor,
          onColor: (c) => setState(() => _cfg.eyeshadowColor = c),
          opacity: _cfg.eyeshadowOpacity,
          onOpacity: (v) => setState(() => _cfg.eyeshadowOpacity = v),
          extra: _eyeStyleRow(),
        ),
        _sep(),
        _makeupRow(
          label: 'Eyeliner',
          isOn: true,
          onToggle: (v) {},
          colors: const [],
          selected: _cfg.eyelinerColor,
          onColor: (_) {},
          opacity: _cfg.eyelinerOpacity,
          onOpacity: (v) => setState(() => _cfg.eyelinerOpacity = v),
          extra: _linerStyleRow(),
        ),
      ],
    );
  }

  Widget _eyeStyleRow() {
    const List<Map<String, dynamic>> s = [
      {'style': EyeshadowStyle.gradient, 'label': 'Gradient'},
      {'style': EyeshadowStyle.smoky, 'label': 'Smoky'},
      {'style': EyeshadowStyle.cutCrease, 'label': 'Cut Crease'},
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          ...s.map((x) {
            final style = x['style'] as EyeshadowStyle;
            final label = x['label'] as String;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() => _cfg.eyeshadowStyle = style),
                child: _chip(label, _cfg.eyeshadowStyle == style),
              ),
            );
          }),
          GestureDetector(
            onTap: () =>
                setState(() => _cfg.eyeshadowShimmer = !_cfg.eyeshadowShimmer),
            child: _chip('✨ Shimmer', _cfg.eyeshadowShimmer),
          ),
        ],
      ),
    );
  }

  Widget _linerStyleRow() {
    const List<Map<String, dynamic>> s = [
      {'style': EyelinerStyle.natural, 'label': 'Natural'},
      {'style': EyelinerStyle.winged, 'label': 'Winged'},
      {'style': EyelinerStyle.dramatic, 'label': 'Dramatic'},
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: s.map((x) {
          final style = x['style'] as EyelinerStyle;
          final label = x['label'] as String;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _cfg.eyelinerStyle = style),
              child: _chip(label, _cfg.eyelinerStyle == style),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // FACE TAB
  // ===========================================================================

  Widget _faceTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _makeupRow(
          label: 'Foundation',
          isOn: true,
          onToggle: (v) {},
          colors: _foundationColors,
          selected: _cfg.foundationColor,
          onColor: (c) => setState(() => _cfg.foundationColor = c),
          opacity: _cfg.foundationOpacity,
          onOpacity: (v) => setState(() => _cfg.foundationOpacity = v),
        ),
        _sep(),
        _makeupRow(
          label: 'Blush',
          isOn: true,
          onToggle: (v) {},
          colors: _blushColors,
          selected: _cfg.blushColor,
          onColor: (c) => setState(() => _cfg.blushColor = c),
          opacity: _cfg.blushOpacity,
          onOpacity: (v) => setState(() => _cfg.blushOpacity = v),
        ),
        _sep(),
        _makeupRow(
          label: 'Highlighter',
          isOn: true,
          onToggle: (v) {},
          colors: _highlightColors,
          selected: _cfg.highlighterColor,
          onColor: (c) => setState(() => _cfg.highlighterColor = c),
          opacity: _cfg.highlighterOpacity,
          onOpacity: (v) => setState(() => _cfg.highlighterOpacity = v),
        ),
        _sep(),
        _makeupRow(
          label: 'Eyebrows',
          isOn: true,
          onToggle: (v) {},
          colors: _browColors,
          selected: _cfg.eyebrowColor,
          onColor: (c) => setState(() => _cfg.eyebrowColor = c),
          opacity: _cfg.eyebrowOpacity,
          onOpacity: (v) => setState(() => _cfg.eyebrowOpacity = v),
        ),
      ],
    );
  }

  // ===========================================================================
  // JEWELRY TAB
  // ===========================================================================

  Widget _jewelryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _jewelryToggle('Maang Tikka', _cfg.showMaangTikka,
            () => setState(() => _cfg.showMaangTikka = !_cfg.showMaangTikka)),
        _jewelryToggle('Nath', _cfg.showNath,
            () => setState(() => _cfg.showNath = !_cfg.showNath)),
        _jewelryToggle('Necklace', _cfg.showNecklace,
            () => setState(() => _cfg.showNecklace = !_cfg.showNecklace)),
        _jewelryToggle('Earrings', _cfg.showEarrings,
            () => setState(() => _cfg.showEarrings = !_cfg.showEarrings)),
        _sep(),
        const Text(
          'Jewelry Color',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _jewelryColors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final color = _jewelryColors[i];
              final sel = _cfg.jewelryColor == color;
              return GestureDetector(
                onTap: () => setState(() => _cfg.jewelryColor = color),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: sel ? Colors.white : Colors.white24,
                      width: sel ? 2.5 : 1,
                    ),
                  ),
                  child: sel
                      ? const Icon(Icons.check, color: Colors.black, size: 14)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // WIDGET HELPERS
  // ===========================================================================

  Widget _makeupRow({
    required String label,
    required bool isOn,
    required ValueChanged<bool> onToggle,
    required List<Color> colors,
    required Color selected,
    required ValueChanged<Color> onColor,
    required double opacity,
    required ValueChanged<double> onOpacity,
    Widget? extra,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
          ],
        ),
        if (colors.isNotEmpty) ...[
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: colors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final c = colors[i];
                final sel = c.value == selected.value;
                return GestureDetector(
                  onTap: () => onColor(c),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? Colors.white : Colors.white24,
                        width: sel ? 2.5 : 1,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: c.withOpacity(0.6),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                    child: sel
                        ? const Icon(
                            Icons.check,
                            size: 13,
                            color: Colors.white,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Text(
              'Intensity',
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: const Color(0xFFD91A5B),
                  inactiveTrackColor: Colors.white10,
                  thumbColor: const Color(0xFFD91A5B),
                ),
                child: Slider(
                  value: opacity,
                  min: 0.05,
                  max: 1.0,
                  onChanged: onOpacity,
                ),
              ),
            ),
            SizedBox(
              width: 34,
              child: Text(
                '${(opacity * 100).round()}%',
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        if (extra != null) extra,
      ],
    );
  }

  Widget _jewelryToggle(String label, bool isOn, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isOn ? const Color(0xFFFFD700).withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOn ? const Color(0xFFFFD700) : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOn ? Icons.check_circle : Icons.circle_outlined,
              color: isOn ? const Color(0xFFFFD700) : Colors.white54,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isOn ? const Color(0xFFFFD700) : Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFD91A5B).withOpacity(0.22)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFFD91A5B) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: isSelected ? const Color(0xFFD91A5B) : Colors.white54,
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback fn) {
    return GestureDetector(
      onTap: fn,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _sep() {
    return Divider(
      height: 14,
      thickness: 0.5,
      color: Colors.white.withOpacity(0.06),
    );
  }
}

// =============================================================================
// BRIDAL MAKEUP PAINTER - Simplified
// =============================================================================

class BridalMakeupPainter extends CustomPainter {
  final Face face;
  final Size imageSize;
  final InputImageRotation rotation;
  final BridalLookConfig config;

  const BridalMakeupPainter({
    required this.face,
    required this.imageSize,
    required this.rotation,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Simplified painter for demo
    // In production, this would apply full makeup
  }

  @override
  bool shouldRepaint(covariant BridalMakeupPainter oldDelegate) {
    return true;
  }
}