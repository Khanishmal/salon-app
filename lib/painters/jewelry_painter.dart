// lib/painters/jewelry_painter.dart
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/jewelry_models.dart';

class JewelryPainter extends CustomPainter {
  final List<Face> faces;
  final Size originalImageSize;
  final List<String> selectedJewelryIds;
  final Map<String, ui.Image?> loadedImages;
  final Map<String, JewelryAsset> jewelryAssets;

  JewelryPainter({
    required this.faces,
    required this.originalImageSize,
    required this.selectedJewelryIds,
    required this.loadedImages,
    required this.jewelryAssets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faces.isEmpty) return;

    for (final Face face in faces) {
      final double scaleX = size.width / originalImageSize.width;
      final double scaleY = size.height / originalImageSize.height;

      Offset transformPoint(Point<int> point) {
        return Offset(point.x * scaleX, point.y * scaleY);
      }

      final boundingBox = face.boundingBox;
      final double faceWidth = boundingBox.width * scaleX;
      final double faceHeight = boundingBox.height * scaleY;
      final double leftBox = boundingBox.left * scaleX;
      final double topBox = boundingBox.top * scaleY;

      // Extract contours and landmarks
      final faceContour = face.contours[FaceContourType.face];
      final noseBridge = face.contours[FaceContourType.noseBridge];
      final leftEye = face.contours[FaceContourType.leftEye];
      final rightEye = face.contours[FaceContourType.rightEye];

      // Get landmarks for precise positioning - use only valid ones
      final noseBase = face.landmarks[FaceLandmarkType.noseBase];

      // Process each selected jewelry item
      for (final jewelryId in selectedJewelryIds) {
        final asset = jewelryAssets[jewelryId];
        if (asset == null) continue;
        
        final image = loadedImages[asset.assetPath];
        if (image == null) continue;

        final String category = asset.category;
        final double scale = asset.defaultScale;
        
        Paint paint = Paint()
          ..filterQuality = FilterQuality.high
          ..isAntiAlias = true;

        switch (category) {
          case 'Forehead':
            _drawForeheadJewelry(
              canvas, image, asset, 
              faceContour, noseBridge, 
              faceWidth, faceHeight,
              scale, transformPoint, paint
            );
            break;
          
          case 'Nose':
            _drawNoseJewelry(
              canvas, image, asset,
              noseBase, faceWidth, faceHeight,
              scale, transformPoint, paint
            );
            break;
          
          case 'Neck':
            _drawNeckJewelry(
              canvas, image, asset,
              faceContour, faceWidth, faceHeight,
              scale, transformPoint, paint
            );
            break;
          
          case 'Ears':
            _drawEarJewelry(
              canvas, image, asset,
              leftEye, rightEye,
              faceWidth, faceHeight,
              scale, transformPoint, paint
            );
            break;
        }
      }
    }
  }

