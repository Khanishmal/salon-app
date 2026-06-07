import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class JewelryTryOnPainter extends CustomPainter {
  final List<Face> faces;
  final Size absoluteImageSize;
  final ui.Image? nathImage;
  final ui.Image? teekaImage;
  final ui.Image? earringsImage;

  // $1 Filter Smoothing Weights to prevent artifact jittering during movement
  static const double kSmoothingAlpha = 0.35;
  static Map<int, Offset> _smoothedNoseTip = {};
  static Map<int, Offset> _smoothedForehead = {};

  JewelryTryOnPainter({
    required this.faces,
    required this.absoluteImageSize,
    this.nathImage,
    this.teekaImage,
    this.earringsImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final face in faces) {
      final double scaleX = size.width / absoluteImageSize.height;
      final double scaleY = size.height / absoluteImageSize.width;

      Offset transformPoint(Point<int> point) {
        return Offset(size.width - (point.x * scaleX), point.y * scaleY);
      }

      final int id = face.trackingId ?? 0;
      final boundingBox = face.boundingBox;
      final double leftBox = size.width - (boundingBox.right * scaleX);
      final double widthBox = boundingBox.width * scaleX;
      final double topBox = boundingBox.top * scaleY;
      final double heightBox = boundingBox.height * scaleY;

      // Extract precise anchors 
      final noseBridge = face.contours[FaceContourType.noseBridge];
      Offset rawNoseTip = Offset(leftBox + widthBox * 0.5, topBox + heightBox * 0.55);
      if (noseBridge != null && noseBridge.points.isNotEmpty) {
        rawNoseTip = transformPoint(noseBridge.points.last);
      }

      Offset rawForehead = Offset(leftBox + widthBox * 0.5, topBox + heightBox * 0.15);
      if (face.contours[FaceContourType.face]?.points.isNotEmpty ?? false) {
        rawForehead = transformPoint(face.contours[FaceContourType.face]!.points.first);
      }

      // Apply Exponential Filter Pipeline
      _smoothedNoseTip[id] = Offset(
        ui.lerpDouble(_smoothedNoseTip[id]?.dx ?? rawNoseTip.dx, rawNoseTip.dx, kSmoothingAlpha)!,
        ui.lerpDouble(_smoothedNoseTip[id]?.dy ?? rawNoseTip.dy, rawNoseTip.dy, kSmoothingAlpha)!,
      );
      _smoothedForehead[id] = Offset(
        ui.lerpDouble(_smoothedForehead[id]?.dx ?? rawForehead.dx, rawForehead.dx, kSmoothingAlpha)!,
        ui.lerpDouble(_smoothedForehead[id]?.dy ?? rawForehead.dy, rawForehead.dy, kSmoothingAlpha)!,
      );

      final noseAnchor = _smoothedNoseTip[id]!;
      final foreheadAnchor = _smoothedForehead[id]!;

      // Render Forehead Maang Tikka Asset
      if (teekaImage != null) {
        double teekaW = widthBox * 0.28;
        double teekaH = teekaW * (teekaImage!.height / teekaImage!.width);
        Rect teekaRect = Rect.fromLTWH(
          foreheadAnchor.dx - (teekaW / 2),
          foreheadAnchor.dy + (heightBox * 0.05),
          teekaW,
          teekaH,
        );
        canvas.drawImageRect(
          teekaImage!,
          Rect.fromLTWH(0, 0, teekaImage!.width.toDouble(), teekaImage!.height.toDouble()),
          teekaRect,
          Paint()..isAntiAlias = true..filterQuality = FilterQuality.high,
        );
      }

      // Render Bridal Nath (Nose Ring offset cleanly to the left flank)
      if (nathImage != null) {
        double nathW = widthBox * 0.35;
        double nathH = nathW * (nathImage!.height / nathImage!.width);
        Rect nathRect = Rect.fromLTWH(
          noseAnchor.dx - (nathW * 0.72),
          noseAnchor.dy - (nathH * 0.2),
          nathW,
          nathH,
        );
        canvas.drawImageRect(
          nathImage!,
          Rect.fromLTWH(0, 0, nathImage!.width.toDouble(), nathImage!.height.toDouble()),
          nathRect,
          Paint()..isAntiAlias = true..filterQuality = FilterQuality.high,
        );
      }

      // Render Earrings balancing both margins
      if (earringsImage != null) {
        double earW = widthBox * 0.18;
        double earH = earW * (earringsImage!.height / earringsImage!.width);
        
        // Left Ear Overlay bounding zone
        canvas.drawImageRect(
          earringsImage!,
          Rect.fromLTWH(0, 0, earringsImage!.width.toDouble(), earringsImage!.height.toDouble()),
          Rect.fromLTWH(leftBox - (earW * 0.4), topBox + (heightBox * 0.55), earW, earH),
          Paint()..isAntiAlias = true,
        );

        // Right Ear Overlay bounding zone
        canvas.drawImageRect(
          earringsImage!,
          Rect.fromLTWH(0, 0, earringsImage!.width.toDouble(), earringsImage!.height.toDouble()),
          Rect.fromLTWH(leftBox + widthBox - (earW * 0.6), topBox + (heightBox * 0.55), earW, earH),
          Paint()..isAntiAlias = true,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant JewelryTryOnPainter oldDelegate) => true;
}