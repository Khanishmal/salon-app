// lib/painters/static_photo_makeup_painter.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/makeup_configuration.dart';

class StaticPhotoMakeupPainter extends CustomPainter {
  final List<Face> faces;
  final MakeupConfiguration config;
  final Size originalImageSize;
  final bool hideMakeup;

  StaticPhotoMakeupPainter({
    required this.faces,
    required this.config,
    required this.originalImageSize,
    required this.hideMakeup,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faces.isEmpty || hideMakeup) return;

    for (final Face face in faces) {
      final double scaleX = size.width / originalImageSize.width;
      final double scaleY = size.height / originalImageSize.height;

      Offset transformPoint(Point<int> point) {
        return Offset(point.x * scaleX, point.y * scaleY);
      }

      final boundingBox = face.boundingBox;
      final double leftBox = boundingBox.left * scaleX;
      final double widthBox = boundingBox.width * scaleX;
      final double topBox = boundingBox.top * scaleY;
      final double heightBox = boundingBox.height * scaleY;

      final faceContour = face.contours[FaceContourType.face];
      final upperLipTop = face.contours[FaceContourType.upperLipTop];
      final upperLipBottom = face.contours[FaceContourType.upperLipBottom];
      final lowerLipTop = face.contours[FaceContourType.lowerLipTop];
      final lowerLipBottom = face.contours[FaceContourType.lowerLipBottom];
      final leftEye = face.contours[FaceContourType.leftEye];
      final rightEye = face.contours[FaceContourType.rightEye];
      final leftEyebrow = face.contours[FaceContourType.leftEyebrowTop];
      final rightEyebrow = face.contours[FaceContourType.rightEyebrowTop];

      // Apply intensity multiplier
      final intensity = config.intensity != 0 ? config.intensity : 0.5;

      // ==========================================
      // 1. FOUNDATION
      // ==========================================
      if (faceContour != null && config.foundationColor != Colors.transparent) {
        final Path facePath = _createContourPath(faceContour, transformPoint);
        canvas.drawPath(
          facePath,
          Paint()
            ..color = config.foundationColor.withOpacity(config.foundationOpacity * intensity)
            ..blendMode = BlendMode.softLight
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0),
        );
      }

      // ==========================================
      // 2. EYEBROWS - Natural Color Enhancement
      // ==========================================
      if (leftEyebrow != null && rightEyebrow != null && config.eyebrowColor != Colors.transparent) {
        final Paint eyebrowPaint = Paint()
          ..color = config.eyebrowColor.withOpacity(config.eyebrowOpacity * intensity * 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

        for (var eyebrow in [leftEyebrow, rightEyebrow]) {
          final points = eyebrow.points.map(transformPoint).toList();
          if (points.isNotEmpty && points.length > 2) {
            final Path fillPath = Path();
            fillPath.moveTo(points.first.dx, points.first.dy - 2);
            for (var p in points) {
              fillPath.lineTo(p.dx, p.dy - 2);
            }
            for (var p in points.reversed) {
              fillPath.lineTo(p.dx, p.dy + 2);
            }
            fillPath.close();
            canvas.drawPath(fillPath, eyebrowPaint);
          }
        }
      }

      // ==========================================
      // 3. EYESHADOW
      // ==========================================
      if (leftEye != null && rightEye != null && config.eyeshadowColor != Colors.transparent) {
        final Paint shadowPaint = Paint()
          ..color = config.eyeshadowColor.withOpacity(config.eyeshadowOpacity * intensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

        for (var eyeContour in [leftEye, rightEye]) {
          final points = eyeContour.points.map(transformPoint).toList();
          if (points.isNotEmpty) {
            final halfLength = (points.length / 2).floor();
            final topLidPoints = points.sublist(0, halfLength);
            
            if (topLidPoints.isNotEmpty) {
              final Path shadowPath = Path();
              shadowPath.moveTo(topLidPoints.first.dx, topLidPoints.first.dy - 2);
              for (var p in topLidPoints) {
                shadowPath.lineTo(p.dx, p.dy - 20);
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
      // 4. EYELINER
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
      // 5. BLUSH
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
      // 6. LIPSTICK
      // ==========================================
      if (config.lipstickColor != Colors.transparent) {
        final Paint lipstickPaint = Paint()
          ..color = config.lipstickColor.withOpacity(config.lipstickOpacity * intensity)
          ..blendMode = BlendMode.colorBurn
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

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
  bool shouldRepaint(covariant StaticPhotoMakeupPainter oldDelegate) {
    return oldDelegate.faces != faces ||
           oldDelegate.config != config ||
           oldDelegate.hideMakeup != hideMakeup;
  }
}