import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/makeup_configuration.dart';

class MakeupPainter extends CustomPainter {
  final List<Face> faces;
  final MakeupConfiguration config;
  final Size absoluteImageSize;
  final int rotation;

  final ui.Image? nathImage;
  final ui.Image? teekaImage;
  final ui.Image? mehndiImage;

  MakeupPainter({
    required this.faces,
    required this.config,
    required this.absoluteImageSize,
    required this.rotation,
    this.nathImage,
    this.teekaImage,
    this.mehndiImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final Face face in faces) {
      // Scale conversions between raw image frame buffers and screen display canvas
      final double scaleX = size.width / absoluteImageSize.height;
      final double scaleY = size.height / absoluteImageSize.width;

      Offset transformPoint(Point<int> point) {
        return Offset(size.width - (point.x * scaleX), point.y * scaleY);
      }

      // Read highly stable bounding box metrics
      final boundingBox = face.boundingBox;
      final double leftBox = size.width - (boundingBox.right * scaleX);
      final double widthBox = boundingBox.width * scaleX;
      final double topBox = boundingBox.top * scaleY;
      final double heightBox = boundingBox.height * scaleY;

      // Extract specific semantic paths unlocked by step 1
      final upperLip = face.contours[FaceContourType.upperLipTop];
      final lowerLip = face.contours[FaceContourType.lowerLipBottom];
      final leftEye = face.contours[FaceContourType.leftEye];
      final rightEye = face.contours[FaceContourType.rightEye];
      final noseBridge = face.contours[FaceContourType.noseBridge];

      // ==========================================
      // 1. LIPSTICK LAYER
      // ==========================================
      if (upperLip != null && lowerLip != null && config.lipstickColor != Colors.transparent) {
        final Path lipPath = Path();
        final List<Offset> points = [...upperLip.points, ...lowerLip.points.reversed].map(transformPoint).toList();
        if (points.isNotEmpty) {
          lipPath.moveTo(points.first.dx, points.first.dy);
          for (var p in points) {
            lipPath.lineTo(p.dx, p.dy);
          }
          lipPath.close();
          canvas.drawPath(lipPath, Paint()
            ..color = config.lipstickColor.withOpacity(config.lipstickOpacity)
            ..blendMode = BlendMode.colorBurn
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
        }
      }

      // ==========================================
      // 2. BLUSH LAYER
      // ==========================================
      if (config.blushColor != Colors.transparent) {
        final leftCheek = Offset(leftBox + widthBox * 0.25, topBox + heightBox * 0.6);
        final rightCheek = Offset(leftBox + widthBox * 0.75, topBox + heightBox * 0.6);
        final radius = widthBox * 0.15;
        final Paint blushPaint = Paint()..blendMode = BlendMode.multiply;

        blushPaint.shader = RadialGradient(colors: [config.blushColor.withOpacity(config.blushOpacity), Colors.transparent])
            .createShader(Rect.fromCircle(center: leftCheek, radius: radius));
        canvas.drawCircle(leftCheek, radius, blushPaint);

        blushPaint.shader = RadialGradient(colors: [config.blushColor.withOpacity(config.blushOpacity), Colors.transparent])
            .createShader(Rect.fromCircle(center: rightCheek, radius: radius));
        canvas.drawCircle(rightCheek, radius, blushPaint);
      }

      // ==========================================
      // 3. EYESHADOW LAYER
      // ==========================================
      if (leftEye != null && rightEye != null && config.eyeshadowColor != Colors.transparent) {
        final Paint shadowPaint = Paint()
          ..color = config.eyeshadowColor.withOpacity(config.eyeshadowOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

        for (var eyeContour in [leftEye, rightEye]) {
          final Path shadowPath = Path();
          final points = eyeContour.points.map(transformPoint).toList();
          if (points.isNotEmpty) {
            final halfLength = (points.length / 2).floor();
            final topLidPoints = points.sublist(0, halfLength);
            
            shadowPath.moveTo(topLidPoints.first.dx, topLidPoints.first.dy - 2);
            for (var p in topLidPoints) {
              shadowPath.lineTo(p.dx, p.dy - 8); 
            }
            for (var p in topLidPoints.reversed) {
              shadowPath.lineTo(p.dx, p.dy);
            }
            shadowPath.close();
            canvas.drawPath(shadowPath, shadowPaint);
          }
        }
      }

      // ==========================================
      // 4. EYELINER LAYER
      // ==========================================
      if (leftEye != null && rightEye != null && config.eyelinerColor != Colors.transparent) {
        final Paint linerPaint = Paint()
          ..color = config.eyelinerColor.withOpacity(config.eyelinerOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

        for (var eyeContour in [leftEye, rightEye]) {
          final points = eyeContour.points.map(transformPoint).toList();
          if (points.isNotEmpty) {
            final halfLength = (points.length / 2).floor();
            final topLidPoints = points.sublist(0, halfLength);
            
            if (topLidPoints.length > 1) {
              final Path linerPath = Path();
              linerPath.moveTo(topLidPoints.first.dx, topLidPoints.first.dy);
              for (int i = 1; i < topLidPoints.length; i++) {
                linerPath.lineTo(topLidPoints[i].dx, topLidPoints[i].dy);
              }
              canvas.drawPath(linerPath, linerPaint);
            }
          }
        }
      }

      // ==========================================
      // 5. CONTOUR LAYER
      // ==========================================
      if (config.contourColor != Colors.transparent) {
        final Paint contourPaint = Paint()..blendMode = BlendMode.darken;
        final leftHollow = Offset(leftBox + widthBox * 0.15, topBox + heightBox * 0.68);
        final rightHollow = Offset(leftBox + widthBox * 0.85, topBox + heightBox * 0.68);
        final cr = widthBox * 0.14;

        contourPaint.shader = RadialGradient(colors: [config.contourColor.withOpacity(config.contourOpacity), Colors.transparent])
            .createShader(Rect.fromCircle(center: leftHollow, radius: cr));
        canvas.drawOval(Rect.fromCenter(center: leftHollow, width: cr * 1.5, height: cr * 0.5), contourPaint);

        contourPaint.shader = RadialGradient(colors: [config.contourColor.withOpacity(config.contourOpacity), Colors.transparent])
            .createShader(Rect.fromCircle(center: rightHollow, radius: cr));
        canvas.drawOval(Rect.fromCenter(center: rightHollow, width: cr * 1.5, height: cr * 0.5), contourPaint);
      }

      // ========================================================
      // 6. SHORTCUT PLATFORM: JEWELRY (NATH & TEEKA IMAGE ASSETS)
      // ========================================================
      if (config.jewelryColor != Colors.transparent) {
        // Find center-midline anchor using the stable top of the nose bridge
        Offset midFaceAnchor = Offset(leftBox + widthBox * 0.5, topBox + heightBox * 0.42);
        if (noseBridge != null && noseBridge.points.isNotEmpty) {
          midFaceAnchor = transformPoint(noseBridge.points.first);
        }

        // A. FOREHEAD TEEKA OVERLAY SHORTCUT
        if (teekaImage != null) {
          double teekaW = widthBox * 0.20; 
          double teekaH = teekaW * (teekaImage!.height / teekaImage!.width);

          Rect teekaRect = Rect.fromLTWH(
            midFaceAnchor.dx - (teekaW / 2),
            topBox + (heightBox * 0.12), // Positions safely in upper forehead zone
            teekaW,
            teekaH,
          );

          canvas.drawImageRect(
            teekaImage!,
            Rect.fromLTWH(0, 0, teekaImage!.width.toDouble(), teekaImage!.height.toDouble()),
            teekaRect,
            Paint()..isAntiAlias = true..filterQuality = FilterQuality.high,
          );
        }

        // B. BRIDAL NATH (NOSE RING) OVERLAY SHORTCUT
        if (nathImage != null) {
          double nathW = widthBox * 0.30;
          double nathH = nathW * (nathImage!.height / nathImage!.width);

          Rect nathRect = Rect.fromLTWH(
            midFaceAnchor.dx - (nathW * 0.6), // Offsets automatically toward left nostril/cheek
            midFaceAnchor.dy + (heightBox * 0.08), 
            nathW,
            nathH,
          );

          canvas.drawImageRect(
            nathImage!,
            Rect.fromLTWH(0, 0, nathImage!.width.toDouble(), nathImage!.height.toDouble()),
            nathRect,
            Paint()..isAntiAlias = true..filterQuality = FilterQuality.high,
          );
        }
      }

      // ========================================================
      // 7. SHORTCUT PLATFORM: BRIDAL MEHNDI (IMAGE ASSET BROW STRIP)
      // ========================================================
      if (config.mehndiColor != Colors.transparent && mehndiImage != null) {
        Offset midFaceAnchor = Offset(leftBox + widthBox * 0.5, topBox + heightBox * 0.42);
        if (noseBridge != null && noseBridge.points.isNotEmpty) {
          midFaceAnchor = transformPoint(noseBridge.points.first);
        }

        double mehndiW = widthBox * 0.65; // Arches flawlessly across full forehead width
        double mehndiH = mehndiW * (mehndiImage!.height / mehndiImage!.width);

        Rect mehndiRect = Rect.fromLTWH(
          midFaceAnchor.dx - (mehndiW / 2),
          midFaceAnchor.dy - mehndiH - 4, // Anchored naturally directly over eyebrows
          mehndiW,
          mehndiH,
        );

        canvas.drawImageRect(
          mehndiImage!,
          Rect.fromLTWH(0, 0, mehndiImage!.width.toDouble(), mehndiImage!.height.toDouble()),
          mehndiRect,
          Paint()
            ..isAntiAlias = true
            ..filterQuality = FilterQuality.high
            ..colorFilter = ColorFilter.mode(config.mehndiColor.withOpacity(config.mehndiOpacity), BlendMode.srcATop),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant MakeupPainter oldDelegate) => true;
}