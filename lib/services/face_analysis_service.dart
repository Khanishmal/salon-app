// lib/services/face_analysis_service.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceMetrics {
  final String faceShape;
  final String skinTone;
  final String eyeShape;
  final String lipShape;
  final double symmetryScore;
  final Map<String, double> featureDistances;

  FaceMetrics({
    required this.faceShape,
    required this.skinTone,
    required this.eyeShape,
    required this.lipShape,
    required this.symmetryScore,
    required this.featureDistances,
  });
}

class FaceAnalysisService {
  // ===========================================================================
  // ANALYZE FACE METRICS FROM ML KIT DATA
  // ===========================================================================

  static FaceMetrics analyzeFace(Face face) {
    final landmarks = face.landmarks;
    final contours = face.contours;
    
    // Extract key points using correct ML Kit enum names
    final leftEye = landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = landmarks[FaceLandmarkType.rightEye]?.position;
    final noseBase = landmarks[FaceLandmarkType.noseBase]?.position;
    
    // Calculate face shape from contours
    final faceContour = contours[FaceContourType.face];
    final faceShape = _determineFaceShape(faceContour);
    
    // Determine skin tone (simplified from face features)
    final skinTone = _determineSkinTone(face);
    
    // Determine eye shape
    final eyeShape = _determineEyeShape(leftEye, rightEye);
    
    // Determine lip shape using mouth contours
    final lipShape = _determineLipShape(face);
    
    // Calculate symmetry
    final symmetryScore = _calculateSymmetry(face);
    
    // Calculate feature distances
    final featureDistances = _calculateFeatureDistances(face);
    
    return FaceMetrics(
      faceShape: faceShape,
      skinTone: skinTone,
      eyeShape: eyeShape,
      lipShape: lipShape,
      symmetryScore: symmetryScore,
      featureDistances: featureDistances,
    );
  }

  static String _determineFaceShape(FaceContour? faceContour) {
    if (faceContour == null || faceContour.points.length < 10) return 'Oval';
    
    final points = faceContour.points;
    final minX = points.map((p) => p.x).reduce((a, b) => a < b ? a : b);
    final maxX = points.map((p) => p.x).reduce((a, b) => a > b ? a : b);
    final minY = points.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    
    final width = (maxX - minX).toDouble();
    final height = (maxY - minY).toDouble();
    
    final ratio = width / height;
    
    if (ratio < 0.65) return 'Oval';
    if (ratio < 0.75) return 'Round';
    if (ratio < 0.85) return 'Heart';
    return 'Square';
  }

  static String _determineSkinTone(Face face) {
    // Using yaw angle as proxy for skin tone analysis
    final yaw = face.headEulerAngleY ?? 0.0;
    
    if (yaw.abs() > 20) return 'Medium';
    if (yaw > 10) return 'Warm';
    if (yaw < -10) return 'Cool';
    return 'Neutral';
  }

  static String _determineEyeShape(Point<int>? leftEye, Point<int>? rightEye) {
    if (leftEye == null || rightEye == null) return 'Almond';
    
    final distance = (rightEye.x - leftEye.x).abs().toDouble();
    if (distance < 50) return 'Round';
    if (distance < 80) return 'Almond';
    return 'Hooded';
  }

  static String _determineLipShape(Face face) {
    // Use mouth contours
    final upperLip = face.contours[FaceContourType.upperLipTop];
    final lowerLip = face.contours[FaceContourType.lowerLipBottom];
    
    if (upperLip == null || lowerLip == null) return 'Medium';
    
    final upperPoints = upperLip.points;
    final lowerPoints = lowerLip.points;
    
    // Calculate lip width
    final minX = upperPoints.map((p) => p.x).reduce((a, b) => a < b ? a : b);
    final maxX = upperPoints.map((p) => p.x).reduce((a, b) => a > b ? a : b);
    final width = (maxX - minX).abs().toDouble();
    
    // Calculate lip height
    final minY = upperPoints.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final maxY = lowerPoints.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    final height = (maxY - minY).abs().toDouble();
    
    if (width < 40) return 'Thin';
    if (width < 60 && height < 30) return 'Medium';
    if (width >= 60 || height >= 30) return 'Full';
    return 'Medium';
  }

  static double _calculateSymmetry(Face face) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    
    if (leftEye == null || rightEye == null) return 0.8;
    
    final yDiff = (leftEye.y - rightEye.y).abs();
    final maxDiff = 20.0;
    
    return 1.0 - (yDiff / maxDiff).clamp(0.0, 1.0);
  }

  static Map<String, double> _calculateFeatureDistances(Face face) {
    final landmarks = face.landmarks;
    final Map<String, double> distances = {};
    
    // Eye distance
    if (landmarks[FaceLandmarkType.leftEye] != null && 
        landmarks[FaceLandmarkType.rightEye] != null) {
      final left = landmarks[FaceLandmarkType.leftEye]!.position;
      final right = landmarks[FaceLandmarkType.rightEye]!.position;
      distances['eyeDistance'] = (right.x - left.x).abs().toDouble();
    }
    
    // Nose width
    if (landmarks[FaceLandmarkType.noseBase] != null) {
      final nose = landmarks[FaceLandmarkType.noseBase]!.position;
      distances['noseWidth'] = nose.x.toDouble();
    }
    
    // Lip width using contours
    final upperLip = face.contours[FaceContourType.upperLipTop];
    if (upperLip != null && upperLip.points.isNotEmpty) {
      final points = upperLip.points;
      final minX = points.map((p) => p.x).reduce((a, b) => a < b ? a : b);
      final maxX = points.map((p) => p.x).reduce((a, b) => a > b ? a : b);
      distances['lipWidth'] = (maxX - minX).abs().toDouble();
    }
    
    return distances;
  }
}