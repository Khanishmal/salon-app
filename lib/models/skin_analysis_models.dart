// lib/models/skin_analysis_models.dart
import 'package:flutter/material.dart';

class SkinAnalysisResult {
  final String skinTone;
  final String skinType;
  final int confidence;
  final int ageEstimate;
  final SkinRecommendations recommendations;
  final List<String> concerns;
  final int glowScore;
  final SkinHealth health;
  final List<String> bestLooks;
  final String celebrityMatch;
  final String analysisDate;
  final String photoSource;

  SkinAnalysisResult({
    required this.skinTone,
    required this.skinType,
    required this.confidence,
    required this.ageEstimate,
    required this.recommendations,
    required this.concerns,
    required this.glowScore,
    required this.health,
    required this.bestLooks,
    required this.celebrityMatch,
    required this.analysisDate,
    required this.photoSource,
  });

  factory SkinAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SkinAnalysisResult(
      skinTone: json['skinTone'] ?? 'Warm Olive',
      skinType: json['skinType'] ?? 'Combination',
      confidence: json['confidence'] is int ? json['confidence'] : 85,
      ageEstimate: json['ageEstimate'] ?? 25,
      recommendations: SkinRecommendations.fromJson(json['recommendations'] ?? {}),
      concerns: List<String>.from(json['concerns'] ?? []),
      glowScore: json['glowScore'] is int ? json['glowScore'] : 7,
      health: SkinHealth.fromJson(json['skinHealth'] ?? {}),
      bestLooks: List<String>.from(json['bestLooks'] ?? []),
      celebrityMatch: json['celebrityMatch'] ?? 'N/A',
      analysisDate: json['analysisDate'] ?? DateTime.now().toIso8601String(),
      photoSource: json['photoSource'] ?? 'Photo',
    );
  }

  Map<String, dynamic> toJson() => {
    'skinTone': skinTone,
    'skinType': skinType,
    'confidence': confidence,
    'ageEstimate': ageEstimate,
    'recommendations': recommendations.toJson(),
    'concerns': concerns,
    'glowScore': glowScore,
    'skinHealth': health.toJson(),
    'bestLooks': bestLooks,
    'celebrityMatch': celebrityMatch,
    'analysisDate': analysisDate,
    'photoSource': photoSource,
  };
}

class SkinRecommendations {
  final List<String> lipstick;
  final String blush;
  final String eyeshadow;
  final String foundation;
  final List<String> skincare;
  final String hairStyle;

  SkinRecommendations({
    required this.lipstick,
    required this.blush,
    required this.eyeshadow,
    required this.foundation,
    required this.skincare,
    required this.hairStyle,
  });

  factory SkinRecommendations.fromJson(Map<String, dynamic> json) {
    return SkinRecommendations(
      lipstick: List<String>.from(json['lipstick'] ?? ['Ruby Red', 'Coral Pink']),
      blush: json['blush'] ?? 'Peach',
      eyeshadow: json['eyeshadow'] ?? 'Gold & Bronze',
      foundation: json['foundation'] ?? 'Medium with yellow undertones',
      skincare: List<String>.from(json['skincare'] ?? ['Vitamin C Serum', 'Sunscreen']),
      hairStyle: json['hairStyle'] ?? 'Soft waves',
    );
  }

  Map<String, dynamic> toJson() => {
    'lipstick': lipstick,
    'blush': blush,
    'eyeshadow': eyeshadow,
    'foundation': foundation,
    'skincare': skincare,
    'hairStyle': hairStyle,
  };
}

class SkinHealth {
  final int hydration;
  final int elasticity;
  final int evenness;

  SkinHealth({
    required this.hydration,
    required this.elasticity,
    required this.evenness,
  });

  factory SkinHealth.fromJson(Map<String, dynamic> json) {
    return SkinHealth(
      hydration: json['hydration'] is int ? json['hydration'] : 70,
      elasticity: json['elasticity'] is int ? json['elasticity'] : 70,
      evenness: json['evenness'] is int ? json['evenness'] : 70,
    );
  }

  Map<String, dynamic> toJson() => {
    'hydration': hydration,
    'elasticity': elasticity,
    'evenness': evenness,
  };
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}