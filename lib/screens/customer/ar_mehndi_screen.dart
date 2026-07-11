// lib/screens/customer/ar_mehndi_screen.dart
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

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

  final List<Map<String, dynamic>> _hennaPatterns = [
    {'name': 'Bridal Mandala', 'color': const Color(0xFF4A2C00), 'style': 'Traditional'},
    {'name': 'Arabic Floral', 'color': const Color(0xFF6E3A07), 'style': 'Arabic'},
    {'name': 'Pakistani', 'color': const Color(0xFF2B1900), 'style': 'Pakistani'},
    {'name': 'Finger Design', 'color': const Color(0xFF5C2C16), 'style': 'Finger'},
    {'name': 'Back Hand', 'color': const Color(0xFF3D1E00), 'style': 'Back Hand'},
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
          const SnackBar(content: Text('📸 Mehndi design saved!'),
              backgroundColor: Color(0xFF4A2C00)),
        );
      }
    } finally {
      await _engine.startStream();
      if (mounted) setState(() => _capturing = false);
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
                child: const Text('Align face in frame',
                    style: TextStyle(color: Colors.white60)),
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
                Text('Mehndi Try-On',
                    style: GoogleFonts.cormorantGaramond(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                const Spacer(),
                _iconBtn(_capturing ? Icons.hourglass_top : Icons.camera_alt_rounded, _capture),
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
                        color: isSelected ? const Color(0xFF8B4513).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? const Color(0xFF8B4513) : Colors.white24),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: pattern['color'],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(pattern['name'],
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF8B4513) : Colors.white70,
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            
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
                Text('${(_intensity * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white70)),
              ],
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
        color: Colors.black38, shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

// Mehndi Painter
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
      ..quadraticBezierTo(bounds.center.dx, bounds.top - bounds.height * 0.02,
          bounds.right - bounds.width * 0.15, bounds.top + bounds.height * 0.05);
    canvas.drawPath(foreheadPath, paint..strokeWidth = 2.0);
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