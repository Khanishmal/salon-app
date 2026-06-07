// lib/painters/makeup_painter.dart
import 'dart:math'; // FIXED: Added import to resolve the 'Undefined class Point' error
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/makeup_configuration.dart';

class MakeupPainter extends CustomPainter {
  final List<Face> faces;
  final MakeupConfiguration config;
  final Size absoluteImageSize;
  final int rotation;

  MakeupPainter({
    required this.faces,
    required this.config,
    required this.absoluteImageSize,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final face in faces) {
      final double scaleX = size.width / (rotation == 90 || rotation == 270 ? absoluteImageSize.height : absoluteImageSize.width);
      final double scaleY = size.height / (rotation == 90 || rotation == 270 ? absoluteImageSize.width : absoluteImageSize.height);

      // Converts ML Kit's Point<int> data cleanly into native Flutter Offset layout vectors
      Offset scalePoint(Point<int> point) {
        return Offset(point.x.toDouble() * scaleX, point.y.toDouble() * scaleY);
      }

      // --- 1. PROFESSIONAL FOUNDATION LAYER ---
      if (config.foundationColor != Colors.transparent) {
        final contour = face.contours[FaceContourType.face];
        if (contour != null && contour.points.isNotEmpty) {
          final path = Path()..moveTo(scalePoint(contour.points[0]).dx, scalePoint(contour.points[0]).dy);
          for (var i = 1; i < contour.points.length; i++) {
            path.lineTo(scalePoint(contour.points[i]).dx, scalePoint(contour.points[i]).dy);
          }
          path.close();
          final paint = Paint()
            ..color = config.foundationColor.withOpacity(config.foundationOpacity)
            ..style = PaintingStyle.fill
            ..imageFilter = ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8);
          canvas.drawPath(path, paint);
        }
      }

      // --- 2. PRECISE LIPSTICK MAPPING ---
      if (config.lipstickColor != Colors.transparent) {
        final upperLip = face.contours[FaceContourType.upperLipTop];
        final lowerLip = face.contours[FaceContourType.lowerLipBottom];
        
        if (upperLip != null && lowerLip != null && upperLip.points.isNotEmpty && lowerLip.points.isNotEmpty) {
          final lipPath = Path();
          lipPath.moveTo(scalePoint(upperLip.points.first).dx, scalePoint(upperLip.points.first).dy);
          for (var pt in upperLip.points) {
            lipPath.lineTo(scalePoint(pt).dx, scalePoint(pt).dy);
          }
          for (var pt in lowerLip.points.reversed) {
            lipPath.lineTo(scalePoint(pt).dx, scalePoint(pt).dy);
          }
          lipPath.close();

          final paint = Paint()
            ..color = config.lipstickColor.withOpacity(config.lipstickOpacity)
            ..style = PaintingStyle.fill
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
          
          canvas.drawPath(lipPath, paint);
        }
      }

      // --- 3. CONTOUR WORKSPACE MODULE ---
      if (config.contourColor != Colors.transparent) {
        final leftCheek = face.contours[FaceContourType.leftCheek];
        final rightCheek = face.contours[FaceContourType.rightCheek];
        final paint = Paint()
          ..color = config.contourColor.withOpacity(config.contourOpacity)
          ..style = PaintingStyle.fill
          ..imageFilter = ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12);

        if (leftCheek != null && leftCheek.points.isNotEmpty) {
          final p = Path()..addPolygon(leftCheek.points.map((e) => scalePoint(e)).toList(), true);
          canvas.drawPath(p, paint);
        }
        if (rightCheek != null && rightCheek.points.isNotEmpty) {
          final p = Path()..addPolygon(rightCheek.points.map((e) => scalePoint(e)).toList(), true);
          canvas.drawPath(p, paint);
        }
      }
      
      // --- 4. BLUSH LAYER ---
      if (config.blushColor != Colors.transparent) {
        final leftCheekLandmark = face.landmarks[FaceLandmarkType.leftCheek];
        final rightCheekLandmark = face.landmarks[FaceLandmarkType.rightCheek];
        final paint = Paint()
          ..color = config.blushColor.withOpacity(config.blushOpacity)
          ..style = PaintingStyle.fill
          ..imageFilter = ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15);

        if (leftCheekLandmark != null) {
          canvas.drawCircle(scalePoint(leftCheekLandmark.position), size.width * 0.12, paint);
        }
        if (rightCheekLandmark != null) {
          canvas.drawCircle(scalePoint(rightCheekLandmark.position), size.width * 0.12, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MakeupPainter oldDelegate) => true;
}