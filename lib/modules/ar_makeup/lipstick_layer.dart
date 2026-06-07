// lib/modules/ar_makeup/lipstick_layer.dart
import 'package:flutter/material.dart';

class LipstickLayerPainter extends CustomPainter {
  final List<Offset> outerLipContours;
  final List<Offset> innerLipContours;
  final Color lipstickColor;

  LipstickLayerPainter({
    required this.outerLipContours,
    required this.innerLipContours,
    required this.lipstickColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (outerLipContours.isEmpty) return;

    final paint = Paint()
      ..color = lipstickColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    final path = Path();
    path.moveTo(outerLipContours.first.dx, outerLipContours.first.dy);

    // FIX: Wrapped sequential looping blocks inside structural brackets
    for (int i = 1; i < outerLipContours.length; i++) {
      path.lineTo(outerLipContours[i].dx, outerLipContours[i].dy);
    }
    for (int i = innerLipContours.length - 1; i >= 0; i--) {
      path.lineTo(innerLipContours[i].dx, innerLipContours[i].dy);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LipstickLayerPainter oldDelegate) => true;
}