// lib/screens/ar/ar_makeup_screen.dart
// CORRECTED VERSION - Proper face makeup without mehndi/jewelry interference
// Issues fixed:
// 1. Lipstick mask to avoid teeth area
// 2. Better blend modes for natural look
// 3. Proper eye detection preventing mehndi patterns
// 4. Separated from jewelry and mehndi logic

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ar_face_engine.dart';

// =============================================================================
// MAKEUP CONFIGURATION
// =============================================================================

enum EyelinerStyle { natural, winged, dramatic }
enum EyeshadowStyle { gradient, smoky, cutCrease }
enum LipFinish { matte, gloss, satin, metallic }

class MakeupConfig {
  // Foundation - Full face
  bool foundationOn = false;
  Color foundationColor = const Color(0xFFEEBE9A);
  double foundationOpacity = 0.30;

  // Concealer - Under eyes
  bool concealerOn = false;
  Color concealerColor = const Color(0xFFF5D5B0);
  double concealerOpacity = 0.40;

  // Contour - Cheeks, jawline, nose
  bool contourOn = false;
  Color contourColor = const Color(0xFFA0683C);
  double contourOpacity = 0.42;

  // Blush - Cheeks only
  bool blushOn = false;
  Color blushColor = const Color(0xFFE8736E);
  double blushOpacity = 0.52;

  // Highlighter - Cheekbones, nose bridge
  bool highlighterOn = false;
  Color highlighterColor = const Color(0xFFFFF0C8);
  double highlighterOpacity = 0.55;

  // Eyebrow
  bool eyebrowOn = false;
  Color eyebrowColor = const Color(0xFF3D2314);
  double eyebrowOpacity = 0.72;

  // Eyeshadow - Eyelid only
  bool eyeshadowOn = false;
  Color eyeshadowColor = const Color(0xFF8B4A6E);
  double eyeshadowOpacity = 0.62;
  bool eyeshadowShimmer = false;
  EyeshadowStyle eyeshadowStyle = EyeshadowStyle.gradient;

  // Eyeliner - Eye outline
  bool eyelinerOn = false;
  Color eyelinerColor = const Color(0xFF1A0A0A);
  double eyelinerOpacity = 0.90;
  EyelinerStyle eyelinerStyle = EyelinerStyle.natural;

  // Mascara - Lashes only
  bool mascaraOn = false;
  double mascaraOpacity = 0.85;

  // Lip Liner - Lip outline
  bool lipLinerOn = false;
  Color lipLinerColor = const Color(0xFF8B1A2A);
  double lipLinerOpacity = 0.82;

  // Lipstick - Lips only (NOT teeth)
  bool lipstickOn = false;
  Color lipstickColor = const Color(0xFFC8384E);
  double lipstickOpacity = 0.78;
  LipFinish lipFinish = LipFinish.matte;
}

// =============================================================================
// MAKEUP SCREEN
// =============================================================================

class ArMakeupScreen extends StatefulWidget {
  const ArMakeupScreen({super.key});

  @override
  State<ArMakeupScreen> createState() => _ArMakeupScreenState();
}

