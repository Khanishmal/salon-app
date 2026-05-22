// lib/models/makeup_configuration.dart
import 'package:flutter/material.dart';

class MakeupConfiguration {
  Color lipstickColor;
  double lipstickOpacity; // Range 0.0 to 1.0
  
  Color eyeshadowColor;
  double eyeshadowOpacity;
  
  Color blushColor;
  double blushOpacity;

  MakeupConfiguration({
    this.lipstickColor = Colors.transparent,
    this.lipstickOpacity = 0.5,
    this.eyeshadowColor = Colors.transparent,
    this.eyeshadowOpacity = 0.3,
    this.blushColor = Colors.transparent,
    this.blushOpacity = 0.2,
  });
}