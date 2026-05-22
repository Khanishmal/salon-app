import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../painters/makeup_painter.dart';

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

  // Customization Layer States
  String _selectedCategory = 'Lipstick';
  Color _lipstickColor = const Color(0xFFD91A5B);
  double _lipstickOpacity = 0.5;
  Color _blushColor = const Color(0xFFFFB6C1);
  double _blushOpacity = 0.3;

  // Professional Bridal Makeup Color Palettes
  final Map<String, List<Color>> _colorPalettes = {
    'Lipstick': [
      Colors.transparent, 
      const Color(0xFFD91A5B), // Classic Rose
      const Color(0xFF8C0327), // Crimson Maroon
      const Color(0xFFE65C7B), // Pastel Pink
      const Color(0xFF590219), // Deep Burgundy
    ],
    'Blush': [
      Colors.transparent, 
      const Color(0xFFFFB6C1), // Light Coral
      const Color(0xFFFA8072), // Salmon Glow
      const Color(0xFFE9967A), // Peach Blush
      const Color(0xFFFF69B4), // Hot Pink Tint
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializePipeline();
  }

  Future<void> _initializePipeline() async {
    // Safely request hardware layer permissions before camera init
    final status = await Permission.camera.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera access is required for AI Try-On.')),
        );
      }
      return;
    }

    // Configure the Google ML Kit Face Detector with contours explicitly enabled
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      
      // Start real-time image analysis stream processing loops
      await _cameraController!.startImageStream((CameraImage image) {
        _processImageFrame(image, frontCamera);
      });

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint("Camera hardware initialization fault: $e");
    }
  }

  void _processImageFrame(CameraImage image, CameraDescription camera) async {
    // Prevent pipeline backpressure bottlenecks
    if (_isBusy || _faceDetector == null) return;
    _isBusy = true;

    try {
      // High-performance direct byte accumulation loop 
      final BytesBuilder bytesBuilder = BytesBuilder();
      for (final Plane plane in image.planes) {
        bytesBuilder.add(plane.bytes);
      }
      final Uint8List bytes = bytesBuilder.takeBytes();

      // Explicitly handle ML Kit's rotation mapping requirements 
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

      if (mounted) {
        setState(() {
          _detectedFaces = faces;
        });
      }
    } catch (e) {
      debugPrint("ML Kit pipeline analysis error: $e");
    } finally {
      _isBusy = false;
    }
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
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD91A5B)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Bridal AI Try-On', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // 1. Camera Real-time Viewfinder Viewport Layout
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          ),
          
          // 2. Custom Paint Layer (Maps ML Kit Contours dynamically onto Canvas)
          if (_detectedFaces.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: MakeupPainter(
                  faces: _detectedFaces,
                  lipstickColor: _lipstickColor,
                  lipstickOpacity: _lipstickOpacity,
                  blushColor: _blushColor,
                  blushOpacity: _blushOpacity,
                  absoluteImageSize: _cameraController!.value.previewSize!,
                  rotation: _cameraController!.description.sensorOrientation,
                ),
              ),
            ),
            
          // 3. Choice Options Interface Overlay Control Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24), 
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category Selection Chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['Lipstick', 'Blush'].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(
                          cat, 
                          style: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFFD91A5B),
                        backgroundColor: Colors.grey.shade900,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  
                  // Horizontal Color Palette Swatches Selection Loop
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colorPalettes[_selectedCategory]!.length,
                      itemBuilder: (context, idx) {
                        final color = _colorPalettes[_selectedCategory]![idx];
                        final isCurrentColor = _selectedCategory == 'Lipstick' 
                            ? _lipstickColor == color 
                            : _blushColor == color;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_selectedCategory == 'Lipstick') _lipstickColor = color;
                              if (_selectedCategory == 'Blush') _blushColor = color;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color == Colors.transparent ? Colors.grey.shade800 : color,
                              border: Border.all(
                                color: isCurrentColor ? const Color(0xFFD91A5B) : Colors.white, 
                                width: isCurrentColor ? 3 : 1.5,
                              ),
                            ),
                            child: color == Colors.transparent
                                ? const Icon(Icons.block, color: Colors.white54, size: 22)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Alpha Layer Opacity Blend Slider Control
                  Row(
                    children: [
                      const Icon(Icons.opacity, color: Colors.white70),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Slider(
                          value: _selectedCategory == 'Lipstick' ? _lipstickOpacity : _blushOpacity,
                          min: 0.0,
                          max: 1.0,
                          activeColor: const Color(0xFFD91A5B),
                          inactiveColor: Colors.grey.shade800,
                          onChanged: (val) {
                            setState(() {
                              if (_selectedCategory == 'Lipstick') {
                                _lipstickOpacity = val;
                              } else {
                                _blushOpacity = val;
                              }
                            });
                          },
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