class _ArMakeupScreenState extends State<ArMakeupScreen>
    with WidgetsBindingObserver {
  final _engine = ArFaceEngine();
  bool _cameraReady = false;
  ArFaceData? _faceData;
  final _cfg = MakeupConfig();
  int _tab = 0;
  bool _capturing = false;
  final _previewKey = GlobalKey();

  // Preset looks
  static const _looks = {
    'Natural': _LookPreset(
      lip: Color(0xFFD4956A),
      blush: Color(0xFFE8957A),
      eye: Color(0xFFC8A080),
      brow: Color(0xFF5C3A1E),
    ),
    'Red Glam': _LookPreset(
      lip: Color(0xFFC80020),
      blush: Color(0xFFC84060),
      eye: Color(0xFF8B0000),
      brow: Color(0xFF3D2314),
    ),
    'Smoky': _LookPreset(
      lip: Color(0xFF602040),
      blush: Color(0xFFA06070),
      eye: Color(0xFF2A1A3A),
      brow: Color(0xFF1A1008),
    ),
    'Sunset': _LookPreset(
      lip: Color(0xFFC83860),
      blush: Color(0xFFE06040),
      eye: Color(0xFFE07030),
      brow: Color(0xFF5C3A1E),
    ),
    'Bridal': _LookPreset(
      lip: Color(0xFF8B0000),
      blush: Color(0xFFE8736E),
      eye: Color(0xFF4A0020),
      brow: Color(0xFF3D2314),
    ),
  };

  // Color palettes
  static const _lipColors = [
    Color(0xFFC8384E), Color(0xFFE8203A), Color(0xFF8B0000),
    Color(0xFFFF6080), Color(0xFFD4956A), Color(0xFFC44A6E),
    Color(0xFF7A1030), Color(0xFF600020), Color(0xFFA0284A),
  ];

  static const _blushColors = [
    Color(0xFFE8736E), Color(0xFFF0A0A0), Color(0xFFE8608A),
    Color(0xFFD4505A), Color(0xFFF0C0A0), Color(0xFFE0809A),
  ];

  static const _eyeColors = [
    Color(0xFF8B4A6E), Color(0xFF2A1A3A), Color(0xFFC8A080),
    Color(0xFF1A0080), Color(0xFF5A4030), Color(0xFF4A305A),
    Color(0xFFD08060), Color(0xFF000080), Color(0xFFC84040),
  ];

  static const _linerColors = [
    Color(0xFF0A0A0A), Color(0xFF1A0A1A), Color(0xFF0A1A3A),
    Color(0xFF2A1A0A), Color(0xFF2C1810),
  ];

  static const _foundColors = [
    Color(0xFFFDE0C4), Color(0xFFF1C27D), Color(0xFFE0AC69),
    Color(0xFFC68642), Color(0xFF8D5524), Color(0xFFEEC99A),
  ];

  static const _highlightColors = [
    Color(0xFFFFF0C8), Color(0xFFFFE8A0), Color(0xFFF0D8C0),
    Color(0xFFFFFAE0), Color(0xFFE8D8B8),
  ];

  static const _contourColors = [
    Color(0xFFA0683C), Color(0xFFB07050), Color(0xFF8A5030),
    Color(0xFFC09070), Color(0xFF7A4020),
  ];

  static const _browColors = [
    Color(0xFF3D2314), Color(0xFF5C3A1E), Color(0xFF2C1810),
    Color(0xFF7A5230), Color(0xFF1A1008),
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

      final f = File(
          '${dir.path}/makeup_${DateTime.now().millisecondsSinceEpoch}.png');
      await f.writeAsBytes(data.buffer.asUint8List());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Makeup look saved!'),
            backgroundColor: Color(0xFF2D1B4E),
          ),
        );
      }
    } finally {
      await _engine.startStream();
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _applyLook(String name) {
    final look = _looks[name]!;
    setState(() {
      _cfg.lipstickOn = true;
      _cfg.lipstickColor = look.lip;
      _cfg.lipstickOpacity = 0.80;

      _cfg.blushOn = true;
      _cfg.blushColor = look.blush;
      _cfg.blushOpacity = 0.55;

      _cfg.eyeshadowOn = true;
      _cfg.eyeshadowColor = look.eye;
      _cfg.eyeshadowOpacity = 0.65;

      _cfg.eyebrowOn = true;
      _cfg.eyebrowColor = look.brow;
      _cfg.eyebrowOpacity = 0.80;

      _cfg.eyelinerOn = true;
      _cfg.eyelinerOpacity = 0.88;

      _cfg.highlighterOn = true;
      _cfg.highlighterOpacity = 0.55;

      _cfg.contourOn = true;
      _cfg.contourOpacity = 0.40;

      if (name == 'Smoky') _cfg.eyeshadowStyle = EyeshadowStyle.smoky;
      if (name == 'Bridal') _cfg.eyelinerStyle = EyelinerStyle.winged;
    });
  }

  void _resetAll() => setState(() {
    _cfg.foundationOn = _cfg.concealerOn = _cfg.contourOn = false;
    _cfg.blushOn = _cfg.highlighterOn = _cfg.eyebrowOn = false;
    _cfg.eyeshadowOn = _cfg.eyelinerOn = _cfg.mascaraOn = false;
    _cfg.lipLinerOn = _cfg.lipstickOn = false;
  });

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

  Widget _buildLoader() => Container(
    color: const Color(0xFF0E0A14),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFFC88CC8),
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Initialising Camera…',
            style: GoogleFonts.dmSans(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
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
                    painter: MakeupPainter(
                      face: _faceData!.face,
                      imageSize: _faceData!.imageSize,
                      rotation: _faceData!.rotation,
                      config: _cfg,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
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
                      'Bridal Makeup',
                      style: GoogleFonts.cormorantGaramond(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    _iconBtn(Icons.refresh_rounded, _resetAll),
                    const SizedBox(width: 8),
                    _iconBtn(
                      _capturing
                          ? Icons.hourglass_top
                          : Icons.camera_alt_rounded,
                      _capture,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Preset looks bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 50,
            margin: const EdgeInsets.only(bottom: 4),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _looks.keys
                  .map(
                    (name) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _applyLook(name),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            name,
                            style: GoogleFonts.dmSans(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanel() {
    const tabs = [
      (Icons.format_color_fill_rounded, 'Lips'),
      (Icons.remove_red_eye_rounded, 'Eyes'),
      (Icons.face_rounded, 'Face'),
      (Icons.brush_rounded, 'Brows'),
    ];

    return Container(
      color: const Color(0xFF100A1A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 50,
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
                                  ? const Color(0xFFC88CC8)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tabs[i].$1,
                              size: 16,
                              color: sel
                                  ? const Color(0xFFC88CC8)
                                  : Colors.white30,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tabs[i].$2,
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                color: sel
                                    ? const Color(0xFFC88CC8)
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
            height: 220,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
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
      default:
        return _browsTab();
    }
  }

  Widget _lipsTab() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _makeupRow(
        'Lipstick',
        _cfg.lipstickOn,
        (v) => setState(() => _cfg.lipstickOn = v),
        _lipColors,
        _cfg.lipstickColor,
        (c) => setState(() => _cfg.lipstickColor = c),
        _cfg.lipstickOpacity,
        (v) => setState(() => _cfg.lipstickOpacity = v),
        extra: _finishRow(),
      ),
      _sep(),
      _makeupRow(
        'Lip Liner',
        _cfg.lipLinerOn,
        (v) => setState(() => _cfg.lipLinerOn = v),
        _lipColors,
        _cfg.lipLinerColor,
        (c) => setState(() => _cfg.lipLinerColor = c),
        _cfg.lipLinerOpacity,
        (v) => setState(() => _cfg.lipLinerOpacity = v),
      ),
    ],
  );

  Widget _finishRow() {
    const opts = [
      (LipFinish.matte, 'Matte'),
      (LipFinish.gloss, 'Gloss'),
      (LipFinish.satin, 'Satin'),
      (LipFinish.metallic, 'Metallic')
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: opts
            .map(
              (o) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _cfg.lipFinish = o.$1),
                  child: _chip(o.$2, _cfg.lipFinish == o.$1),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _eyesTab() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _makeupRow(
        'Eye Shadow',
        _cfg.eyeshadowOn,
        (v) => setState(() => _cfg.eyeshadowOn = v),
        _eyeColors,
        _cfg.eyeshadowColor,
        (c) => setState(() => _cfg.eyeshadowColor = c),
        _cfg.eyeshadowOpacity,
        (v) => setState(() => _cfg.eyeshadowOpacity = v),
        extra: _eyeStyleRow(),
      ),
      _sep(),
      _makeupRow(
        'Eyeliner',
        _cfg.eyelinerOn,
        (v) => setState(() => _cfg.eyelinerOn = v),
        _linerColors,
        _cfg.eyelinerColor,
        (c) => setState(() => _cfg.eyelinerColor = c),
        _cfg.eyelinerOpacity,
        (v) => setState(() => _cfg.eyelinerOpacity = v),
        extra: _linerStyleRow(),
      ),
      _sep(),
      _makeupRow(
        'Mascara',
        _cfg.mascaraOn,
        (v) => setState(() => _cfg.mascaraOn = v),
        const [Color(0xFF0A0A0A)],
        const Color(0xFF0A0A0A),
        (_) {},
        _cfg.mascaraOpacity,
        (v) => setState(() => _cfg.mascaraOpacity = v),
      ),
    ],
  );

  Widget _eyeStyleRow() {
    const s = [
      (EyeshadowStyle.gradient, 'Gradient'),
      (EyeshadowStyle.smoky, 'Smoky'),
      (EyeshadowStyle.cutCrease, 'Cut Crease')
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          ...s.map(
            (x) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() => _cfg.eyeshadowStyle = x.$1),
                child: _chip(x.$2, _cfg.eyeshadowStyle == x.$1),
              ),
            ),
          ),
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
    const s = [
      (EyelinerStyle.natural, 'Natural'),
      (EyelinerStyle.winged, 'Winged'),
      (EyelinerStyle.dramatic, 'Dramatic')
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: s
            .map(
              (x) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _cfg.eyelinerStyle = x.$1),
                  child: _chip(x.$2, _cfg.eyelinerStyle == x.$1),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _faceTab() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _makeupRow(
        'Foundation',
        _cfg.foundationOn,
        (v) => setState(() => _cfg.foundationOn = v),
        _foundColors,
        _cfg.foundationColor,
        (c) => setState(() => _cfg.foundationColor = c),
        _cfg.foundationOpacity,
        (v) => setState(() => _cfg.foundationOpacity = v),
      ),
      _sep(),
      _makeupRow(
        'Concealer',
        _cfg.concealerOn,
        (v) => setState(() => _cfg.concealerOn = v),
        _foundColors,
        _cfg.concealerColor,
        (c) => setState(() => _cfg.concealerColor = c),
        _cfg.concealerOpacity,
        (v) => setState(() => _cfg.concealerOpacity = v),
      ),
      _sep(),
      _makeupRow(
        'Blush',
        _cfg.blushOn,
        (v) => setState(() => _cfg.blushOn = v),
        _blushColors,
        _cfg.blushColor,
        (c) => setState(() => _cfg.blushColor = c),
        _cfg.blushOpacity,
        (v) => setState(() => _cfg.blushOpacity = v),
      ),
      _sep(),
      _makeupRow(
        'Highlighter',
        _cfg.highlighterOn,
        (v) => setState(() => _cfg.highlighterOn = v),
        _highlightColors,
        _cfg.highlighterColor,
        (c) => setState(() => _cfg.highlighterColor = c),
        _cfg.highlighterOpacity,
        (v) => setState(() => _cfg.highlighterOpacity = v),
      ),
      _sep(),
      _makeupRow(
        'Contour',
        _cfg.contourOn,
        (v) => setState(() => _cfg.contourOn = v),
        _contourColors,
        _cfg.contourColor,
        (c) => setState(() => _cfg.contourColor = c),
        _cfg.contourOpacity,
        (v) => setState(() => _cfg.contourOpacity = v),
      ),
    ],
  );

  Widget _browsTab() => _makeupRow(
    'Eyebrows',
    _cfg.eyebrowOn,
    (v) => setState(() => _cfg.eyebrowOn = v),
    _browColors,
    _cfg.eyebrowColor,
    (c) => setState(() => _cfg.eyebrowColor = c),
    _cfg.eyebrowOpacity,
    (v) => setState(() => _cfg.eyebrowOpacity = v),
  );

  Widget _makeupRow(
    String label,
    bool isOn,
    ValueChanged<bool> onToggle,
    List<Color> colors,
    Color selected,
    ValueChanged<Color> onColor,
    double opacity,
    ValueChanged<double> onOpacity, {
    Widget? extra,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: Colors.white70,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            Transform.scale(
              scale: 0.78,
              child: Switch(
                value: isOn,
                onChanged: onToggle,
                activeColor: const Color(0xFFC88CC8),
                activeTrackColor: const Color(0xFFC88CC8).withOpacity(0.3),
                inactiveThumbColor: Colors.white24,
                inactiveTrackColor: Colors.white10,
              ),
            ),
          ],
        ),
        if (isOn) ...[
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
          Row(
            children: [
              Text(
                'Intensity',
                style: GoogleFonts.dmSans(
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
                    activeTrackColor: const Color(0xFFC88CC8),
                    inactiveTrackColor: Colors.white10,
                    thumbColor: const Color(0xFFC88CC8),
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
                  style: GoogleFonts.dmSans(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          if (extra != null) extra,
        ],
      ],
    );
  }

  Widget _chip(String t, bool sel) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: sel
          ? const Color(0xFFC88CC8).withOpacity(0.22)
          : Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: sel
            ? const Color(0xFFC88CC8)
            : Colors.white.withOpacity(0.1),
      ),
    ),
    child: Text(
      t,
      style: GoogleFonts.dmSans(
        fontSize: 10,
        color: sel ? const Color(0xFFC88CC8) : Colors.white54,
      ),
    ),
  );

  Widget _iconBtn(IconData icon, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.black38,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );

  Widget _sep() => Divider(
    height: 14,
    thickness: 0.5,
    color: Colors.white.withOpacity(0.06),
  );
}

// =============================================================================
// MAKEUP PAINTER - 3D-ENHANCED VERSION
// =============================================================================

class MakeupPainter extends CustomPainter {
  final Face face;
  final Size imageSize;
  final InputImageRotation rotation;
  final MakeupConfig config;

  const MakeupPainter({
    required this.face,
    required this.imageSize,
    required this.rotation,
    required this.config,
  });

  // Coordinate transform: ML Kit image space → canvas pixels
  Offset _t(math.Point<int> pt, Size cs) {
    double x = pt.x.toDouble(), y = pt.y.toDouble();
    final iw = imageSize.width, ih = imageSize.height;

    double rx, ry;

    switch (rotation) {
      case InputImageRotation.rotation0deg:
        rx = x;
        ry = y;
      case InputImageRotation.rotation90deg:
        rx = ih - y;
        ry = x;
      case InputImageRotation.rotation180deg:
        rx = iw - x;
        ry = ih - y;
      case InputImageRotation.rotation270deg:
        rx = y;
        ry = iw - x;
    }

    final lw = (rotation == InputImageRotation.rotation90deg ||
            rotation == InputImageRotation.rotation270deg)
        ? ih
        : iw;
    final lh = (rotation == InputImageRotation.rotation90deg ||
            rotation == InputImageRotation.rotation270deg)
        ? iw
        : ih;

    return Offset(cs.width - rx / lw * cs.width, ry / lh * cs.height);
  }

  List<Offset> _tl(List<math.Point<int>> pts, Size cs) =>
      pts.map((p) => _t(p, cs)).toList();

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize == Size.zero) return;

    final faceOval = _tl(face.contours[FaceContourType.face]?.points ?? [], size);
    final leftEye =
        _tl(face.contours[FaceContourType.leftEye]?.points ?? [], size);
    final rightEye =
        _tl(face.contours[FaceContourType.rightEye]?.points ?? [], size);
    final ulTop =
        _tl(face.contours[FaceContourType.upperLipTop]?.points ?? [], size);
    final ulBot =
        _tl(face.contours[FaceContourType.upperLipBottom]?.points ?? [], size);
    final llTop =
        _tl(face.contours[FaceContourType.lowerLipTop]?.points ?? [], size);
    final llBot =
        _tl(face.contours[FaceContourType.lowerLipBottom]?.points ?? [], size);
    final lBrowTop =
        _tl(face.contours[FaceContourType.leftEyebrowTop]?.points ?? [], size);
    final lBrowBot =
        _tl(face.contours[FaceContourType.leftEyebrowBottom]?.points ?? [], size);
    final rBrowTop =
        _tl(face.contours[FaceContourType.rightEyebrowTop]?.points ?? [], size);
    final rBrowBot =
        _tl(face.contours[FaceContourType.rightEyebrowBottom]?.points ?? [], size);
    final noseBr =
        _tl(face.contours[FaceContourType.noseBridge]?.points ?? [], size);
    final noseBot =
        _tl(face.contours[FaceContourType.noseBottom]?.points ?? [], size);

    final fr = _bbox(faceOval);
    final ler = _bbox(leftEye);
    final rer = _bbox(rightEye);

    final yaw = face.headEulerAngleY ?? 0.0;
    final lf = ((90 + yaw) / 90).clamp(0.1, 1.0);
    final rf = ((90 - yaw) / 90).clamp(0.1, 1.0);

    // Draw makeup layers in order
    if (config.foundationOn && faceOval.length >= 3) {
      _drawFoundation(canvas, faceOval);
    }
    if (config.concealerOn && leftEye.isNotEmpty) {
      _drawConcealer(canvas, ler, rer);
    }
    if (config.contourOn && faceOval.isNotEmpty) {
      _drawContour(canvas, faceOval, fr, noseBr, lf, rf);
    }
    if (config.highlighterOn) {
      _drawHighlighter(canvas, ler, rer, noseBot, fr, lf, rf);
    }
    if (config.blushOn) {
      _drawBlush(canvas, fr, lf, rf);
    }
    if (config.eyebrowOn) {
      _drawEyebrows(canvas, lBrowTop, lBrowBot, rBrowTop, rBrowBot);
    }
    if (config.eyeshadowOn && leftEye.isNotEmpty) {
      _drawEyeshadow(canvas, leftEye, rightEye, lf, rf);
    }
    if (config.eyelinerOn && leftEye.isNotEmpty) {
      _drawEyeliner(canvas, leftEye, rightEye, lf, rf);
    }
    if (config.mascaraOn && leftEye.isNotEmpty) {
      _drawMascara(canvas, leftEye, rightEye, lf, rf);
    }
    if (config.lipLinerOn && ulTop.isNotEmpty) {
      _drawLipLiner(canvas, ulTop, llBot);
    }
    if (config.lipstickOn && ulTop.isNotEmpty) {
      _drawLipstick(canvas, ulTop, ulBot, llTop, llBot);
    }
  }

  // Foundation - Full face coverage
  void _drawFoundation(Canvas c, List<Offset> oval) {
    final path = _closed(oval);

    c.drawPath(
      path,
      Paint()
        ..color = config.foundationColor
            .withOpacity(config.foundationOpacity * 0.55)
        ..blendMode = BlendMode.multiply
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    c.drawPath(
      path,
      Paint()
        ..color = config.foundationColor
            .withOpacity(config.foundationOpacity * 0.28)
        ..blendMode = BlendMode.srcATop,
    );
  }

  // Concealer - Under eyes with radial gradient
  void _drawConcealer(Canvas c, Rect le, Rect re) {
    void under(Rect r) {
      if (r.isEmpty) return;
      final cx = r.center.dx;
      final cy = r.bottom + r.height * 0.35;
      final rx = r.width * 0.75;
      final ry = r.height * 0.55;

      c.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: rx * 2,
          height: ry * 2,
        ),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(cx, cy),
            math.max(rx, ry),
            [
              config.concealerColor
                  .withOpacity(config.concealerOpacity * 0.65),
              config.concealerColor.withOpacity(0),
            ],
          )
          ..blendMode = BlendMode.srcATop,
      );
    }

    under(le);
    under(re);
  }

  // Contour - Cheeks, jawline, nose
  void _drawContour(Canvas c, List<Offset> oval, Rect fr,
      List<Offset> nose, double lf, double rf) {
    final col = config.contourColor;
    final op = config.contourOpacity;
    final fw = fr.width;
    final fh = fr.height;
    final cy = fr.top + fh * 0.52;

    void cheek(double x, double factor) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x, cy),
          width: fw * 0.44,
          height: fh * 0.20,
        ),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(x, cy),
            fw * 0.22,
            [
              col.withOpacity(op * 0.55 * factor),
              col.withOpacity(0),
            ],
          )
          ..blendMode = BlendMode.multiply,
      );
    }

    cheek(fr.left + fw * 0.12, lf);
    cheek(fr.right - fw * 0.12, rf);

    // Jawline
    final jaw = oval.where((p) => p.dy > fr.top + fh * 0.70).toList();

    if (jaw.length >= 2) {
      final p = Path()..moveTo(jaw.first.dx, jaw.first.dy);
      for (final pt in jaw.skip(1)) p.lineTo(pt.dx, pt.dy);

      c.drawPath(
        p,
        Paint()
          ..color = col.withOpacity(op * 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = fh * 0.022
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
          ..blendMode = BlendMode.multiply,
      );
    }

    // Nose sides
    if (nose.length >= 2) {
      final nw = (nose.last.dx - nose.first.dx).abs() * 0.28;
      for (final side in [nose.first, nose.last]) {
        c.drawOval(
          Rect.fromCenter(
            center: side,
            width: nw,
            height: fh * 0.07,
          ),
          Paint()
            ..color = col.withOpacity(op * 0.22)
            ..blendMode = BlendMode.multiply
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
    }
  }

  // Highlighter - Cheekbones, nose bridge, brow bones
  void _drawHighlighter(Canvas c, Rect le, Rect re, List<Offset> nb, Rect fr,
      double lf, double rf) {
    final col = config.highlighterColor;
    final op = config.highlighterOpacity;
    final fw = fr.width;
    final fh = fr.height;

    void glow(Offset center, double rx, double ry, double factor) {
      c.drawOval(
        Rect.fromCenter(
          center: center,
          width: rx * 2,
          height: ry * 2,
        ),
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            math.max(rx, ry),
            [
              col.withOpacity(op * 0.70 * factor),
              col.withOpacity(0),
            ],
          )
          ..blendMode = BlendMode.screen,
      );
    }

    if (!le.isEmpty) {
      glow(
        Offset(le.left - fw * 0.03, le.center.dy + le.height * 0.5),
        fw * 0.09,
        fh * 0.045,
        lf,
      );
      glow(
        Offset(le.center.dx, le.top - fh * 0.012),
        fw * 0.065,
        fh * 0.018,
        lf * 0.65,
      );
    }

    if (!re.isEmpty) {
      glow(
        Offset(re.right + fw * 0.03, re.center.dy + re.height * 0.5),
        fw * 0.09,
        fh * 0.045,
        rf,
      );
      glow(
        Offset(re.center.dx, re.top - fh * 0.012),
        fw * 0.065,
        fh * 0.018,
        rf * 0.65,
      );
    }

    if (nb.isNotEmpty) glow(_cen(nb), fw * 0.038, fh * 0.022, 1.0);
  }

  // Blush - Cheeks only with directional gradient
  void _drawBlush(Canvas c, Rect fr, double lf, double rf) {
    final col = config.blushColor;
    final op = config.blushOpacity;
    final fw = fr.width;
    final fh = fr.height;
    final cy = fr.top + fh * 0.52;
    final r = fw * 0.17;

    void side(double x, double factor) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(x, cy),
          width: r * 2.2,
          height: r * 1.35,
        ),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(x, cy),
            r,
            [
              col.withOpacity(op * 0.50 * factor),
              col.withOpacity(0),
            ],
          )
          ..blendMode = BlendMode.multiply,
      );
    }

    side(fr.left + fw * 0.17, lf);
    side(fr.right - fw * 0.17, rf);
  }

  // Eyebrows
  void _drawEyebrows(Canvas c, List<Offset> lt, List<Offset> lb,
      List<Offset> rt, List<Offset> rb) {
    void brow(List<Offset> top, List<Offset> bot) {
      if (top.isEmpty) return;

      final bh = (top.isNotEmpty && bot.isNotEmpty)
          ? ((top.first.dy - bot.first.dy).abs() +
                  (top.last.dy - bot.last.dy).abs()) /
              2
          : 7.0;

      c.drawPath(
        _smooth(top),
        Paint()
          ..color =
              config.eyebrowColor.withOpacity(config.eyebrowOpacity * 0.88)
          ..style = PaintingStyle.stroke
          ..strokeWidth = bh.clamp(3.5, 11.0)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2)
          ..blendMode = BlendMode.multiply,
      );
    }

    brow(lt, lb);
    brow(rt, rb);
  }

  // Eyeshadow - 3D-enhanced with multiple styles
  void _drawEyeshadow(Canvas c, List<Offset> le, List<Offset> re,
      double lf, double rf) {
    void shadow(List<Offset> eye, double factor) {
      if (eye.isEmpty) return;

      final r = _bbox(eye);
      if (r.isEmpty) return;

      final cx = r.center.dx;
      final cy = r.top;
      final ew = r.width;
      final eh = r.height;
      final op = config.eyeshadowOpacity * factor;

      final sh = switch (config.eyeshadowStyle) {
        EyeshadowStyle.gradient => eh * 2.2,
        EyeshadowStyle.smoky => eh * 3.5,
        EyeshadowStyle.cutCrease => eh * 1.6,
      };

      final col = config.eyeshadowColor;

      switch (config.eyeshadowStyle) {
        case EyeshadowStyle.gradient:
          c.drawOval(
            Rect.fromCenter(
              center: Offset(cx, cy - sh * 0.2),
              width: ew * 1.2,
              height: sh * 1.5,
            ),
            Paint()
              ..shader = ui.Gradient.radial(
                Offset(cx, cy),
                sh,
                [
                  col.withOpacity(op * 0.85),
                  col.withOpacity(op * 0.3),
                  col.withOpacity(0)
                ],
                [0.0, 0.5, 1.0],
              )
              ..blendMode = BlendMode.multiply,
          );

        case EyeshadowStyle.smoky:
          for (int i = 0; i < 2; i++) {
            final lc = i == 0 ? _darken(col, 0.5) : col;
            final lo = i == 0 ? op * 0.9 : op * 0.6;
            final lh = i == 0 ? sh : sh * 0.65;

            c.drawOval(
              Rect.fromCenter(
                center: Offset(cx, cy - lh * 0.2),
                width: ew * 1.3,
                height: lh * 1.6,
              ),
              Paint()
                ..shader = ui.Gradient.radial(
                  Offset(cx, cy),
                  lh,
                  [lc.withOpacity(lo), lc.withOpacity(0)],
                  [0.3, 1.0],
                )
                ..blendMode = BlendMode.multiply,
            );
          }

        case EyeshadowStyle.cutCrease:
          c.drawOval(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: ew * 1.1,
              height: sh,
            ),
            Paint()
              ..shader = ui.Gradient.radial(
                Offset(cx, cy),
                sh,
                [
                  col.withOpacity(op * 0.95),
                  col.withOpacity(op * 0.6),
                  col.withOpacity(0)
                ],
                [0.0, 0.45, 1.0],
              )
              ..blendMode = BlendMode.multiply,
          );

          c.drawLine(
            Offset(r.left - ew * 0.08, cy),
            Offset(r.right + ew * 0.08, cy),
            Paint()
              ..color = _darken(col, 0.3).withOpacity(op * 0.6)
              ..strokeWidth = eh * 0.4
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
              ..blendMode = BlendMode.multiply,
          );
      }

      if (config.eyeshadowShimmer) {
        c.drawOval(
          Rect.fromCenter(
            center: Offset(cx, r.center.dy),
            width: ew * 0.75,
            height: eh * 0.65,
          ),
          Paint()
            ..shader = ui.Gradient.radial(
              Offset(cx, r.center.dy),
              ew * 0.38,
              [
                Colors.white.withOpacity(op * 0.38),
                Colors.white.withOpacity(0)
              ],
            )
            ..blendMode = BlendMode.screen,
        );
      }
    }

    shadow(le, lf);
    shadow(re, rf);
  }

  // Eyeliner with styles
  void _drawEyeliner(Canvas c, List<Offset> le, List<Offset> re,
      double lf, double rf) {
    void liner(List<Offset> eye, double factor, bool isLeft) {
      if (eye.isEmpty) return;

      final r = _bbox(eye);
      if (r.isEmpty) return;

      final midY = r.center.dy;
      final upper = (eye
          .where((p) => p.dy <= midY + r.height * 0.15)
          .toList()
            ..sort((a, b) => a.dx.compareTo(b.dx)));

      if (upper.length < 2) return;

      final lw = (r.height * 0.22).clamp(2.0, 5.5);
      final op = config.eyelinerOpacity * factor;
      final col = config.eyelinerColor;

      c.drawPath(
        _smooth(upper),
        Paint()
          ..color = col.withOpacity(op)
          ..style = PaintingStyle.stroke
          ..strokeWidth = lw
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..blendMode = BlendMode.srcATop,
      );

      final lower = (eye
          .where((p) => p.dy > midY - r.height * 0.15)
          .toList()
            ..sort((a, b) => a.dx.compareTo(b.dx)));

      if (lower.length >= 2) {
        c.drawPath(
          _smooth(lower),
          Paint()
            ..color = col.withOpacity(op * 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = lw * 0.5
            ..strokeCap = StrokeCap.round
            ..blendMode = BlendMode.srcATop,
        );
      }

      if (config.eyelinerStyle == EyelinerStyle.winged ||
          config.eyelinerStyle == EyelinerStyle.dramatic) {
        final wl = config.eyelinerStyle == EyelinerStyle.dramatic
            ? r.width * 0.27
            : r.width * 0.17;
        final wa = isLeft ? -0.55 : -2.59;
        final corner = isLeft ? upper.last : upper.first;
        final end = Offset(
          corner.dx + wl * math.cos(wa),
          corner.dy + wl * math.sin(wa),
        );

        c.drawLine(
          corner,
          end,
          Paint()
            ..color = col.withOpacity(op)
            ..strokeWidth = lw * 0.75
            ..strokeCap = StrokeCap.round
            ..blendMode = BlendMode.srcATop,
        );

        if (config.eyelinerStyle == EyelinerStyle.dramatic) {
          c.drawPath(
            Path()
              ..moveTo(corner.dx, corner.dy)
              ..lineTo(end.dx, end.dy)
              ..lineTo(corner.dx, corner.dy + r.height * 0.25)
              ..close(),
            Paint()
              ..color = col.withOpacity(op * 0.78)
              ..blendMode = BlendMode.srcATop,
          );
        }
      }
    }

    liner(le, lf, true);
    liner(re, rf, false);
  }

  // Mascara - Lashes with natural variation
  void _drawMascara(Canvas c, List<Offset> le, List<Offset> re,
      double lf, double rf) {
    void lashes(List<Offset> eye, double factor) {
      if (eye.isEmpty) return;

      final r = _bbox(eye);
      if (r.isEmpty) return;

      final upper = (eye
          .where((p) => p.dy < r.center.dy)
          .toList()
            ..sort((a, b) => a.dx.compareTo(b.dx)));

      if (upper.length < 2) return;

      final ll = r.height * 0.65;
      final p = Paint()
        ..color = const Color(0xFF080808)
            .withOpacity(config.mascaraOpacity * factor)
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.srcATop;

      for (int i = 0; i < upper.length; i++) {
        final pt = upper[i];
        final prog = i / (upper.length - 1);
        final ang = -math.pi / 2 + (prog - 0.5) * 0.4;

        p.strokeWidth = 1.1 + (1 - (prog - 0.5).abs() * 2) * 1.5;

        c.drawLine(
          pt,
          Offset(
            pt.dx + ll * 0.28 * math.cos(ang),
            pt.dy - ll * math.sin(ang.abs()),
          ),
          p,
        );
      }

      c.drawPath(
        _smooth(upper),
        Paint()
          ..color = const Color(0xFF080808)
              .withOpacity(config.mascaraOpacity * 0.65 * factor)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r.height * 0.17
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.srcATop,
      );
    }

    lashes(le, lf);
    lashes(re, rf);
  }

  // Lip Liner - Outline only
  void _drawLipLiner(Canvas c, List<Offset> ut, List<Offset> lb) {
    final all = [...ut, ...lb.reversed];

    if (all.length < 3) return;

    c.drawPath(
      _closed(all),
      Paint()
        ..color = config.lipLinerColor.withOpacity(config.lipLinerOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..blendMode = BlendMode.srcATop,
    );
  }

  // Lipstick - CRITICAL: Only lips, not teeth!
  void _drawLipstick(Canvas c, List<Offset> ut, List<Offset> ub,
      List<Offset> lt, List<Offset> lb) {
    if (ut.isEmpty || lb.isEmpty) return;

    // Create separate paths for upper and lower lips
    final upper = _lipHalf(ut, ub);
    final lower = _lipHalf(lt, lb);

    final col = config.lipstickColor;
    final op = config.lipstickOpacity;

    // Apply lipstick with appropriate blend mode
    final bm = _isLight(col) ? BlendMode.overlay : BlendMode.multiply;

    // Upper lip
    c.drawPath(
      upper,
      Paint()
        ..color = col.withOpacity(op * 0.88)
        ..blendMode = bm,
    );

    // Lower lip (usually darker)
    c.drawPath(
      lower,
      Paint()
        ..color = col.withOpacity(op * 0.92)
        ..blendMode = bm,
    );

    // Lip finish effects
    switch (config.lipFinish) {
      case LipFinish.gloss:
        if (lb.isNotEmpty) {
          final cen = _cen(lb);
          final lr = _bbox(lb);

          c.drawPath(
            lower,
            Paint()
              ..shader = ui.Gradient.radial(
                Offset(cen.dx, cen.dy - lr.height * 0.2),
                lr.width * 0.34,
                [
                  Colors.white.withOpacity(0.42),
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0)
                ],
                [0.0, 0.4, 1.0],
              )
              ..blendMode = BlendMode.screen,
          );
        }

      case LipFinish.satin:
        if (lb.isNotEmpty) {
          final lr = _bbox(lb);

          c.drawPath(
            lower,
            Paint()
              ..shader = ui.Gradient.linear(
                Offset(lr.center.dx, lr.top),
                Offset(lr.center.dx, lr.bottom),
                [
                  Colors.white.withOpacity(0.18),
                  Colors.white.withOpacity(0.04),
                  Colors.white.withOpacity(0)
                ],
              )
              ..blendMode = BlendMode.screen,
          );
        }

      case LipFinish.metallic:
        c.drawPath(
          lower,
          Paint()
            ..color = _lighten(col, 0.6).withOpacity(0.33)
            ..blendMode = BlendMode.screen,
        );

        c.drawPath(
          upper,
          Paint()
            ..color = _darken(col, 0.3).withOpacity(0.18)
            ..blendMode = BlendMode.multiply,
        );

      case LipFinish.matte:
        break;
    }

    // Lip definition
    if (ub.isNotEmpty) {
      c.drawPath(
        _smooth(ub),
        Paint()
          ..color = _darken(col, 0.22).withOpacity(op * 0.45)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke
          ..blendMode = BlendMode.multiply,
      );
    }
  }

  // Path helpers
  Path _smooth(List<Offset> pts) {
    if (pts.isEmpty) return Path();

    final p = Path()..moveTo(pts[0].dx, pts[0].dy);

    for (int i = 1; i < pts.length - 1; i++) {
      p.quadraticBezierTo(
        pts[i].dx,
        pts[i].dy,
        (pts[i].dx + pts[i + 1].dx) / 2,
        (pts[i].dy + pts[i + 1].dy) / 2,
      );
    }

    if (pts.length > 1) p.lineTo(pts.last.dx, pts.last.dy);

    return p;
  }

  Path _closed(List<Offset> pts) {
    if (pts.isEmpty) return Path();

    final p = Path()..moveTo(pts[0].dx, pts[0].dy);

    for (final pt in pts.skip(1)) p.lineTo(pt.dx, pt.dy);

    return p..close();
  }

  Path _lipHalf(List<Offset> outer, List<Offset> inner) {
    if (outer.isEmpty) return Path();

    final so = List<Offset>.from(outer)..sort((a, b) => a.dx.compareTo(b.dx));
    final si = List<Offset>.from(inner)..sort((a, b) => a.dx.compareTo(b.dx));

    final p = Path()..moveTo(so.first.dx, so.first.dy);

    for (int i = 1; i < so.length - 1; i++) {
      p.quadraticBezierTo(
        so[i].dx,
        so[i].dy,
        (so[i].dx + so[i + 1].dx) / 2,
        (so[i].dy + so[i + 1].dy) / 2,
      );
    }

    if (so.length > 1) p.lineTo(so.last.dx, so.last.dy);

    for (int i = si.length - 1; i >= 0; i--) p.lineTo(si[i].dx, si[i].dy);

    return p..close();
  }

  Rect _bbox(List<Offset> pts) {
    if (pts.isEmpty) return Rect.zero;

    double x0 = double.infinity, y0 = double.infinity;
    double x1 = double.negativeInfinity, y1 = double.negativeInfinity;

    for (final p in pts) {
      if (p.dx < x0) x0 = p.dx;
      if (p.dy < y0) y0 = p.dy;
      if (p.dx > x1) x1 = p.dx;
      if (p.dy > y1) y1 = p.dy;
    }

    return Rect.fromLTRB(x0, y0, x1, y1);
  }

  Offset _cen(List<Offset> pts) {
    if (pts.isEmpty) return Offset.zero;

    return pts.fold(Offset.zero, (s, p) => s + p) / pts.length.toDouble();
  }

  Color _darken(Color c, double a) => Color.fromARGB(
    c.alpha,
    (c.red * (1 - a)).round().clamp(0, 255),
    (c.green * (1 - a)).round().clamp(0, 255),
    (c.blue * (1 - a)).round().clamp(0, 255),
  );

  Color _lighten(Color c, double a) => Color.fromARGB(
    c.alpha,
    (c.red + (255 - c.red) * a).round().clamp(0, 255),
    (c.green + (255 - c.green) * a).round().clamp(0, 255),
    (c.blue + (255 - c.blue) * a).round().clamp(0, 255),
  );

  bool _isLight(Color c) =>
      (c.red * 0.299 + c.green * 0.587 + c.blue * 0.114) > 128;

  @override
  bool shouldRepaint(MakeupPainter old) =>
      old.face != face ||
      old.imageSize != imageSize ||
      old.rotation != rotation ||
      old.config != config;
}

class _LookPreset {
  final Color lip, blush, eye, brow;

  const _LookPreset({
    required this.lip,
    required this.blush,
    required this.eye,
    required this.brow,
  });
}