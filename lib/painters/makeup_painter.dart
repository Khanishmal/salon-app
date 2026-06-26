// lib/painters/makeup_painter.dart
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
        // Mirrored projection transformation sequence to perfectly handle front-camera raw stream coordinates
        return Offset(size.width - (point.x * scaleX), point.y * scaleY);
      }

      // Extract specific semantic contours unlocked by your ML Kit options
      final upperLipContour = face.contours[FaceContourType.upperLipTop];
      final lowerLipContour = face.contours[FaceContourType.lowerLipBottom];
      final leftEyeContour = face.contours[FaceContourType.leftEye];
      final rightEyeContour = face.contours[FaceContourType.rightEye];
      final noseBridgeContour = face.contours[FaceContourType.noseBridge];

      // ==========================================
      // 1. LIPSTICK LAYER (Dynamic Contour Paths)
      // ==========================================
      if (upperLipContour != null && lowerLipContour != null && config.lipstickColor != Colors.transparent) {
        final Path lipPath = Path();
        final List<Offset> points = [...upperLipContour.points, ...lowerLipContour.points.reversed].map(transformPoint).toList();
        if (points.isNotEmpty) {
          lipPath.moveTo(points.first.dx, points.first.dy);
          for (var p in points) {
            lipPath.lineTo(p.dx, p.dy);
          }
          lipPath.close();
          canvas.drawPath(
            lipPath, 
            Paint()
              ..color = config.lipstickColor.withOpacity(config.lipstickOpacity)
              ..blendMode = BlendMode.colorBurn // Preserves natural lip folds/highlights
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8) // Softens makeup margins
          );
        }
      }

      // ==========================================
      // 2. BLUSH & CONTOUR LANDMARK ANCHORS
      // ==========================================
      if (leftEyeContour != null && rightEyeContour != null && noseBridgeContour != null && leftEyeContour.points.isNotEmpty && rightEyeContour.points.isNotEmpty && noseBridgeContour.points.isNotEmpty) {
        final Offset leftEyeNode = transformPoint(leftEyeContour.points.first);
        final Offset rightEyeNode = transformPoint(rightEyeContour.points.first);
        final Offset noseBaseNode = transformPoint(noseBridgeContour.points.last);

        // Dynamically compute the face size to scale overlays automatically
        final double calculatedFaceWidth = (rightEyeNode.dx - leftEyeNode.dx).abs();
        final double blushRadius = calculatedFaceWidth * 0.22;

        // ── BLUSH APPLICATION LAYER ──
        if (config.blushColor != Colors.transparent) {
          final Offset leftCheekCenter = Offset(leftEyeNode.dx + (calculatedFaceWidth * 0.05), noseBaseNode.dy - (blushRadius * 0.2));
          final Offset rightCheekCenter = Offset(rightEyeNode.dx - (calculatedFaceWidth * 0.05), noseBaseNode.dy - (blushRadius * 0.2));

          final Paint blushPaint = Paint()..blendMode = BlendMode.multiply;

          // Left Cheek Gradient Blend
          blushPaint.shader = RadialGradient(colors: [config.blushColor.withOpacity(config.blushOpacity), Colors.transparent])
              .createShader(Rect.fromCircle(center: leftCheekCenter, radius: blushRadius));
          canvas.drawCircle(leftCheekCenter, blushRadius, blushPaint);

          // Right Cheek Gradient Blend
          blushPaint.shader = RadialGradient(colors: [config.blushColor.withOpacity(config.blushOpacity), Colors.transparent])
              .createShader(Rect.fromCircle(center: rightCheekCenter, radius: blushRadius));
          canvas.drawCircle(rightCheekCenter, blushRadius, blushPaint);
        }

        // ── SUB-ZYGOMATIC HOLLOW CONTOUR LAYER ──
        if (config.contourColor != Colors.transparent) {
          final Paint contourPaint = Paint()..blendMode = BlendMode.darken;
          final double contourW = blushRadius * 1.5;
          final double contourH = blushRadius * 0.5;

          // Left Jaw Hollows Positioning
          final Offset leftContourPos = Offset(leftEyeNode.dx - (calculatedFaceWidth * 0.08), noseBaseNode.dy + (blushRadius * 0.3));
          contourPaint.shader = RadialGradient(colors: [config.contourColor.withOpacity(config.contourOpacity), Colors.transparent])
              .createShader(Rect.fromCircle(center: leftContourPos, radius: contourW));
          canvas.drawOval(Rect.fromCenter(center: leftContourPos, width: contourW, height: contourH), contourPaint);

          // Right Jaw Hollows Positioning
          final Offset rightContourPos = Offset(rightEyeNode.dx + (calculatedFaceWidth * 0.08), noseBaseNode.dy + (blushRadius * 0.3));
          contourPaint.shader = RadialGradient(colors: [config.contourColor.withOpacity(config.contourOpacity), Colors.transparent])
              .createShader(Rect.fromCircle(center: rightContourPos, radius: contourW));
          canvas.drawOval(Rect.fromCenter(center: rightContourPos, width: contourW, height: contourH), contourPaint);
        }
      }

      // ==========================================
      // 3. EYESHADOW LAYER
      // ==========================================
      if (leftEyeContour != null && rightEyeContour != null && config.eyeshadowColor != Colors.transparent) {
        final Paint shadowPaint = Paint()
          ..color = config.eyeshadowColor.withOpacity(config.eyeshadowOpacity)
          ..blendMode = BlendMode.multiply
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

        for (var eyeContour in [leftEyeContour, rightEyeContour]) {
          final Path shadowPath = Path();
          final points = eyeContour.points.map(transformPoint).toList();
          if (points.isNotEmpty) {
            final halfLength = (points.length / 2).floor();
            final topLidPoints = points.sublist(0, halfLength);

            shadowPath.moveTo(topLidPoints.first.dx, topLidPoints.first.dy - 2);
            for (var p in topLidPoints) {
              shadowPath.lineTo(p.dx, p.dy - 9); // Curves the eyeshadow naturally along the brow bone
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
      if (leftEyeContour != null && rightEyeContour != null && config.eyelinerColor != Colors.transparent) {
        final Paint linerPaint = Paint()
          ..color = config.eyelinerColor.withOpacity(config.eyelinerOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        for (var eyeContour in [leftEyeContour, rightEyeContour]) {
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
      // 5. BRIDAL JEWELRY LAYER (Anchored Images)
      // ==========================================
      if (leftEyeContour != null && rightEyeContour != null && noseBridgeContour != null && noseBridgeContour.points.isNotEmpty) {
        final Offset leftEyeNode = transformPoint(leftEyeContour.points.first);
        final Offset rightEyeNode = transformPoint(rightEyeContour.points.first);
        final double referenceFaceWidth = (rightEyeNode.dx - leftEyeNode.dx).abs();

        final Offset glabellaAnchor = transformPoint(noseBridgeContour.points.first); // Top center point between eyebrows
        final Offset subNasalAnchor = transformPoint(noseBridgeContour.points.last);  // Base foundation anchor of nose structure

        final Paint jewelryPaint = Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high;

        // Maang Teeka Placement
        if (teekaImage != null && config.jewelryColor != Colors.transparent) {
          final double teekaWidth = referenceFaceWidth * 0.28;
          final double teekaHeight = teekaWidth * (teekaImage!.height / teekaImage!.width);
          final Rect teekaRect = Rect.fromLTWH(
            glabellaAnchor.dx - (teekaWidth / 2),
            glabellaAnchor.dy - (teekaHeight * 0.88), // Positions the jewelry cleanly on the forehead
            teekaWidth,
            teekaHeight,
          );
          canvas.drawImageRect(teekaImage!, Rect.fromLTWH(0, 0, teekaImage!.width.toDouble(), teekaImage!.height.toDouble()), teekaRect, jewelryPaint);
        }

        // Bridal Nath Ring Placement
        if (nathImage != null && config.jewelryColor != Colors.transparent) {
          final double nathWidth = referenceFaceWidth * 0.36;
          final double nathHeight = nathWidth * (nathImage!.height / nathImage!.width);
          final Rect nathRect = Rect.fromLTWH(
            subNasalAnchor.dx - (nathWidth * 0.55),
            subNasalAnchor.dy - (nathHeight * 0.25),
            nathWidth,
            nathHeight,
          );
          canvas.drawImageRect(nathImage!, Rect.fromLTWH(0, 0, nathImage!.width.toDouble(), nathImage!.height.toDouble()), nathRect, jewelryPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MakeupPainter oldDelegate) {
    return true; // Keeps the rendering loop responsive during camera frame updates
  }
}