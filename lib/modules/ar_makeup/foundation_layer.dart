import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FoundationLayer {
  static void draw({
    required Canvas canvas,
    required Face face,
    required Color color,
    required double opacity,
    required Offset Function(Point<int>, String) transform,
  }) {
    if (color == Colors.transparent || opacity <= 0.0) return;

    final faceContour = face.contours[FaceContourType.face];
    if (faceContour == null || faceContour.points.isEmpty) return;

    final List<Offset> points = [];
    for (int i = 0; i < faceContour.points.length; i++) {
      points.add(transform(faceContour.points[i], 'face_perimeter_$i'));
    }

    final Path foundationPath = Path();
    foundationPath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      foundationPath.lineTo(points[i].dx, points[i].dy);
    }
    foundationPath.close();

    final Paint foundationPaint = Paint()
      ..color = color.withOpacity(opacity)
      ..blendMode = BlendMode.softLight
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0)
      ..style = PaintingStyle.fill;

    canvas.drawPath(foundationPath, foundationPaint);
  }
}