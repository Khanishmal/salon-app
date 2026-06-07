import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class ContourLayer {
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

    final Offset leftHollowRaw = Offset(leftBox + widthBox * 0.12, topBox + heightBox * 0.68);
    final Offset rightHollowRaw = Offset(leftBox + widthBox * 0.88, topBox + heightBox * 0.68);

    final Offset leftHollow = stabilizeRawOffset(leftHollowRaw, 'contour_L');
    final Offset rightHollow = stabilizeRawOffset(rightHollowRaw, 'contour_R');
    final cr = widthBox * 0.14;

    final Paint contourPaint = Paint()..blendMode = BlendMode.darken;
    
    contourPaint.shader = RadialGradient(colors: [color.withOpacity(opacity), Colors.transparent])
        .createShader(Rect.fromCircle(center: leftHollow, radius: cr));
    canvas.drawOval(Rect.fromCenter(center: leftHollow, width: cr * 1.5, height: cr * 0.5), contourPaint);

    contourPaint.shader = RadialGradient(colors: [color.withOpacity(opacity), Colors.transparent])
        .createShader(Rect.fromCircle(center: rightHollow, radius: cr));
    canvas.drawOval(Rect.fromCenter(center: rightHollow, width: cr * 1.5, height: cr * 0.5), contourPaint);
  }
}