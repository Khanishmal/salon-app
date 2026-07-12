// lib/customer/ar_mehndi_screen.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ar_face_engine.dart';

class ArMehndiScreen extends StatefulWidget {
  const ArMehndiScreen({super.key});

  @override
  State<ArMehndiScreen> createState() => _ArMehndiScreenState();
}

class _ArMehndiScreenState extends State<ArMehndiScreen>
    with WidgetsBindingObserver {
  final _engine = ArFaceEngine();
  bool _cameraReady = false;
  ArFaceData? _faceData;
  final _previewKey = GlobalKey();
  bool _capturing = false;
  int _selectedPattern = 0;
  double _intensity = 0.85;
  bool _photoMode = false;
  File? _uploadedImage;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _hennaPatterns = [
    {'name': 'Bridal Mandala', 'color': const Color(0xFF4A2C00), 'style': 'Traditional'},
    {'name': 'Arabic Floral', 'color': const Color(0xFF6E3A07), 'style': 'Arabic'},
    {'name': 'Pakistani', 'color': const Color(0xFF2B1900), 'style': 'Pakistani'},
    {'name': 'Finger Design', 'color': const Color(0xFF5C2C16), 'style': 'Finger'},
    {'name': 'Back Hand', 'color': const Color(0xFF3D1E00), 'style': 'Back Hand'},
    {'name': 'Full Hand', 'color': const Color(0xFF1A0A00), 'style': 'Full'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _start() async {
    await Permission.camera.request();
    _engine.onCameraReady = (v) => setState(() => _cameraReady = v);
    _engine.onFace = (d) {
      if (mounted) setState(() => _faceData = d);
    };
    await _engine.init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) _engine.stopStream();
    if (state == AppLifecycleState.resumed) _engine.startStream();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      await _engine.stopStream();
      await Future.delayed(const Duration(milliseconds: 80));
      final rb = _previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (rb == null) return;
      final img = await rb.toImage(pixelRatio: 3.0);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      final dir = Directory('/storage/emulated/0/DCIM/SalonAR');
      await dir.create(recursive: true);
      final f = File('${dir.path}/mehndi_${DateTime.now().millisecondsSinceEpoch}.png');
      await f.writeAsBytes(data.buffer.asUint8List());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Mehndi design saved!'),
            backgroundColor: Color(0xFF4A2C00),
          ),
        );
      }
    } finally {
      await _engine.startStream();
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _uploadedImage = File(image.path);
        _photoMode = true;
      });
    }
  }

  Future<void> _applyAIMehndi() async {
    if (_uploadedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a hand photo first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final bytes = await _uploadedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final pattern = _hennaPatterns[_selectedPattern];
      
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=YOUR_API_KEY'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''
Apply a beautiful mehndi design to this hand photo.
Design style: ${pattern['style']}
Design name: ${pattern['name']}
Color: ${pattern['color'].toString()}
Intensity: ${(_intensity * 100).toStringAsFixed(0)}%

Make the mehndi look realistic and natural on the hand.
'''
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Mehndi applied successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to apply mehndi');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_cameraReady) _buildCameraView() else _buildLoader(),
          _buildControls(),
          _buildTopBar(),
        ],
      ),
    );
  }

  Widget _buildLoader() => Container(
    color: const Color(0xFF0E0A14),
    child: const Center(
      child: CircularProgressIndicator(color: Color(0xFF8B4513)),
    ),
  );

  Widget _buildCameraView() {
    return RepaintBoundary(
      key: _previewKey,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0),
            child: CameraPreview(_engine.controller!),
          ),
          if (_faceData != null)
            LayoutBuilder(
              builder: (_, box) => CustomPaint(
                size: box.biggest,
                painter: MehndiPainter(
                  face: _faceData!.face,
                  imageSize: _faceData!.imageSize,
                  rotation: _faceData!.rotation,
                  pattern: _hennaPatterns[_selectedPattern],
                  intensity: _intensity,
                ),
              ),
            ),
          if (_faceData == null)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Show your hand or face',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: Row(
              children: [
                _iconBtn(Icons.arrow_back_ios_rounded, () => Navigator.pop(context)),
                const SizedBox(width: 10),
                Text(
                  'Mehndi Try-On',
                  style: GoogleFonts.cormorantGaramond(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _iconBtn(Icons.photo_rounded, _uploadPhoto),
                const SizedBox(width: 8),
                _iconBtn(
                  _capturing ? Icons.hourglass_top : Icons.camera_alt_rounded,
                  _capture,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        color: const Color(0xFF1A0A00),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pattern selector
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _hennaPatterns.length,
                itemBuilder: (context, index) {
                  final pattern = _hennaPatterns[index];
                  final isSelected = _selectedPattern == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPattern = index),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF8B4513).withOpacity(0.2) 
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF8B4513) : Colors.white24,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 35, 
                            height: 35,
                            decoration: BoxDecoration(
                              color: pattern['color'],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pattern['name'],
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF8B4513) : Colors.white70,
                              fontSize: 9,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            
            // Intensity slider
            Row(
              children: [
                const Icon(Icons.opacity, color: Color(0xFF8B4513)),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _intensity,
                    min: 0.3,
                    max: 1.0,
                    activeColor: const Color(0xFF8B4513),
                    inactiveColor: Colors.white24,
                    onChanged: (v) => setState(() => _intensity = v),
                  ),
                ),
                Text(
                  '${(_intensity * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            
            // AI Apply button (for photo mode)
            if (_photoMode && _uploadedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _applyAIMehndi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4513),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Apply AI Mehndi ✨',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: Colors.black38, 
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

// =============================================================================
// MEHNDI PAINTER
// =============================================================================

class MehndiPainter extends CustomPainter {
  final Face face;
  final Size imageSize;
  final InputImageRotation rotation;
  final Map<String, dynamic> pattern;
  final double intensity;

  const MehndiPainter({
    required this.face,
    required this.imageSize,
    required this.rotation,
    required this.pattern,
    required this.intensity,
  });

  Offset _toCanvas(math.Point<int> pt, Size cs) {
    double x = pt.x.toDouble(), y = pt.y.toDouble();
    final iw = imageSize.width, ih = imageSize.height;
    double rx, ry;
    switch (rotation) {
      case InputImageRotation.rotation0deg:   rx = x; ry = y;
      case InputImageRotation.rotation90deg:  rx = ih - y; ry = x;
      case InputImageRotation.rotation180deg: rx = iw - x; ry = ih - y;
      case InputImageRotation.rotation270deg: rx = y; ry = iw - x;
    }
    final lw = (rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg) ? ih : iw;
    final lh = (rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg) ? iw : ih;
    return Offset(cs.width - rx / lw * cs.width, ry / lh * cs.height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final facePoints = face.contours[FaceContourType.face]?.points ?? [];
    if (facePoints.isEmpty) return;

    final bounds = _bbox(facePoints.map((p) => _toCanvas(p, size)).toList());
    final center = Offset(bounds.center.dx, bounds.top + bounds.height * 0.2);
    final radius = bounds.width * 0.28;
    final color = (pattern['color'] as Color).withOpacity(intensity);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Draw mandala-style henna pattern
    for (int i = 0; i < 12; i++) {
      final angle = i * 2 * math.pi / 12;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawLine(center, point, paint);
    }

    // Circles
    canvas.drawCircle(center, radius / 2, paint);
    canvas.drawCircle(center, radius / 3, paint);

    // Dots
    final fillPaint = Paint()..color = color;
    for (int i = 0; i < 24; i++) {
      final angle = i * 2 * math.pi / 24;
      final point = Offset(
        center.dx + math.cos(angle) * (radius * 0.65),
        center.dy + math.sin(angle) * (radius * 0.65),
      );
      canvas.drawCircle(point, 2, fillPaint);
    }

    // Forehead border
    final foreheadPath = Path()
      ..moveTo(bounds.left + bounds.width * 0.15, bounds.top + bounds.height * 0.05)
      ..quadraticBezierTo(
        bounds.center.dx, 
        bounds.top - bounds.height * 0.02,
        bounds.right - bounds.width * 0.15, 
        bounds.top + bounds.height * 0.05
      );
    canvas.drawPath(foreheadPath, paint..strokeWidth = 2.0);

    // Decorative side patterns
    final leftSide = Path()
      ..moveTo(bounds.left + bounds.width * 0.1, bounds.top + bounds.height * 0.2)
      ..quadraticBezierTo(
        bounds.left - bounds.width * 0.05,
        bounds.top + bounds.height * 0.35,
        bounds.left + bounds.width * 0.1,
        bounds.top + bounds.height * 0.5,
      );
    canvas.drawPath(leftSide, paint..strokeWidth = 1.5);

    final rightSide = Path()
      ..moveTo(bounds.right - bounds.width * 0.1, bounds.top + bounds.height * 0.2)
      ..quadraticBezierTo(
        bounds.right + bounds.width * 0.05,
        bounds.top + bounds.height * 0.35,
        bounds.right - bounds.width * 0.1,
        bounds.top + bounds.height * 0.5,
      );
    canvas.drawPath(rightSide, paint..strokeWidth = 1.5);

    // Pattern-specific details
    if (pattern['style'] == 'Traditional' || pattern['style'] == 'Pakistani') {
      // Additional traditional elements
      for (int i = 0; i < 6; i++) {
        final angle = i * 2 * math.pi / 6 + math.pi / 6;
        final petal = Offset(
          center.dx + (radius * 0.45) * math.cos(angle),
          center.dy + (radius * 0.45) * math.sin(angle),
        );
        canvas.drawCircle(petal, radius * 0.06, fillPaint);
      }
    }

    if (pattern['style'] == 'Arabic') {
      // Arabic-style floral elements
      for (int i = 0; i < 8; i++) {
        final angle = i * 2 * math.pi / 8;
        final floral = Offset(
          center.dx + (radius * 0.35) * math.cos(angle),
          center.dy + (radius * 0.35) * math.sin(angle),
        );
        canvas.drawCircle(floral, radius * 0.04, fillPaint);
        // Small petals
        for (int j = 0; j < 3; j++) {
          final a = angle + j * 2 * math.pi / 3;
          canvas.drawCircle(
            Offset(
              floral.dx + radius * 0.06 * math.cos(a),
              floral.dy + radius * 0.06 * math.sin(a),
            ),
            radius * 0.02,
            fillPaint,
          );
        }
      }
    }
  }

  Rect _bbox(List<Offset> pts) {
    if (pts.isEmpty) return Rect.zero;
    double x0 = double.infinity, y0 = double.infinity;
    double x1 = double.negativeInfinity, y1 = double.negativeInfinity;
    for (final p in pts) {
      if (p.dx < x0) x0 = p.dx; if (p.dy < y0) y0 = p.dy;
      if (p.dx > x1) x1 = p.dx; if (p.dy > y1) y1 = p.dy;
    }
    return Rect.fromLTRB(x0, y0, x1, y1);
  }

  @override
  bool shouldRepaint(covariant MehndiPainter old) => true;
}