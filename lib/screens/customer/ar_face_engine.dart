//lib/customer/ar_face_engine.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

class ArFaceData {
  final Face face;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection lensDirection;

  const ArFaceData({
    required this.face,
    required this.imageSize,
    required this.rotation,
    required this.lensDirection,
  });

  bool get isFrontCamera => lensDirection == CameraLensDirection.front;
}

class ArFaceEngine {
  void Function(ArFaceData?)? onFace;
  void Function(bool)? onCameraReady;
  void Function(String)? onError;

  CameraController? _ctrl;
  FaceDetector? _detector;
  bool _processing = false;
  bool _isInitialized = false;

  Size _imgSize = Size.zero;
  InputImageRotation _rotation = InputImageRotation.rotation90deg;

  CameraController? get controller => _ctrl;
  bool get isInitialized => _isInitialized;

  Future<bool> init({
    bool enableContours = true,
    bool enableLandmarks = true,
    bool enableTracking = true,
  }) async {
    try {
      final permission = await Permission.camera.request();
      if (!permission.isGranted) {
        onError?.call('Camera permission denied');
        return false;
      }

      _detector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: enableContours,
          enableLandmarks: enableLandmarks,
          enableClassification: true,
          enableTracking: enableTracking,
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.15,
        ),
      );

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        onError?.call('No cameras available');
        return false;
      }

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _ctrl = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _ctrl!.initialize();

      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      _isInitialized = true;
      onCameraReady?.call(true);

      await _ctrl!.startImageStream(_onFrame);

      return true;
    } catch (e) {
      onError?.call('Initialization error: $e');
      return false;
    }
  }

  void _onFrame(CameraImage img) async {
    if (_processing || _detector == null) return;
    _processing = true;

    try {
      final inputImg = _buildInputImage(img);
      if (inputImg == null) {
        _processing = false;
        return;
      }

      final faces = await _detector!.processImage(inputImg);

      if (faces.isNotEmpty) {
        onFace?.call(ArFaceData(
          face: faces.first,
          imageSize: _imgSize,
          rotation: _rotation,
          lensDirection: _ctrl?.description.lensDirection ?? CameraLensDirection.front,
        ));
      } else {
        onFace?.call(null);
      }
    } catch (e) {
      onError?.call('Face detection error: $e');
      onFace?.call(null);
    } finally {
      _processing = false;
    }
  }

  InputImage? _buildInputImage(CameraImage img) {
    if (_ctrl?.description == null || img.planes.isEmpty) return null;

    final camera = _ctrl!.description;
    final sensorOrientation = camera.sensorOrientation;
    final deviceOrientation = _getDeviceOrientation(_ctrl!.value.deviceOrientation);

    int rotation;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotation = (sensorOrientation + deviceOrientation) % 360;
    } else {
      rotation = (sensorOrientation - deviceOrientation + 360) % 360;
    }

    final inputRotation = InputImageRotationValue.fromRawValue(rotation) ?? InputImageRotation.rotation90deg;

    final imgW = img.width.toDouble();
    final imgH = img.height.toDouble();

    if (_imgSize.width != imgW || _imgSize.height != imgH || _rotation != inputRotation) {
      _imgSize = Size(imgW, imgH);
      _rotation = inputRotation;
    }

    final buffer = WriteBuffer();
    for (final plane in img.planes) {
      buffer.putUint8List(plane.bytes);
    }
    final bytes = buffer.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(imgW, imgH),
        rotation: inputRotation,
        format: InputImageFormat.nv21,
        bytesPerRow: img.planes.first.bytesPerRow,
      ),
    );
  }

  int _getDeviceOrientation(DeviceOrientation? o) {
    switch (o) {
      case DeviceOrientation.portraitUp:
        return 0;
      case DeviceOrientation.landscapeLeft:
        return 90;
      case DeviceOrientation.portraitDown:
        return 180;
      case DeviceOrientation.landscapeRight:
        return 270;
      default:
        return 0;
    }
  }

  Future<void> stopStream() async {
    try {
      await _ctrl?.stopImageStream();
    } catch (_) {}
  }

  Future<void> startStream() async {
    try {
      if (_isInitialized && _ctrl != null) {
        await _ctrl!.startImageStream(_onFrame);
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _ctrl?.stopImageStream();
      await _ctrl?.dispose();
      await _detector?.close();
      _isInitialized = false;
    } catch (_) {}
  }
}

class ArCoordTransform {
  final Size imageSize;
  final InputImageRotation rotation;
  final bool isFrontCamera;

  const ArCoordTransform({
    required this.imageSize,
    required this.rotation,
    required this.isFrontCamera,
  });

  Offset toCanvas(math.Point<int> mlPoint, Size canvasSize) {
    double x = mlPoint.x.toDouble();
    double y = mlPoint.y.toDouble();

    final iw = imageSize.width;
    final ih = imageSize.height;

    double rotatedX, rotatedY;
    switch (rotation) {
      case InputImageRotation.rotation0deg:
        rotatedX = x;
        rotatedY = y;
      case InputImageRotation.rotation90deg:
        rotatedX = ih - y;
        rotatedY = x;
      case InputImageRotation.rotation180deg:
        rotatedX = iw - x;
        rotatedY = ih - y;
      case InputImageRotation.rotation270deg:
        rotatedX = y;
        rotatedY = iw - x;
    }

    final logicalWidth = (rotation == InputImageRotation.rotation90deg || rotation == InputImageRotation.rotation270deg) ? ih : iw;
    final logicalHeight = (rotation == InputImageRotation.rotation90deg || rotation == InputImageRotation.rotation270deg) ? iw : ih;

    double canvasX = (rotatedX / logicalWidth) * canvasSize.width;
    double canvasY = (rotatedY / logicalHeight) * canvasSize.height;

    if (isFrontCamera) {
      canvasX = canvasSize.width - canvasX;
    }

    return Offset(canvasX, canvasY);
  }

  List<Offset> toCanvasList(List<math.Point<int>> mlPoints, Size canvasSize) {
    return mlPoints.map((p) => toCanvas(p, canvasSize)).toList();
  }

  static Rect boundingBox(List<Offset> points) {
    if (points.isEmpty) return Rect.zero;

    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (final p in points) {
      minX = math.min(minX, p.dx);
      minY = math.min(minY, p.dy);
      maxX = math.max(maxX, p.dx);
      maxY = math.max(maxY, p.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  static Offset centroid(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;
    final sum = points.fold<Offset>(Offset.zero, (a, b) => a + b);
    return sum / points.length.toDouble();
  }
}