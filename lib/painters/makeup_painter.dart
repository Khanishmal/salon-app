import 'dart:math';
import 'package:flutter/material.dart';
// If using google_mlkit_face_detection, ensure it's imported:
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'; 
import '../models/makeup_configuration.dart';

// Assuming an Enum representation matching your ML infrastructure framework
enum FaceContourType {
  face,
  leftEyeTopBoundary,  // Fixed missing constants
  rightEyeTopBoundary, // Fixed missing constants
  leftEye,
  rightEye,
  upperLipTop,
  lowerLipBottom
}

class MakeupPainter extends CustomPainter {
  final List<Map<FaceContourType, List<Point<int>>>> faces;
  final MakeupConfiguration config;

  MakeupPainter({required this.faces, required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    if (faces.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (var face in faces) {
      // Logic utilizing leftEyeTopBoundary and rightEyeTopBoundary
      if (config.eyeshadowEnabled) {
        paint.color = config.eyeshadowColor.withOpacity(config.eyeshadowOpacity);
        
        final leftEyePoints = face[FaceContourType.leftEyeTopBoundary];
        if (leftEyePoints != null && leftEyePoints.isNotEmpty) {
          final path = Path();
          path.moveTo(leftEyePoints.first.x.toDouble(), leftEyePoints.first.y.toDouble());
          for (var pt in leftEyePoints) {
            path.lineTo(pt.x.toDouble(), pt.y.toDouble());
          }
          canvas.drawPath(path, paint);
        }

        final rightEyePoints = face[FaceContourType.rightEyeTopBoundary];
        if (rightEyePoints != null && rightEyePoints.isNotEmpty) {
          final path = Path();
          path.moveTo(rightEyePoints.first.x.toDouble(), rightEyePoints.first.y.toDouble());
          for (var pt in rightEyePoints) {
            path.lineTo(pt.x.toDouble(), pt.y.toDouble());
          }
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MakeupPainter oldDelegate) => true;
}