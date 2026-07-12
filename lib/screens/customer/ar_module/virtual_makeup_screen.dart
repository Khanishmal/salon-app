//lib/screens/virtual_makeup_screen.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../models/makeup_configuration.dart';
import '../../../painters/makeup_painter.dart';

class VirtualMakeupScreen extends StatefulWidget {
  const VirtualMakeupScreen({super.key});

  @override
  State<VirtualMakeupScreen> createState() => _VirtualMakeupScreenState();
}

class _VirtualMakeupScreenState extends State<VirtualMakeupScreen> {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  bool _isBusy = false;
  List<Face> _detectedFaces = [];
  bool _isInitialized = false;

  String _selectedCategory = 'Lipstick';
  int _frameSkipCounter = 0;

  // Image assets preloaded in memory for real-time performance
  ui.Image? _loadedNath;
  ui.Image? _loadedTeeka;
  ui.Image? _loadedMehndi;

  // Global Makeup Configuration State
  final MakeupConfiguration _currentConfig = MakeupConfiguration(
    lipstickColor: const Color(0xFFD91A5B),
    blushColor: const Color(0xFFFFB6C1),
    eyeshadowColor: const Color(0xFF8C0327),
    eyelinerColor: const Color(0xFF000000),
    contourColor: const Color(0xFF5C4033),
    jewelryColor: const Color(0xFFFFD700), 
    mehndiColor: const Color(0xFF4A2C00),  
  );

  // Deep Premium Bridal Palette Selection
  final Map<String, List<Color>> _colorPalettes = {
    'Lipstick': [Colors.transparent, const Color(0xFFD91A5B), const Color(0xFF8C0327), const Color(0xFFE65C7B), const Color(0xFF590219), const Color(0xFFC71585)],
    'Blush': [Colors.transparent, const Color(0xFFFFB6C1), const Color(0xFFFA8072), const Color(0xFFE9967A), const Color(0xFFFF69B4)],
    'Eyeshadow': [Colors.transparent, const Color(0xFF8C0327), const Color(0xFFFFD700), const Color(0xFF4B0082), const Color(0xFF1167B1), const Color(0xFF004B23)],
    'Eyeliner': [Colors.transparent, const Color(0xFF000000), const Color(0xFF2C3E50), const Color(0xFF1A1A1A)],
    'Contour': [Colors.transparent, const Color(0xFF5C4033), const Color(0xFF704214), const Color(0xFF3D2314)],
    'Jewelry': [Colors.transparent, const Color(0xFFFFD700), const Color(0xFFE6C280), const Color(0xFFC0C0C0), const Color(0xFFFFDF73)], 
    'Mehndi': [Colors.transparent, const Color(0xFF4A2C00), const Color(0xFF6E3A07), const Color(0xFF2B1900), const Color(0xFF5C2C16)],   
  };

  @override
  void initState() {
    super.initState();
    _loadProfessionalAssets();
    _initializePipeline();
  }

  // Decodes transparent PNG assets asynchronously into raw bit buffers before canvas execution
  Future<void> _loadProfessionalAssets() async {
    try {
      _loadedNath = await _loadAssetImage('assets/jewelry/bridal_nath.png');
      _loadedTeeka = await _loadAssetImage('assets/jewelry/forehead_teeka.png');
      _loadedMehndi = await _loadAssetImage('assets/mehndi/bridal_bindi.png');
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error loading transparent PNG assets: $e");
    }
  }

