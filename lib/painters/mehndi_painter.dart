// lib/painters/mehndi_painter.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class MehndiPainter extends CustomPainter {
  final ui.Image? patternImage;
  final Color patternColor;
  final double opacity;
  final Size imageSize;

  MehndiPainter({
    required this.patternImage,
    required this.patternColor,
    required this.opacity,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (patternImage == null) return;

    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    // Apply mehndi pattern with color
    final Paint paint = Paint()
      ..color = patternColor.withOpacity(opacity)
      ..blendMode = BlendMode.srcATop
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    // Draw pattern over the image
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
      patternImage!,
      Rect.fromLTWH(0, 0, patternImage!.width.toDouble(), patternImage!.height.toDouble()),
      rect,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant MehndiPainter oldDelegate) {
    return oldDelegate.patternImage != patternImage ||
           oldDelegate.patternColor != patternColor ||
           oldDelegate.opacity != opacity;
  }
}