import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class BlushLayer {
  static void draw({
    required Canvas canvas,
    required Face face,
    required Color color,
    required double opacity,
    required double scaleX,
    required double scaleY,
    required Size canvasSize,
    required Offset Function(Offset, String) stabilizeRawOffset,
  }) {
    if (color == Colors.transparent || opacity <= 0.0) return;

    final boundingBox = face.boundingBox;
    final double leftBox = canvasSize.width - (boundingBox.right * scaleX);
    final double widthBox = boundingBox.width * scaleX;
    final double topBox = boundingBox.top * scaleY;
    final double heightBox = boundingBox.height * scaleY;

    // Temporal smoothing applied directly to cheek bounds matrix
    final Offset leftCheekRaw = Offset(leftBox + widthBox * 0.28, topBox + heightBox * 0.60);
    final Offset rightCheekRaw = Offset(leftBox + widthBox * 0.72, topBox + heightBox * 0.60);

    final Offset leftCheek = stabilizeRawOffset(leftCheekRaw, 'blush_L');
    final Offset rightCheek = stabilizeRawOffset(rightCheekRaw, 'blush_R');
    final radius = widthBox * 0.15;

    final Paint blushPaint = Paint()..blendMode = BlendMode.multiply;

    blushPaint.shader = RadialGradient(colors: [color.withOpacity(opacity), Colors.transparent])
        .createShader(Rect.fromCircle(center: leftCheek, radius: radius));
    canvas.drawCircle(leftCheek, radius, blushPaint);

    blushPaint.shader = RadialGradient(colors: [color.withOpacity(opacity), Colors.transparent])
        .createShader(Rect.fromCircle(center: rightCheek, radius: radius));
    canvas.drawCircle(rightCheek, radius, blushPaint);
  }
}