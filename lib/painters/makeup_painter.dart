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
  final double compareSliderX;
  final bool isCompareMode;
  final bool isCapturing;

  MakeupPainter({
    required this.faces,
    required this.config,
    required this.absoluteImageSize,
    required this.compareSliderX,
    required this.isCompareMode,
    this.isCapturing = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faces.isEmpty) return;

    for (final Face face in faces) {
      final double scaleX = size.width / absoluteImageSize.height;
      final double scaleY = size.height / absoluteImageSize.width;

      Offset transformPoint(Point<int> point) {
        return Offset(size.width - (point.x * scaleX), point.y * scaleY);
      }

      final boundingBox = face.boundingBox;
      final double leftBox = size.width - (boundingBox.right * scaleX);
      final double widthBox = boundingBox.width * scaleX;
      final double topBox = boundingBox.top * scaleY;
      final double heightBox = boundingBox.height * scaleY;

      // Extract contours
      final faceContour = face.contours[FaceContourType.face];
      final upperLipTop = face.contours[FaceContourType.upperLipTop];
      final upperLipBottom = face.contours[FaceContourType.upperLipBottom];
      final lowerLipTop = face.contours[FaceContourType.lowerLipTop];
      final lowerLipBottom = face.contours[FaceContourType.lowerLipBottom];
      final leftEye = face.contours[FaceContourType.leftEye];
      final rightEye = face.contours[FaceContourType.rightEye];
      final leftEyebrow = face.contours[FaceContourType.leftEyebrowTop];
      final rightEyebrow = face.contours[FaceContourType.rightEyebrowTop];

      canvas.save();

      // Split mode clipping
      if (isCompareMode && !isCapturing) {
        final double splitX = size.width * compareSliderX;
        canvas.clipRect(Rect.fromLTWH(splitX, 0, size.width - splitX, size.height));
      }

      // Apply intensity multiplier
      final intensity = config.intensity;

      // ==========================================
      // 1. BRONZER - Warmth & Definition (Multiply Blend)
      // ==========================================
      if (faceContour != null && config.bronzerColor != Colors.transparent) {
        final Path facePath = _createContourPath(faceContour, transformPoint);
        canvas.drawPath(
          facePath,
          Paint()
            ..color = config.bronzerColor.withOpacity(config.bronzerOpacity * intensity)
            ..blendMode = BlendMode.multiply
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25.0),
        );
      }

      // ==========================================
      // 2. FOUNDATION - Base Coverage (Soft Light Blend)
      // ==========================================
      if (faceContour != null && config.foundationColor != Colors.transparent) {
        final Path facePath = _createContourPath(faceContour, transformPoint);
        canvas.drawPath(
          facePath,
          Paint()
            ..color = config.foundationColor.withOpacity(config.foundationOpacity * intensity)
            ..blendMode = BlendMode.softLight
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20.0),
        );
      }

      // ==========================================
      // 3. HIGHLIGHTER - Glow Points
      // ==========================================
      if (config.highlighterColor != Colors.transparent) {
        final Paint highlighterPaint = Paint()
          ..color = config.highlighterColor.withOpacity(config.highlighterOpacity * intensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);

        final leftCheekHighlight = Offset(leftBox + widthBox * 0.2, topBox + heightBox * 0.42);
        final rightCheekHighlight = Offset(leftBox + widthBox * 0.8, topBox + heightBox * 0.42);
        final radius = widthBox * 0.08;
        
        canvas.drawCircle(leftCheekHighlight, radius, highlighterPaint);
        canvas.drawCircle(rightCheekHighlight, radius, highlighterPaint);
        
        if (faceContour != null) {
          final noseTip = Offset(leftBox + widthBox * 0.5, topBox + heightBox * 0.5);
          final noseHighlight = Paint()
            ..color = config.highlighterColor.withOpacity(config.highlighterOpacity * intensity * 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
          canvas.drawCircle(noseTip, widthBox * 0.03, noseHighlight);
        }
      }

      // ==========================================
      // 4. EYEBROWS - Natural Color Enhancement
      // ==========================================
      if (leftEyebrow != null && rightEyebrow != null && config.eyebrowColor != Colors.transparent) {
        final Paint eyebrowPaint = Paint()
          ..color = config.eyebrowColor.withOpacity(config.eyebrowOpacity * intensity * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

        for (var eyebrow in [leftEyebrow, rightEyebrow]) {
          final points = eyebrow.points.map(transformPoint).toList();
          if (points.isNotEmpty && points.length > 2) {
            final Path fillPath = Path();
            fillPath.moveTo(points.first.dx, points.first.dy - 3);
            for (var p in points) {
              fillPath.lineTo(p.dx, p.dy - 3);
            }
            for (var p in points.reversed) {
              fillPath.lineTo(p.dx, p.dy + 3);
            }
            fillPath.close();
            canvas.drawPath(fillPath, eyebrowPaint);
          }
        }
      }

      // ==========================================
      // 5. EYESHADOW - Rich Color Application
      // ==========================================
      if (leftEye != null && rightEye != null && config.eyeshadowColor != Colors.transparent) {
        final Paint shadowPaint = Paint()
          ..color = config.eyeshadowColor.withOpacity(config.eyeshadowOpacity * intensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);

        for (var eyeContour in [leftEye, rightEye]) {
          final points = eyeContour.points.map(transformPoint).toList();
          if (points.isNotEmpty) {
            final halfLength = (points.length / 2).floor();
            final topLidPoints = points.sublist(0, halfLength);
            
            if (topLidPoints.isNotEmpty) {
              final Path shadowPath = Path();
              shadowPath.moveTo(topLidPoints.first.dx, topLidPoints.first.dy - 2);
              for (var p in topLidPoints) {
                shadowPath.lineTo(p.dx, p.dy - 25);
              }
              for (var p in topLidPoints.reversed) {
                shadowPath.lineTo(p.dx, p.dy);
              }
              shadowPath.close();
              canvas.drawPath(shadowPath, shadowPaint);
            }
          }
        }
      }

      // ==========================================
      // 6. EYELINER - Precise Liner
      // ==========================================
      if (leftEye != null && rightEye != null && config.eyelinerColor != Colors.transparent) {
        final Paint linerPaint = Paint()
          ..color = config.eyelinerColor.withOpacity(config.eyelinerOpacity * intensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;

        for (var eyeContour in [leftEye, rightEye]) {
          final points = eyeContour.points.map(transformPoint).toList();
          if (points.isNotEmpty) {
            final halfLength = (points.length / 2).floor();
            final topPoints = points.sublist(0, halfLength);
            
            if (topPoints.length > 2) {
              final Path linerPath = Path();
              linerPath.moveTo(topPoints.first.dx, topPoints.first.dy);
              for (int i = 1; i < topPoints.length; i++) {
                linerPath.lineTo(topPoints[i].dx, topPoints[i].dy);
              }
              canvas.drawPath(linerPath, linerPaint);
            }
          }
        }
      }

      // ==========================================
      // 7. BLUSH - Soft Gradient Application
      // ==========================================
      if (config.blushColor != Colors.transparent) {
        final leftCheek = Offset(leftBox + widthBox * 0.25, topBox + heightBox * 0.55);
        final rightCheek = Offset(leftBox + widthBox * 0.75, topBox + heightBox * 0.55);
        final radius = widthBox * 0.12;
        
        final Paint blushPaint = Paint()..blendMode = BlendMode.multiply;
        
        final leftGradient = RadialGradient(
          colors: [
            config.blushColor.withOpacity(config.blushOpacity * intensity * 0.7),
            config.blushColor.withOpacity(config.blushOpacity * intensity * 0.2),
            Colors.transparent,
          ],
          radius: 1.8,
        );
        blushPaint.shader = leftGradient.createShader(
          Rect.fromCircle(center: leftCheek, radius: radius)
        );
        canvas.drawCircle(leftCheek, radius, blushPaint);
        
        final rightGradient = RadialGradient(
          colors: [
            config.blushColor.withOpacity(config.blushOpacity * intensity * 0.7),
            config.blushColor.withOpacity(config.blushOpacity * intensity * 0.2),
            Colors.transparent,
          ],
          radius: 1.8,
        );
        blushPaint.shader = rightGradient.createShader(
          Rect.fromCircle(center: rightCheek, radius: radius)
        );
        canvas.drawCircle(rightCheek, radius, blushPaint);
      }

      // ==========================================
      // 8. LIPSTICK - Color Burn Blend for Natural Texture
      // ==========================================
      if (config.lipstickColor != Colors.transparent) {
        final Paint lipstickPaint = Paint()
          ..color = config.lipstickColor.withOpacity(config.lipstickOpacity * intensity)
          ..blendMode = BlendMode.colorBurn
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

        if (upperLipTop != null && upperLipBottom != null) {
          final Path upperLipPath = _createLipPath(upperLipTop, upperLipBottom, transformPoint);
          canvas.drawPath(upperLipPath, lipstickPaint);
        }

        if (lowerLipTop != null && lowerLipBottom != null) {
          final Path lowerLipPath = _createLipPath(lowerLipTop, lowerLipBottom, transformPoint);
          canvas.drawPath(lowerLipPath, lipstickPaint);
        }
        
        // Lip highlight
        if (lowerLipTop != null) {
          final lowerPoints = lowerLipTop.points.map(transformPoint).toList();
          if (lowerPoints.isNotEmpty) {
            final centerX = lowerPoints.reduce((a, b) => a.dx < b.dx ? a : b).dx +
                           (lowerPoints.reduce((a, b) => a.dx > b.dx ? a : b).dx - 
                            lowerPoints.reduce((a, b) => a.dx < b.dx ? a : b).dx) / 2;
            final centerY = lowerPoints.reduce((a, b) => a.dy < b.dy ? a : b).dy +
                           (lowerPoints.reduce((a, b) => a.dy > b.dy ? a : b).dy - 
                            lowerPoints.reduce((a, b) => a.dy < b.dy ? a : b).dy) / 2;
            
            final Paint highlightPaint = Paint()
              ..color = Colors.white.withOpacity(0.15 * intensity)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
            
            canvas.drawCircle(
              Offset(centerX, centerY),
              widthBox * 0.035,
              highlightPaint,
            );
          }
        }
      }

      canvas.restore();
    }
  }

  Path _createContourPath(FaceContour contour, Offset Function(Point<int>) transform) {
    final Path path = Path();
    final points = contour.points.map(transform).toList();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (var p in points) {
        path.lineTo(p.dx, p.dy);
      }
      path.close();
    }
    return path;
  }

  Path _createLipPath(FaceContour top, FaceContour bottom, Offset Function(Point<int>) transform) {
    final Path path = Path();
    final topPoints = top.points.map(transform).toList();
    final bottomPoints = bottom.points.map(transform).toList();
    
    if (topPoints.isNotEmpty && bottomPoints.isNotEmpty) {
      path.moveTo(topPoints.first.dx, topPoints.first.dy);
      for (var p in topPoints) {
        path.lineTo(p.dx, p.dy);
      }
      for (var p in bottomPoints.reversed) {
        path.lineTo(p.dx, p.dy);
      }
      path.close();
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant MakeupPainter oldDelegate) {
    return oldDelegate.faces != faces ||
           oldDelegate.config != config ||
           oldDelegate.isCompareMode != isCompareMode ||
           oldDelegate.compareSliderX != compareSliderX ||
           oldDelegate.isCapturing != isCapturing;
  }
}