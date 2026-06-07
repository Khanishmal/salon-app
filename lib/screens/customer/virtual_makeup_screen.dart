// lib/screens/customer/virtual_makeup_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Make sure to add http to pubspec.yaml
import '../../models/makeup_configuration.dart';
import '../../painters/makeup_painter.dart';

class VirtualMakeupScreen extends StatefulWidget {
  final String initialCategory;
  const VirtualMakeupScreen({super.key, this.initialCategory = 'Lipstick'});

  @override
  State<VirtualMakeupScreen> createState() => _VirtualMakeupScreenState();
}

class _VirtualMakeupScreenState extends State<VirtualMakeupScreen> {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  bool _isBusy = false;
  List<Face> _detectedFaces = [];
  bool _isInitialized = false;
  late String _selectedCategory;
  
  File? _uploadedImage;
  bool _isProcessingAI = false;
  final ImagePicker _picker = ImagePicker();
  late MakeupConfiguration _currentConfig;

  // Professional Global Cosmetics Palette Swatches
  final Map<String, List<Color>> _professionalPalettes = {
    'Foundation': [
      Colors.transparent,
      const Color(0xFFF3E1D3), // Porcelain Light
      const Color(0xFFE8CBB5), // Classic Ivory
      const Color(0xFFD9B69B), // Natural Beige
      const Color(0xFFC79B79), // Warm Honey
      const Color(0xFFA6714B), // Deep Espresso
    ],
    'Contour': [
      Colors.transparent,
      const Color(0xFF9E7963), // Light Taupe Shadow
      const Color(0xFF7D5843), // Medium Umber Contour
      const Color(0xFF5C3C2B), // Deep Walnut sculpt
    ],
    'Lipstick': [
      Colors.transparent,
      const Color(0xFFB33939), // Velvet Matte Crimson
      const Color(0xFFE05252), // High-Shine Coral Rose
      const Color(0xFF832E40), // Deep Plum Satin
      const Color(0xFFD47A6F), // Dusty Nude Pink
    ],
    'Blush': [
      Colors.transparent,
      const Color(0xFFFFB6C1), // Pastel Peony
      const Color(0xFFF4A261), // Sunkissed Peach
      const Color(0xFFE76F51), // Spicy Coral
    ],
    'Eyeshadow': [
      Colors.transparent,
      const Color(0xFFD4AF37), // Metallic Champagne Gold
      const Color(0xFF6B4226), // Earthy Matte Auburn
      const Color(0xFF5E3A60), // Velvet Amethyst
    ]
  };

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _currentConfig = MakeupConfiguration();
    _initializePipeline();
  }

  Future<void> _initializePipeline() async {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final frontCamera = cameras.firstWhere((cam) => cam.lensDirection == CameraLensDirection.front);
      
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high, // Ensures accurate vector path resolutions
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.yuv420 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      _cameraController!.startImageStream((CameraImage image) {
        if (_isBusy || _uploadedImage != null) return;
        _isBusy = true;
        _processFrame(image, frontCamera);
      });

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _isInitialized = true);
    }
  }

  void _processFrame(CameraImage image, CameraDescription camera) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final Uint8List bytes = allBytes.done().buffer.asUint8List();

      final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.group.index) ?? InputImageFormat.nv21;

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
      final faces = await _faceDetector.processImage(inputImage);
      
      if (mounted && _uploadedImage == null) {
        setState(() => _detectedFaces = faces);
      }
    } catch (e) {
      debugPrint("Frame processing pass: $e");
    } finally {
      _isBusy = false;
    }
  }

  // =========================================================================
  // CORE INTELLIGENT AI ENGINE DISPATCH LAYER (INTEGRATION POINT)
  // =========================================================================
  Future<void> _runIntelligentLookRecommendation(File imageFile) async {
    setState(() => _isProcessingAI = true);

    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // PLACE YOUR SUITE ACCESS TOKEN KEY HERE SECURELY
      const String gatewayKey = "YOUR_SECURE_GENERATIVE_API_KEY"; 
      const String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$gatewayKey";

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": "Analyze this user's facial undertone and facial structures from the image. "
                          "Return a clean JSON object containing HEX codes for matching makeup types. "
                          "Strictly follow this JSON scheme structure and do not output any markdown wrapper text: "
                          "{\"foundation\": \"#HEX\", \"lipstick\": \"#HEX\", \"blush\": \"#HEX\", \"contour\": \"#HEX\"}"
                },
                {
                  "inlineData": {
                    "mimeType": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String rawText = data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
        
        // Sanitize any occasional markdown codeblock wrappers in the raw response
        final sanitizedJson = rawText.replaceAll("```json", "").replaceAll("```", "").trim();
        final Map<String, dynamic> colorMap = jsonDecode(sanitizedJson);

        Color parseHex(String hexStr) {
          final hex = hexStr.replaceAll("#", "");
          return Color(int.parse("FF$hex", radix: 16));
        }

        setState(() {
          _currentConfig.foundationColor = parseHex(colorMap['foundation']);
          _currentConfig.lipstickColor = parseHex(colorMap['lipstick']);
          _currentConfig.blushColor = parseHex(colorMap['blush']);
          _currentConfig.contourColor = parseHex(colorMap['contour']);
        });
      }
    } catch (e) {
      debugPrint("Generative Network pipeline fault: $e");
    } finally {
      setState(() => _isProcessingAI = false);
    }
  }

  Future<void> _handleLiveCaptureAndAutoRecommend() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    try {
      final XFile capturedFile = await _cameraController!.takePicture();
      await _runIntelligentLookRecommendation(File(capturedFile.path));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Consultation Complete: Smart Makeover mapped perfectly!')),
      );
    } catch (e) {
      debugPrint("Live stream capture failed: $e");
    }
  }

  Future<void> _handlePhotoUploadWorkflow() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    setState(() {
      _uploadedImage = file;
    });

    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }

    // Read face contours for the static uploaded image
    final inputImage = InputImage.fromFile(file);
    final faces = await _faceDetector.processImage(inputImage);
    setState(() => _detectedFaces = faces);

    // Prompt user choice or execute automated application automatically
    _showAIPromptDialog(file);
  }

  void _showAIPromptDialog(File file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text("Studio Selection", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("Would you like our AI Engine to completely auto-apply a personalized look, or tweak the palettes yourself?", style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _runIntelligentLookRecommendation(file);
            },
            child: const Text("AI Auto-Apply", style: TextStyle(color: Color(0xFFF2845C))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Manual Application", style: TextStyle(color: Colors.white54)),
          )
        ],
      ),
    );
  }

  void _clearPhotoAndRestoreLiveStream() {
    setState(() {
      _uploadedImage = null;
      _detectedFaces.clear();
      _currentConfig = MakeupConfiguration();
    });
    _initializePipeline();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Base View Render Layer
          Positioned.fill(
            child: _uploadedImage != null
                ? Image.file(_uploadedImage!, fit: BoxFit.cover)
                : (_cameraController != null && _cameraController!.value.isInitialized
                    ? CameraPreview(_cameraController!)
                    : const Center(child: CircularProgressIndicator(color: Color(0xFFF2845C)))),
          ),

          // High-Precision Real-Time Painting Vector Layer
          if (_detectedFaces.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: MakeupPainter(
                  faces: _detectedFaces,
                  config: _currentConfig,
                  absoluteImageSize: _uploadedImage != null ? const Size(1080, 1920) : _cameraController!.value.previewSize!,
                  rotation: _uploadedImage != null ? 0 : _cameraController!.description.sensorOrientation,
                ),
              ),
            ),

          // Return to Live Stream View Pin Action Button
          if (_uploadedImage != null)
            Positioned(
              top: 50,
              left: 16,
              child: FloatingActionButton.small(
                backgroundColor: Colors.black.withOpacity(0.7),
                onPressed: _clearPhotoAndRestoreLiveStream,
                child: const Icon(Icons.videocam_rounded, color: Colors.white),
              ),
            ),

          // Studio Processing Modal Overlay Frame
          if (_isProcessingAI)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFF2845C)),
                    const SizedBox(height: 18),
                    Text("AI Consulting Engine parsing facial metrics...", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),

          // Glassmorphic Selector Sliding Container Panel Mesh
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 22, left: 18, right: 18, bottom: 28),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1F).withOpacity(0.94),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Categories Selector Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _professionalPalettes.keys.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: const Color(0xFFF2845C),
                            backgroundColor: Colors.white.withOpacity(0.05),
                            labelStyle: GoogleFonts.poppins(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            onSelected: (val) => setState(() => _selectedCategory = cat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Shader Swatch Grid Loops Selection
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _professionalPalettes[_selectedCategory]!.length,
                      itemBuilder: (context, idx) {
                        final color = _professionalPalettes[_selectedCategory]![idx];
                        bool isSelectedColor = false;
                        
                        if (_selectedCategory == 'Lipstick') isSelectedColor = _currentConfig.lipstickColor == color;
                        if (_selectedCategory == 'Foundation') isSelectedColor = _currentConfig.foundationColor == color;
                        if (_selectedCategory == 'Contour') isSelectedColor = _currentConfig.contourColor == color;
                        if (_selectedCategory == 'Blush') isSelectedColor = _currentConfig.blushColor == color;
                        if (_selectedCategory == 'Eyeshadow') isSelectedColor = _currentConfig.eyeshadowColor == color;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_selectedCategory == 'Lipstick') _currentConfig.lipstickColor = color;
                              if (_selectedCategory == 'Foundation') _currentConfig.foundationColor = color;
                              if (_selectedCategory == 'Contour') _currentConfig.contourColor = color;
                              if (_selectedCategory == 'Blush') _currentConfig.blushColor = color;
                              if (_selectedCategory == 'Eyeshadow') _currentConfig.eyeshadowColor = color;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color == Colors.transparent ? Colors.grey[900] : color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelectedColor ? const Color(0xFFF2845C) : Colors.white24,
                                width: isSelectedColor ? 3 : 1,
                              ),
                            ),
                            child: color == Colors.transparent ? const Icon(Icons.block, color: Colors.white38, size: 18) : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Bottom Action Grid Control Bars
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _handleLiveCaptureAndAutoRecommend,
                          icon: const Icon(Icons.auto_awesome, color: Colors.white),
                          label: const Text("AI Live Recommend"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF2845C),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handlePhotoUploadWorkflow,
                          icon: const Icon(Icons.photo_library, color: Colors.white),
                          label: const Text("Upload Photo", style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
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

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }
}