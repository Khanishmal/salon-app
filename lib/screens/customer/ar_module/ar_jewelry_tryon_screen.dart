import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const Color kAccent = Color(0xFFD4AF37);
const Color kAccentLight = Color(0xFFFFD700);

class ArJewelryTryOnScreen extends StatefulWidget {
  const ArJewelryTryOnScreen({super.key});

  @override
  State<ArJewelryTryOnScreen> createState() => _ArJewelryTryOnScreenState();
}

class _ArJewelryTryOnScreenState extends State<ArJewelryTryOnScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFrontCamera = true;
  
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  Size? _cameraImageSize;
  
  final ValueNotifier<SmoothedFace> _smoothedFaceNotifier = ValueNotifier(SmoothedFace());

  Map<String, ui.Image> _jewelryImages = {};
  bool _assetsLoaded = false;
  
  String? _selectedNecklace;
  String? _selectedEarring;
  bool _showNecklaceRow = false;
  bool _showEarringRow = false;

  // UPDATED: 8 Necklace Options instead of 4
  final List<String> _necklaceOptions = [
    'neck1.png', 
    'neck2.png', 
    'neck3.png', 
    'neck4.png',
    'neck5.png', 
    'neck6.png', 
    'neck7.png', 
    'neck8.png'
  ];
  
  final List<String> _earringOptions = ['ear5.png', 'ear6.png', 'ear7.png', 'ear9.png'];
  
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isExporting = false;

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _loadJewelryAssets();
    _setupFaceDetector();
    await _setupCamera();
  }

  Future<void> _loadJewelryAssets() async {
    final allAssets = [..._necklaceOptions, ..._earringOptions];
    final Map<String, ui.Image> loadedImages = {};
    for (final asset in allAssets) {
      try {
        final data = await rootBundle.load('assets/$asset');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        loadedImages[asset] = frame.image;
      } catch (e) {
        debugPrint('Error loading asset $asset: $e');
      }
    }
    if (mounted) {
      setState(() {
        _jewelryImages = loadedImages;
        _assetsLoaded = true;
      });
    }
  }

  void _setupFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableContours: false,
        enableClassification: false,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.2,
      ),
    );
  }

  Future<void> _setupCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) return;

    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == (_isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back)
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (_cameraController!.description.sensorOrientation == 90) {
        await _cameraController!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      }
      
      await _cameraController!.startImageStream(_processCameraImage);
      if (mounted) setState(() => _isCameraInitialized = true);
      
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || !_assetsLoaded) return;
    _isDetecting = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
      _cameraImageSize = Size(
        isPortrait ? image.height.toDouble() : image.width.toDouble(),
        isPortrait ? image.width.toDouble() : image.height.toDouble(),
      );

      final faces = await _faceDetector.processImage(inputImage);
      
      final currentSmoothed = _smoothedFaceNotifier.value;
      if (faces.isNotEmpty) {
        currentSmoothed.update(faces.first);
        _smoothedFaceNotifier.value = SmoothedFace.clone(currentSmoothed);
      } else {
        currentSmoothed.reset();
        _smoothedFaceNotifier.value = SmoothedFace.clone(currentSmoothed);
      }
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;
    final sensorOrientation = _cameraController!.description.sensorOrientation;
    InputImageRotation? rotation;
    
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (_cameraController!.description.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    
    return InputImage.fromBytes(
      bytes: allBytes.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Future<void> _switchCamera() async {
    setState(() => _isFrontCamera = !_isFrontCamera);
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _smoothedFaceNotifier.value = SmoothedFace();
    await _setupCamera();
  }

  Future<void> _captureAndShareStudioLook() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    HapticFeedback.mediumImpact();

    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/bridal_studio_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '💎 My bridal jewelry look from GlowSalon Virtual Studio! ✨👑',
      );
    } catch (e) {
      debugPrint('Error capturing studio look: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _faceDetector.close();
    _smoothedFaceNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '💎 JEWELRY STUDIO',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isCameraInitialized && _cameraController != null)
            RepaintBoundary(
              key: _repaintBoundaryKey,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(_isFrontCamera ? -1.0 : 1.0, 1.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(child: CameraPreview(_cameraController!)),
                    if (_assetsLoaded && _cameraImageSize != null)
                      ValueListenableBuilder<SmoothedFace>(
                        valueListenable: _smoothedFaceNotifier,
                        builder: (context, smoothedFace, child) {
                          return Positioned.fill(
                            child: CustomPaint(
                              painter: JewelryOverlayPainter(
                                cameraSize: _cameraImageSize!,
                                jewelryImages: _jewelryImages,
                                selectedNecklace: _selectedNecklace,
                                selectedEarring: _selectedEarring,
                                smoothed: smoothedFace,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          
          Positioned(
            bottom: 0, 
            left: 0, 
            right: 0, 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCaptureButton(),
                const SizedBox(height: 16),
                _buildControlsPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _captureAndShareStudioLook,
      child: Container(
        height: 68,
        width: 68,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kAccent, kAccentLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: kAccent.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: Center(
          child: _isExporting
              ? const SizedBox(
                  height: 28, 
                  width: 28, 
                  child: CircularProgressIndicator(
                    color: Colors.white, 
                    strokeWidth: 2.5,
                  ),
                )
              : const Icon(Icons.camera_alt, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildControlsPanel() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          padding: EdgeInsets.fromLTRB(16, 20, 16, 28 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCategoryChip(
                    label: 'Earrings',
                    icon: Icons.auto_awesome,
                    isActive: _showEarringRow,
                    onTap: () => setState(() => _showEarringRow = !_showEarringRow),
                  ),
                  const SizedBox(width: 16),
                  _buildCategoryChip(
                    label: 'Necklace',
                    icon: Icons.diamond_outlined,
                    isActive: _showNecklaceRow,
                    onTap: () => setState(() => _showNecklaceRow = !_showNecklaceRow),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: Column(
                  children: [
                    if (_showEarringRow) ...[
                      const SizedBox(height: 20),
                      _buildJewelryRow('Select Earrings', _earringOptions, _selectedEarring, (v) => setState(() => _selectedEarring = v)),
                    ],
                    if (_showNecklaceRow) ...[
                      const SizedBox(height: 20),
                      _buildJewelryRow('Select Necklace', _necklaceOptions, _selectedNecklace, (v) => setState(() => _selectedNecklace = v)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({required String label, required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? kAccent : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isActive ? kAccent : Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.black : Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isActive ? Colors.black : Colors.white,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJewelryRow(String label, List<String> options, String? selected, ValueChanged<String?> onSelect) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: options.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildOptionCard(null, selected == null, () {
              HapticFeedback.selectionClick();
              onSelect(null);
            });
          }
          final option = options[index - 1];
          return _buildOptionCard(option, selected == option, () {
            HapticFeedback.selectionClick();
            onSelect(option);
          });
        },
      ),
    );
  }

  Widget _buildOptionCard(String? asset, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? kAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? kAccent : Colors.white.withOpacity(0.1), width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kAccent.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            asset == null
                ? Icon(Icons.block, color: isSelected ? kAccent : Colors.white30, size: 24)
                : Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/$asset'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
            const SizedBox(height: 2),
            if (isSelected)
              Container(
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kAccent, kAccentLight],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SMOOTHED FACE DATA MODULE
// =============================================================================
class SmoothedFace {
  Offset? leftEar;
  Offset? rightEar;
  Offset? chin;
  double? faceWidth;
  double? faceHeight;
  double? rollDeg;
  
  bool get isValid => leftEar != null && rightEar != null && chin != null;

  SmoothedFace();
  SmoothedFace.clone(SmoothedFace source) {
    leftEar = source.leftEar;
    rightEar = source.rightEar;
    chin = source.chin;
    faceWidth = source.faceWidth;
    faceHeight = source.faceHeight;
    rollDeg = source.rollDeg;
  }

  Offset _dynamicLerp(Offset? prev, Offset next) {
    if (prev == null) return next;
    final distance = (prev - next).distance;
    
    double alpha = 0.2; 
    if (distance > 30) alpha = 0.8;
    if (distance < 5) alpha = 0.1;

    return Offset(
      next.dx * alpha + prev.dx * (1 - alpha),
      next.dy * alpha + prev.dy * (1 - alpha),
    );
  }

  double _lerpD(double? prev, double next, double alpha) {
    if (prev == null) return next;
    return next * alpha + prev * (1 - alpha);
  }

  void update(Face face) {
    final box = face.boundingBox;
    final leftEarLm = face.landmarks[FaceLandmarkType.leftEar];
    final rightEarLm = face.landmarks[FaceLandmarkType.rightEar];
    
    Offset? leftEarRaw = leftEarLm != null ? Offset(leftEarLm.position.x.toDouble(), leftEarLm.position.y.toDouble()) : null;
    Offset? rightEarRaw = rightEarLm != null ? Offset(rightEarLm.position.x.toDouble(), rightEarLm.position.y.toDouble()) : null;
    
    final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];
    final chinRaw = bottomMouth != null 
        ? Offset(bottomMouth.position.x.toDouble(), bottomMouth.position.y.toDouble() + (box.height * 0.15))
        : Offset(box.left + box.width / 2, box.bottom * 0.95);

    if (leftEarRaw != null) leftEar = _dynamicLerp(leftEar, leftEarRaw);
    if (rightEarRaw != null) rightEar = _dynamicLerp(rightEar, rightEarRaw);
    chin = _dynamicLerp(chin, chinRaw);
    
    faceWidth = _lerpD(faceWidth, box.width, 0.3);
    faceHeight = _lerpD(faceHeight, box.height, 0.3);
    rollDeg = _lerpD(rollDeg, face.headEulerAngleZ ?? 0, 0.3);
  }

  void reset() {
    leftEar = null;
    rightEar = null;
    chin = null;
  }
}

// =============================================================================
// OVERLAY PAINTER
// =============================================================================
class JewelryOverlayPainter extends CustomPainter {
  final Size cameraSize;
  final Map<String, ui.Image> jewelryImages;
  final String? selectedNecklace;
  final String? selectedEarring;
  final SmoothedFace smoothed;

  JewelryOverlayPainter({
    required this.cameraSize,
    required this.jewelryImages,
    required this.selectedNecklace,
    required this.selectedEarring,
    required this.smoothed,
  });

  Offset _mapPoint(double x, double y, double scaleX, double scaleY) {
    return Offset(x * scaleX, y * scaleY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!smoothed.isValid) return;
    
    final scaleX = size.width / cameraSize.width;
    final scaleY = size.height / cameraSize.height;
    
    final earLeftPos = _mapPoint(smoothed.leftEar!.dx, smoothed.leftEar!.dy, scaleX, scaleY);
    final earRightPos = _mapPoint(smoothed.rightEar!.dx, smoothed.rightEar!.dy, scaleX, scaleY);
    final chinPos = _mapPoint(smoothed.chin!.dx, smoothed.chin!.dy, scaleX, scaleY);
    
    final faceWidthScreen = (smoothed.faceWidth ?? 0) * scaleX;
    final rollRad = (smoothed.rollDeg ?? 0).clamp(-25.0, 25.0) * math.pi / 180;

    // Render Earrings
    if (selectedEarring != null && jewelryImages.containsKey(selectedEarring)) {
      final img = jewelryImages[selectedEarring]!;
      final earringSize = faceWidthScreen * 0.22;
      
      _drawRotatedImage(canvas, img, earLeftPos, earringSize, rollRad);
      _drawRotatedImage(canvas, img, earRightPos, earringSize, rollRad);
    }

    // Render Necklace
    if (selectedNecklace != null && jewelryImages.containsKey(selectedNecklace)) {
      final img = jewelryImages[selectedNecklace]!;
      final necklaceWidth = faceWidthScreen * 0.95;
      final necklaceHeight = necklaceWidth * (img.height / img.width);
      
      final anchor = Offset(chinPos.dx, chinPos.dy + (necklaceHeight / 2));
      _drawRotatedImage(canvas, img, anchor, necklaceWidth, rollRad * 0.5);
    }
  }

  void _drawRotatedImage(Canvas canvas, ui.Image image, Offset center, double width, double rotation) {
    final height = width * (image.height / image.width);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    
    final rect = Rect.fromCenter(center: Offset.zero, width: width, height: height);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant JewelryOverlayPainter oldDelegate) {
    return oldDelegate.smoothed != smoothed || 
           oldDelegate.selectedNecklace != selectedNecklace ||
           oldDelegate.selectedEarring != selectedEarring;
  }
}