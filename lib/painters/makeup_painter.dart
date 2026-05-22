// lib/painters/makeup_painter.dart
import 'dart:math'; // FIX: Provides the Point class definition
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class MakeupPainter extends CustomPainter {
  final List<Face> faces;
  final Color lipstickColor;
  final double lipstickOpacity;
  final Color blushColor;
  final double blushOpacity;
  final Size absoluteImageSize;
  final int rotation;

  MakeupPainter({
    required this.faces,
    required this.lipstickColor,
    required this.lipstickOpacity,
    required this.blushColor,
    required this.blushOpacity,
    required this.absoluteImageSize,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final Face face in faces) {
      // Scale mappings based on orientation translations
      final double scaleX = size.width / absoluteImageSize.height;
      final double scaleY = size.height / absoluteImageSize.width;

      Offset transformPoint(Point<int> point) {
        double x = point.x * scaleX;
        double y = point.y * scaleY;
        return Offset(size.width - x, y); // Perfectly mirrors the visual layout
      }

      // 1. Lipstick Fill
      final upperLip = face.contours[FaceContourType.upperLipTop];
      final lowerLip = face.contours[FaceContourType.lowerLipBottom];

      if (upperLip != null && lowerLip != null && lipstickColor != Colors.transparent) {
        final Path lipPath = Path();
        final List<Offset> lipPoints = [];

        for (final point in upperLip.points) {
          lipPoints.add(transformPoint(point));
        }
        for (final point in lowerLip.points.reversed) {
          lipPoints.add(transformPoint(point));
        }

        if (lipPoints.isNotEmpty) {
          lipPath.moveTo(lipPoints.first.dx, lipPoints.first.dy);
          for (var i = 1; i < lipPoints.length; i++) {
            lipPath.lineTo(lipPoints[i].dx, lipPoints[i].dy);
          }
          lipPath.close();

          final Paint lipPaint = Paint()
            ..color = lipstickColor.withOpacity(lipstickOpacity)
            ..style = PaintingStyle.fill
            ..blendMode = BlendMode.colorBurn
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

          canvas.drawPath(lipPath, lipPaint);
        }
      }

      // 2. Blush Circles
      if (blushColor != Colors.transparent) {
        final boundingBox = face.boundingBox;
        
        final double leftBox = size.width - (boundingBox.right * scaleX);
        final double widthBox = boundingBox.width * scaleX;
        final double topBox = boundingBox.top * scaleY;
        final double heightBox = boundingBox.height * scaleY;

        final Offset leftCheekCenter = Offset(leftBox + widthBox * 0.25, topBox + heightBox * 0.55);
        final Offset rightCheekCenter = Offset(leftBox + widthBox * 0.75, topBox + heightBox * 0.55);
        final double blushRadius = widthBox * 0.14;

        final Paint blushPaint = Paint()
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.multiply;

        blushPaint.shader = RadialGradient(
          colors: [blushColor.withOpacity(blushOpacity), Colors.transparent],
        ).createShader(Rect.fromCircle(center: leftCheekCenter, radius: blushRadius));
        canvas.drawCircle(leftCheekCenter, blushRadius, blushPaint);

        blushPaint.shader = RadialGradient(
          colors: [blushColor.withOpacity(blushOpacity), Colors.transparent],
        ).createShader(Rect.fromCircle(center: rightCheekCenter, radius: blushRadius));
        canvas.drawCircle(rightCheekCenter, blushRadius, blushPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MakeupPainter oldDelegate) {
    return true;
  }
}