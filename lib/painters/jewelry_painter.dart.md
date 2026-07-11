// lib/painters/jewelry_painter.dart
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/makeup_configuration.dart';

class JewelryPainter extends CustomPainter {
  final List<Face> faces;
  final MakeupConfiguration config;
  final Size absoluteImageSize;
  final int rotation;

  JewelryPainter({
    required this.faces,
    required this.config,
    required this.absoluteImageSize,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final face in faces) {
      final double scaleX = size.width / absoluteImageSize.width;
      final double scaleY = size.height / absoluteImageSize.height;

      // 1. Forehead Anchor Point -> Maang Tikka Placement
      final foreheadContour = face.contours[FaceContourType.face];
      if (foreheadContour != null && config.selectedTikkaAsset != null) {
        // Grab top-center point index safely
        final anchorPoint = foreheadContour.points[((foreheadContour.points.length) / 2).floor()];
        final Offset tikkaPosition = Offset(anchorPoint.x * scaleX, (anchorPoint.y * scaleY) + 15);
        
        _renderJewelryAsset(canvas, config.selectedTikkaAsset!, tikkaPosition, size: Size(65, 110));
      }

      // 2. Nose Coordinates -> Nose Ring Placement
      final noseBridge = face.contours[FaceContourType.noseBridge];
      if (noseBridge != null && config.selectedNoseRingAsset != null) {
        final baseNosePoint = noseBridge.points.last; 
        final Offset nosePosition = Offset((baseNosePoint.x * scaleX) - 18, baseNosePoint.y * scaleY);

        _renderJewelryAsset(canvas, config.selectedNoseRingAsset!, nosePosition, size: Size(45, 45));
      }

      // 3. Lower Chin Anchor Point -> Traditional Bridal Necklace Estimation Placement
      if (foreheadContour != null && config.selectedNecklaceAsset != null) {
        final chinPoint = foreheadContour.points[(foreheadContour.points.length / 2).floor()];
        final Offset necklacePosition = Offset(chinPoint.x * scaleX, (chinPoint.y * scaleY) + 120);

        _renderJewelryAsset(canvas, config.selectedNecklaceAsset!, necklacePosition, size: Size(180, 140));
      }
    }
  }

  void _renderJewelryAsset(Canvas canvas, String assetPath, Offset centerPosition, {required Size size}) {
    final painter = ImagePainterEngine.getAssetImagePainter(assetPath);
    painter.paint(canvas, centerPosition - Offset(size.width / 2, size.height / 2), size: size);
  }

  @override
  bool shouldRepaint(covariant JewelryPainter oldDelegate) => true;
}

// Global resource engine wrapper helper caching handles
class ImagePainterEngine {
  static ImagePainter getAssetImagePainter(String assetPath) {
    return ImagePainter(imageProvider: AssetImage(assetPath));
  }
}

class ImagePainter {
  final ImageProvider imageProvider;
  ImagePainter({required this.imageProvider});

  void paint(Canvas canvas, Offset position, {required Size size}) {
    final imageStream = imageProvider.resolve(ImageConfiguration.empty);
    imageStream.addListener(ImageStreamListener((ImageInfo info, bool _) {
      canvas.drawImageRect(
        info.image,
        Rect.fromLTWH(0, 0, info.image.width.toDouble(), info.image.height.toDouble()),
        Rect.fromLTWH(position.dx, position.dy, size.width, size.height),
        Paint(),
      );
    }));
  }
}