//lib/customer/ar_jewelry_screen.dart

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'ar_face_engine.dart';

class ArJewelryScreen extends StatefulWidget {
  const ArJewelryScreen({super.key});

  @override
  State<ArJewelryScreen> createState() => _ArJewelryScreenState();
}

class _ArJewelryScreenState extends State<ArJewelryScreen> with WidgetsBindingObserver {
  late ArFaceEngine _engine;
  bool _cameraReady = false;
  ArFaceData? _faceData;
  final _previewKey = GlobalKey();
  bool _capturing = false;
  String? _error;

  // Jewelry state
  bool _showTikka = true;
  bool _showNath = true;
  bool _showNecklace = false;
  bool _showEarrings = false;

  // Jewelry colors (metal finishes)
  Color _jewelryColor = const Color(0xFFFFD700); // Gold

  final List<(Color, String)> _metalColors = [
    (const Color(0xFFFFD700), 'Gold'),
    (const Color(0xFFC0C0C0), 'Silver'),
    (const Color(0xFFE8C07A), 'Rose Gold'),
    (const Color(0xFFFFC0CB), 'Pink Gold'),
    (const Color(0xFFCD7F32), 'Bronze'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = ArFaceEngine();
    _initialize();
  }

  Future<void> _initialize() async {
    _engine.onCameraReady = (ready) {
      if (mounted) setState(() => _cameraReady = ready);
    };

    _engine.onFace = (data) {
      if (mounted && data != null) {
        setState(() => _faceData = data);
      }
    };

    _engine.onError = (error) {
      if (mounted) {
        setState(() => _error = error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    };

    final success = await _engine.init(
      enableContours: true,
      enableLandmarks: true,
      enableTracking: true,
    );

    if (!success && mounted) {
      setState(() => _error = 'Failed to initialize camera');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _engine.stopStream();
    } else if (state == AppLifecycleState.resumed) {
      _engine.startStream();
    }
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
      await Future.delayed(const Duration(milliseconds: 100));

      final rb = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (rb == null) return;

      final image = await rb.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;

      final dir = Directory('/storage/emulated/0/DCIM/SalonAR');
      await dir.create(recursive: true);

      final file = File('${dir.path}/jewelry_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(data.buffer.asUint8List());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Jewelry look saved!'),
            backgroundColor: Color(0xFF7A5A00),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
      body: _error != null
          ? _buildErrorState()
          : Stack(
              children: [
                if (_cameraReady) _buildCameraView() else _buildLoader(),
                _buildControls(),
                _buildTopBar(),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_error ?? 'Unknown error',
              style: GoogleFonts.poppins(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() => _error = null);
              _initialize();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() => Container(
    color: const Color(0xFF0E0A14),
    child: const Center(
      child: CircularProgressIndicator(color: Color(0xFFFFD700)),
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
              builder: (_, constraints) => CustomPaint(
                size: constraints.biggest,
                painter: JewelryPainter(
                  faceData: _faceData!,
                  showTikka: _showTikka,
                  showNath: _showNath,
                  showNecklace: _showNecklace,
                  showEarrings: _showEarrings,
                  jewelryColor: _jewelryColor,
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
                _iconBtn(Icons.arrow_back_ios_rounded, () => Navigator.pop(context)),
                const SizedBox(width: 10),
                Text(
                  'Bridal Jewelry',
                  style: GoogleFonts.cormorantGaramond(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
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
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: const Color(0xFF1A1000),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Jewelry toggles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _toggleChip('Tikka', _showTikka, () => setState(() => _showTikka = !_showTikka)),
                _toggleChip('Nath', _showNath, () => setState(() => _showNath = !_showNath)),
                _toggleChip('Necklace', _showNecklace,
                    () => setState(() => _showNecklace = !_showNecklace)),
                _toggleChip('Earrings', _showEarrings,
                    () => setState(() => _showEarrings = !_showEarrings)),
              ],
            ),
            const SizedBox(height: 16),

            // Metal color picker
            const Text(
              'Metal Finish',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _metalColors.length,
                itemBuilder: (context, index) {
                  final (color, name) = _metalColors[index];
                  final isSelected = _jewelryColor == color;

                  return Tooltip(
                    message: name,
                    child: GestureDetector(
                      onTap: () => setState(() => _jewelryColor = color),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white24,
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8)]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.black, size: 16)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleChip(String label, bool isOn, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isOn ? _jewelryColor.withOpacity(0.2) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOn ? _jewelryColor : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.diamond, color: isOn ? _jewelryColor : Colors.white54, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isOn ? _jewelryColor : Colors.white54,
                fontSize: 12,
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

// ─────────────────────────────────────────────────────────────────────────
// JEWELRY PAINTER
// ─────────────────────────────────────────────────────────────────────────

class JewelryPainter extends CustomPainter {
  final ArFaceData faceData;
  final bool showTikka;
  final bool showNath;
  final bool showNecklace;
  final bool showEarrings;
  final Color jewelryColor;

  late final ArCoordTransform _transform;

  JewelryPainter({
    required this.faceData,
    required this.showTikka,
    required this.showNath,
    required this.showNecklace,
    required this.showEarrings,
    required this.jewelryColor,
  }) {
    _transform = ArCoordTransform(
      imageSize: faceData.imageSize,
      rotation: faceData.rotation,
      isFrontCamera: faceData.isFrontCamera,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final face = faceData.face;

    // Get facial landmarks
    final facePoints = _transform.toCanvasList(
      face.contours[FaceContourType.face]?.points ?? [],
      size,
    );

    final noseBridge = _transform.toCanvasList(
      face.contours[FaceContourType.noseBridge]?.points ?? [],
      size,
    );

    final leftEye = _transform.toCanvasList(
      face.contours[FaceContourType.leftEye]?.points ?? [],
      size,
    );

    final rightEye = _transform.toCanvasList(
      face.contours[FaceContourType.rightEye]?.points ?? [],
      size,
    );

    if (facePoints.isEmpty) return;

    final faceBounds = ArCoordTransform.boundingBox(facePoints);
    final faceWidth = faceBounds.width;
    final faceHeight = faceBounds.height;

    // Tikka - on forehead between eyebrows
    if (showTikka) {
      Offset foreheadPoint;
      if (noseBridge.isNotEmpty) {
        foreheadPoint = noseBridge.first;
        foreheadPoint =
            Offset(foreheadPoint.dx, foreheadPoint.dy - faceHeight * 0.12);
      } else {
        foreheadPoint = Offset(
          faceBounds.center.dx,
          faceBounds.top + faceHeight * 0.15,
        );
      }

      _drawTikka(canvas, foreheadPoint, faceWidth);
    }

    // Nath - nose ring
    if (showNath) {
      Offset nosePoint = noseBridge.isNotEmpty
          ? noseBridge.last
          : Offset(faceBounds.center.dx, faceBounds.center.dy);

      _drawNath(canvas, nosePoint, faceWidth);
    }

    // Necklace - around neck area
    if (showNecklace) {
      final neckY = faceBounds.bottom + faceHeight * 0.05;
      _drawNecklace(canvas, faceBounds, neckY, faceWidth);
    }

    // Earrings - at ear positions
    if (showEarrings) {
      _drawEarrings(canvas, leftEye, rightEye, faceWidth);
    }
  }

  void _drawTikka(Canvas canvas, Offset center, double faceWidth) {
    final tikkaSize = faceWidth * 0.18;
    final paint = Paint()
      ..color = jewelryColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Main circle
    canvas.drawCircle(center, tikkaSize / 2, paint);

    // Highlight
    canvas.drawCircle(
      center,
      tikkaSize / 3,
      Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..blendMode = BlendMode.screen,
    );

    // Pendant
    final pendantPath = Path()
      ..moveTo(center.dx, center.dy + tikkaSize / 2)
      ..lineTo(center.dx - tikkaSize / 4, center.dy + tikkaSize * 0.9)
      ..lineTo(center.dx + tikkaSize / 4, center.dy + tikkaSize * 0.9)
      ..close();

    canvas.drawPath(pendantPath, paint);

    // Pendant highlight
    canvas.drawCircle(
      Offset(center.dx, center.dy + tikkaSize * 0.7),
      tikkaSize * 0.08,
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..blendMode = BlendMode.screen,
    );
  }

  void _drawNath(Canvas canvas, Offset center, double faceWidth) {
    final nathSize = faceWidth * 0.22;
    final paint = Paint()
      ..color = jewelryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = faceWidth * 0.035
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Ring
    canvas.drawCircle(center, nathSize / 2, paint);

    // Inner highlight
    canvas.drawCircle(
      center,
      nathSize / 3,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..blendMode = BlendMode.screen,
    );
  }

  void _drawNecklace(Canvas canvas, Rect faceBounds, double neckY, double faceWidth) {
    final paint = Paint()
      ..color = jewelryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = faceWidth * 0.045
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Necklace curve
    final necklacePath = Path()
      ..moveTo(faceBounds.left + faceBounds.width * 0.15, neckY)
      ..quadraticBezierTo(
        faceBounds.center.dx,
        neckY + faceBounds.height * 0.1,
        faceBounds.right - faceBounds.width * 0.15,
        neckY,
      );

    canvas.drawPath(necklacePath, paint);

    // Pendant
    final pendantSize = faceWidth * 0.06;
    canvas.drawCircle(
      Offset(faceBounds.center.dx, neckY + faceBounds.height * 0.08),
      pendantSize,
      Paint()
        ..color = jewelryColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Pendant highlight
    canvas.drawCircle(
      Offset(
        faceBounds.center.dx - pendantSize * 0.3,
        neckY + faceBounds.height * 0.06,
      ),
      pendantSize * 0.4,
      Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..blendMode = BlendMode.screen,
    );
  }

  void _drawEarrings(Canvas canvas, List<Offset> leftEye, List<Offset> rightEye, double faceWidth) {
    if (leftEye.isEmpty || rightEye.isEmpty) return;

    final earringSize = faceWidth * 0.08;

    // Get ear positions (outer edge of eyes)
    final leftEarBounds = ArCoordTransform.boundingBox(leftEye);
    final rightEarBounds = ArCoordTransform.boundingBox(rightEye);

    final leftEarPos = Offset(leftEarBounds.left - earringSize, leftEarBounds.center.dy);
    final rightEarPos = Offset(rightEarBounds.right + earringSize, rightEarBounds.center.dy);

    final paint = Paint()
      ..color = jewelryColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Left earring
    canvas.drawCircle(leftEarPos, earringSize, paint);
    canvas.drawCircle(
      Offset(leftEarPos.dx - earringSize * 0.25, leftEarPos.dy - earringSize * 0.2),
      earringSize * 0.35,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..blendMode = BlendMode.screen,
    );

    // Right earring
    canvas.drawCircle(rightEarPos, earringSize, paint);
    canvas.drawCircle(
      Offset(rightEarPos.dx + earringSize * 0.25, rightEarPos.dy - earringSize * 0.2),
      earringSize * 0.35,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..blendMode = BlendMode.screen,
    );
  }

  @override
  bool shouldRepaint(JewelryPainter old) => true;
}