  void _drawForeheadJewelry(
    Canvas canvas,
    ui.Image image,
    JewelryAsset asset,
    FaceContour? faceContour,
    FaceContour? noseBridge,
    double faceWidth,
    double faceHeight,
    double scale,
    Offset Function(Point<int>) transformPoint,
    Paint paint,
  ) {
    if (faceContour == null || faceContour.points.isEmpty) return;

    final contourPoints = faceContour.points;
    final int middleTopIndex = (contourPoints.length * 0.4).floor();
    final Offset foreheadTop = transformPoint(contourPoints[middleTopIndex]);

    Offset anchorPoint = foreheadTop;
    if (noseBridge != null && noseBridge.points.isNotEmpty) {
      final Offset noseTopPoint = transformPoint(noseBridge.points.first);
      anchorPoint = Offset(
        (foreheadTop.dx + noseTopPoint.dx) / 2,
        (foreheadTop.dy + noseTopPoint.dy) / 2 - (faceWidth * 0.06),
      );
    }

    // Apply offset
    final double offsetX = asset.offset['x'] ?? 0.0;
    final double offsetY = asset.offset['y'] ?? 0.0;
    anchorPoint = Offset(
      anchorPoint.dx + (offsetX * faceWidth),
      anchorPoint.dy + (offsetY * faceHeight),
    );

    final double width = faceWidth * scale;
    final double height = width * (image.height / image.width);

    final Rect rect = Rect.fromCenter(
      center: anchorPoint,
      width: width,
      height: height,
    );

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      paint,
    );
  }

  void _drawNoseJewelry(
    Canvas canvas,
    ui.Image image,
    JewelryAsset asset,
    FaceLandmark? noseBase,
    double faceWidth,
    double faceHeight,
    double scale,
    Offset Function(Point<int>) transformPoint,
    Paint paint,
  ) {
    if (noseBase == null) return;

    final Offset noseBasePoint = transformPoint(Point(
      noseBase.position.x.toInt(),
      noseBase.position.y.toInt(),
    ));

    final double width = faceWidth * scale;
    final double height = width * (image.height / image.width);

    final Offset anchorPoint = Offset(
      noseBasePoint.dx + (asset.offset['x'] ?? 0.0) * faceWidth,
      noseBasePoint.dy + (asset.offset['y'] ?? 0.0) * faceHeight,
    );

    final Rect rect = Rect.fromCenter(
      center: anchorPoint,
      width: width,
      height: height,
    );

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      paint,
    );
  }

  void _drawNeckJewelry(
    Canvas canvas,
    ui.Image image,
    JewelryAsset asset,
    FaceContour? faceContour,
    double faceWidth,
    double faceHeight,
    double scale,
    Offset Function(Point<int>) transformPoint,
    Paint paint,
  ) {
    if (faceContour == null || faceContour.points.isEmpty) return;

    final contourPoints = faceContour.points;
    final int middleBottomIndex = (contourPoints.length * 0.82).floor();
    final Offset neckPoint = transformPoint(contourPoints[middleBottomIndex]);

    final Offset anchorPoint = Offset(
      neckPoint.dx + (asset.offset['x'] ?? 0.0) * faceWidth,
      neckPoint.dy + (asset.offset['y'] ?? 0.0) * faceHeight,
    );

    final double width = faceWidth * scale * 0.7;
    final double height = width * (image.height / image.width);

    final Rect rect = Rect.fromCenter(
      center: anchorPoint,
      width: width,
      height: height,
    );

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      paint,
    );
  }

  void _drawEarJewelry(
    Canvas canvas,
    ui.Image image,
    JewelryAsset asset,
    FaceContour? leftEye,
    FaceContour? rightEye,
    double faceWidth,
    double faceHeight,
    double scale,
    Offset Function(Point<int>) transformPoint,
    Paint paint,
  ) {
    // Calculate ear positions from eye contours
    List<Offset> earPositions = [];

    if (leftEye != null && rightEye != null) {
      final leftEyePoints = leftEye.points.map(transformPoint).toList();
      final rightEyePoints = rightEye.points.map(transformPoint).toList();

      if (leftEyePoints.isNotEmpty && rightEyePoints.isNotEmpty) {
        // Calculate eye centers
        final leftEyeCenter = Offset(
          leftEyePoints.reduce((a, b) => a.dx < b.dx ? a : b).dx +
          (leftEyePoints.reduce((a, b) => a.dx > b.dx ? a : b).dx - 
           leftEyePoints.reduce((a, b) => a.dx < b.dx ? a : b).dx) / 2,
          leftEyePoints.reduce((a, b) => a.dy < b.dy ? a : b).dy +
          (leftEyePoints.reduce((a, b) => a.dy > b.dy ? a : b).dy - 
           leftEyePoints.reduce((a, b) => a.dy < b.dy ? a : b).dy) / 2,
        );

        final rightEyeCenter = Offset(
          rightEyePoints.reduce((a, b) => a.dx < b.dx ? a : b).dx +
          (rightEyePoints.reduce((a, b) => a.dx > b.dx ? a : b).dx - 
           rightEyePoints.reduce((a, b) => a.dx < b.dx ? a : b).dx) / 2,
          rightEyePoints.reduce((a, b) => a.dy < b.dy ? a : b).dy +
          (rightEyePoints.reduce((a, b) => a.dy > b.dy ? a : b).dy - 
           rightEyePoints.reduce((a, b) => a.dy < b.dy ? a : b).dy) / 2,
        );

        // Calculate ear positions relative to eyes (approx 0.45 face width outward)
        final earOffset = faceWidth * 0.45;
        earPositions.add(Offset(leftEyeCenter.dx - earOffset, leftEyeCenter.dy));
        earPositions.add(Offset(rightEyeCenter.dx + earOffset, rightEyeCenter.dy));
      }
    }

    // Draw ear jewelry
    for (final earPos in earPositions) {
      final double width = faceWidth * scale * 0.6;
      final double height = width * (image.height / image.width);

      final Offset anchorPoint = Offset(
        earPos.dx + (asset.offset['x'] ?? 0.0) * faceWidth,
        earPos.dy + (asset.offset['y'] ?? 0.0) * faceHeight,
      );

      final Rect rect = Rect.fromCenter(
        center: anchorPoint,
        width: width,
        height: height,
      );

      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant JewelryPainter oldDelegate) {
    return oldDelegate.selectedJewelryIds != selectedJewelryIds ||
           oldDelegate.faces != faces;
  }
}