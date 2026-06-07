import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class EyelinerLayer {
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

    final Paint linerPaint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.darken;

    _drawLinerTrack(canvas, leftEye, 'left', linerPaint, transform);
    _drawLinerTrack(canvas, rightEye, 'right', linerPaint, transform);
  }

  static void _drawLinerTrack(Canvas canvas, FaceContour eyeContour, String side, Paint paint, Offset Function(Point<int>, String) transform) {
    final List<Offset> points = [];
    for (int i = 0; i < eyeContour.points.length; i++) {
      points.add(transform(eyeContour.points[i], '${side}_liner_$i'));
    }

    if (points.isEmpty) return;
    final halfLength = (points.length / 2).floor();
    final topLidPoints = points.sublist(0, halfLength);

    if (topLidPoints.length > 1) {
      final Path linerPath = Path();
      linerPath.moveTo(topLidPoints.first.dx, topLidPoints.first.dy);
      for (int i = 1; i < topLidPoints.length; i++) {
        linerPath.lineTo(topLidPoints[i].dx, topLidPoints[i].dy);
      }
      canvas.drawPath(linerPath, paint);
    }
  }
}