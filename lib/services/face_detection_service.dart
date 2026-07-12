// lib/services/face_detection_service.dart
import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  late FaceDetector _faceDetector;

  FaceDetectionService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        enableClassification: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.15,
      ),
    );
  }

  /// Detect if a face exists in the image using file path
  Future<bool> hasFace(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);
      return faces.isNotEmpty;
    } catch (e) {
      print('Face detection error: $e');
      return false;
    }
  }

  /// Detect face count and return details
  Future<FaceDetectionResult> detectFaceDetails(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);
      
      return FaceDetectionResult(
        hasFace: faces.isNotEmpty,
        faceCount: faces.length,
        faces: faces,
      );
    } catch (e) {
      print('Face detection error: $e');
      return FaceDetectionResult(hasFace: false, faceCount: 0, faces: []);
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}

class FaceDetectionResult {
  final bool hasFace;
  final int faceCount;
  final List<Face> faces;

  FaceDetectionResult({
    required this.hasFace,
    required this.faceCount,
    required this.faces,
  });
}