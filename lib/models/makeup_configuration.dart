// lib/models/makeup_configuration.dart
import 'package:flutter/material.dart';

class MakeupConfiguration {
  // Lipstick
  Color lipstickColor;
  double lipstickOpacity;
  
  // Foundation
  Color foundationColor;
  double foundationOpacity;
  
  // Blush
  Color blushColor;
  double blushOpacity;
  
  // Eyeshadow
  Color eyeshadowColor;
  double eyeshadowOpacity;
  
  // Eyeliner
  Color eyelinerColor;
  double eyelinerOpacity;
  
  // Eyebrows
  Color eyebrowColor;
  double eyebrowOpacity;
  
  // Highlighter
  Color highlighterColor;
  double highlighterOpacity;
  
  // Bronzer
  Color bronzerColor;
  double bronzerOpacity;
  
  // Intensity multipliers
  double intensity;

  MakeupConfiguration({
    this.lipstickColor = Colors.transparent,
    this.lipstickOpacity = 0.8,
    this.foundationColor = Colors.transparent,
    this.foundationOpacity = 0.35,
    this.blushColor = Colors.transparent,
    this.blushOpacity = 0.3,
    this.eyeshadowColor = Colors.transparent,
    this.eyeshadowOpacity = 0.5,
    this.eyelinerColor = Colors.transparent,
    this.eyelinerOpacity = 0.9,
    this.eyebrowColor = Colors.transparent,
    this.eyebrowOpacity = 0.5,
    this.highlighterColor = Colors.transparent,
    this.highlighterOpacity = 0.4,
    this.bronzerColor = Colors.transparent,
    this.bronzerOpacity = 0.3,
    this.intensity = 0.5,
  });

  Map<String, dynamic> toJson() {
    return {
      'lipstick': lipstickColor.value,
      'lipstickOpacity': lipstickOpacity,
      'foundation': foundationColor.value,
      'foundationOpacity': foundationOpacity,
      'blush': blushColor.value,
      'blushOpacity': blushOpacity,
      'eyeshadow': eyeshadowColor.value,
      'eyeshadowOpacity': eyeshadowOpacity,
      'eyeliner': eyelinerColor.value,
      'eyelinerOpacity': eyelinerOpacity,
      'eyebrow': eyebrowColor.value,
      'eyebrowOpacity': eyebrowOpacity,
      'highlighter': highlighterColor.value,
      'highlighterOpacity': highlighterOpacity,
      'bronzer': bronzerColor.value,
      'bronzerOpacity': bronzerOpacity,
      'intensity': intensity,
    };
  }
}