  Future<ui.Image> _loadAssetImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) => completer.complete(img));
    return completer.future;
  }

  Future<void> _initializePipeline() async {
    final status = await Permission.camera.request();
    if (status.isDenied) return;

    // CRITICAL CORE PIPELINE FIX: Unlocks detailed path contours for advanced makeup overlays
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,     // Unlocks eyebrows, lip details, and upper eyelid limits
        enableLandmarks: true,    // Unlocks cheeks and nose bridge tracking points
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.front);

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      await _cameraController!.startImageStream((CameraImage image) {
        _processImageFrame(image, frontCamera);
      });

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint("Camera initialization exception: $e");
    }
  }

  void _processImageFrame(CameraImage image, CameraDescription camera) async {
    if (_isBusy) return;

    // Performance Optimization Throttle: Processes every alternate frame to protect hardware resources
    _frameSkipCounter++;
    if (_frameSkipCounter % 2 != 0) return;

    _isBusy = true;
    final stopwatch = Stopwatch()..start();

    try {
      final BytesBuilder bytesBuilder = BytesBuilder();
      for (final Plane plane in image.planes) {
        bytesBuilder.add(plane.bytes);
      }
      final Uint8List bytes = bytesBuilder.takeBytes();

      final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) 
          ?? InputImageRotation.rotation0deg; 
      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.group.index) 
          ?? InputImageFormat.nv21;

      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
      final faces = await _faceDetector.processImage(inputImage);

      stopwatch.stop();
      debugPrint("AI Core Frame Processing Speed: ${stopwatch.elapsedMilliseconds}ms");

      if (mounted) {
        setState(() => _detectedFaces = faces);
      }
    } catch (e) {
      debugPrint("Frame pipeline processing error: $e");
    } finally {
      _isBusy = false;
    }
  }

  double _getCurrentOpacityValue() {
    switch (_selectedCategory) {
      case 'Lipstick': return _currentConfig.lipstickOpacity;
      case 'Blush': return _currentConfig.blushOpacity;
      case 'Eyeshadow': return _currentConfig.eyeshadowOpacity;
      case 'Eyeliner': return _currentConfig.eyelinerOpacity;
      case 'Contour': return _currentConfig.contourOpacity;
      case 'Jewelry': return _currentConfig.jewelryOpacity;
      case 'Mehndi': return _currentConfig.mehndiOpacity;
      default: return 0.5;
    }
  }

  void _updateCurrentOpacityValue(double value) {
    setState(() {
      switch (_selectedCategory) {
        case 'Lipstick': _currentConfig.lipstickOpacity = value; break;
        case 'Blush': _currentConfig.blushOpacity = value; break;
        case 'Eyeshadow': _currentConfig.eyeshadowOpacity = value; break;
        case 'Eyeliner': _currentConfig.eyelinerOpacity = value; break;
        case 'Contour': _currentConfig.contourOpacity = value; break;
        case 'Jewelry': _currentConfig.jewelryOpacity = value; break;
        case 'Mehndi': _currentConfig.mehndiOpacity = value; break;
      }
    });
  }

  void _updateCurrentColorValue(Color color) {
    setState(() {
      switch (_selectedCategory) {
        case 'Lipstick': _currentConfig.lipstickColor = color; break;
        case 'Blush': _currentConfig.blushColor = color; break;
        case 'Eyeshadow': _currentConfig.eyeshadowColor = color; break;
        case 'Eyeliner': _currentConfig.eyelinerColor = color; break;
        case 'Contour': _currentConfig.contourColor = color; break;
        case 'Jewelry': _currentConfig.jewelryColor = color; break;
        case 'Mehndi': _currentConfig.mehndiColor = color; break;
      }
    });
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD91A5B))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Bridal AI Makeover Suite', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 1. Live Camera Preview Layer
          Positioned.fill(child: CameraPreview(_cameraController!)),
          
          // 2. Real-Time Drawing Overlay Canvas Core Engine
          if (_detectedFaces.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: MakeupPainter(
                  faces: _detectedFaces,
                  config: _currentConfig,
                  absoluteImageSize: _cameraController!.value.previewSize!,
                  rotation: _cameraController!.description.sensorOrientation,
                  nathImage: _loadedNath,
                  teekaImage: _loadedTeeka,
                  mehndiImage: _loadedMehndi,
                ),
              ),
            ),

          // 3. Screen Snap Utility Action Button
          Positioned(
            top: kToolbarHeight + 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFFD91A5B),
              mini: true,
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              onPressed: () async {
                try {
                  final XFile capturedImageFile = await _cameraController!.takePicture();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Look saved successfully! ${capturedImageFile.name}'),
                        backgroundColor: const Color(0xFF4A2C00),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Error capturing frame snapshot: $e");
                }
              },
            ),
          ),

          // 4. Floating User Customization Control Panel Board
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Horizontal Category Choice Filter Bar
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _colorPalettes.keys.map((cat) {
                        final isSel = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(cat, style: TextStyle(color: isSel ? Colors.white : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                            selected: isSel,
                            selectedColor: const Color(0xFFD91A5B),
                            backgroundColor: Colors.grey.shade900,
                            onSelected: (_) => setState(() => _selectedCategory = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Color Circle Grid Selection Module Row
                  SizedBox(
                    height: 46,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colorPalettes[_selectedCategory]!.length,
                      itemBuilder: (context, idx) {
                        final color = _colorPalettes[_selectedCategory]![idx];
                        
                        bool isActive = false;
                        switch (_selectedCategory) {
                          case 'Lipstick': isActive = _currentConfig.lipstickColor == color; break;
                          case 'Blush': isActive = _currentConfig.blushColor == color; break;
                          case 'Eyeshadow': isActive = _currentConfig.eyeshadowColor == color; break;
                          case 'Eyeliner': isActive = _currentConfig.eyelinerColor == color; break;
                          case 'Contour': isActive = _currentConfig.contourColor == color; break;
                          case 'Jewelry': isActive = _currentConfig.jewelryColor == color; break;
                          case 'Mehndi': isActive = _currentConfig.mehndiColor == color; break;
                        }

                        return GestureDetector(
                          onTap: () => _updateCurrentColorValue(color),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color == Colors.transparent ? Colors.grey.shade800 : color,
                              border: Border.all(
                                color: isActive ? const Color(0xFFD91A5B) : Colors.white, 
                                width: isActive ? 3.5 : 1.5
                              ),
                            ),
                            child: color == Colors.transparent ? const Icon(Icons.block, color: Colors.white30, size: 18) : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Alpha Opacity Slider Field
                  Row(
                    children: [
                      const Icon(Icons.blur_on, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: _getCurrentOpacityValue(),
                          activeColor: const Color(0xFFD91A5B),
                          inactiveColor: Colors.grey.shade800,
                          onChanged: (val) => _updateCurrentOpacityValue(val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
