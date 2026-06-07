import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class EyeshadowLayer {
  static void draw({
    required Canvas canvas,
    required Face face,
    required Color color,
    required double opacity,
    required Offset Function(Point<int>, String) transform,
  }) {
    if (color == Colors.transparent || opacity <= 0.0) return;

    final leftEye = face.contours[FaceContourType.leftEye];
    final rightEye = face.contours[FaceContourType.rightEye];

    if (leftEye == null || rightEye == null) return;

    final Paint shadowPaint = Paint()
      ..color = color.withOpacity(opacity)
      ..blendMode = BlendMode.multiply
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

    // Apply tracking on both eyes
    _drawEyeShadow(canvas, leftEye, 'left', shadowPaint, transform);
    _drawEyeShadow(canvas, rightEye, 'right', shadowPaint, transform);
  }

  static void _drawEyeShadow(Canvas canvas, FaceContour eyeContour, String side, Paint paint, Offset Function(Point<int>, String) transform) {
    final Path shadowPath = Path();
    final List<Offset> points = [];
    
    for (int i = 0; i < eyeContour.points.length; i++) {
      points.add(transform(eyeContour.points[i], '${side}_shadow_$i'));
    }
    
    if (points.isEmpty) return;

    final halfLength = (points.length / 2).floor();
    final topLidPoints = points.sublist(0, halfLength);

    // Build upper eyelid shading volume maps
    shadowPath.moveTo(topLidPoints.first.dx, topLidPoints.first.dy - 2);
    for (var p in topLidPoints) {
      shadowPath.lineTo(p.dx, p.dy - 12); 
    }
    for (var p in topLidPoints.reversed) {
      shadowPath.lineTo(p.dx, p.dy);
    }
    shadowPath.close();
    canvas.drawPath(shadowPath, paint);
  }
}