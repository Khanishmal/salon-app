// lib/models/makeup_configuration.dart
import 'package:flutter/material.dart';

class MakeupConfiguration {
  Color lipstickColor;
  double lipstickOpacity;
  bool lipstickEnabled;
  
  Color eyeshadowColor;
  double eyeshadowOpacity;
  bool eyeshadowEnabled;
  
  Color eyelinerColor;
  double eyelinerOpacity;
  bool eyelinerEnabled;
  
  Color blushColor;
  double blushOpacity;
  bool blushEnabled;
  
  Color contourColor;
  double contourOpacity;
  bool contourEnabled;
  
  Color foundationColor;
  double foundationOpacity;
  bool foundationEnabled;
  
  Color jewelryColor;
  double jewelryOpacity;
  bool jewelryEnabled;
  
  Color mehndiColor;
  double mehndiOpacity;
  bool mehndiEnabled;

  MakeupConfiguration({
    this.lipstickColor = Colors.transparent,
    this.lipstickOpacity = 0.5,
    this.lipstickEnabled = true,
    this.eyeshadowColor = Colors.transparent,
    this.eyeshadowOpacity = 0.4,
    this.eyeshadowEnabled = false,
    this.eyelinerColor = Colors.transparent,
    this.eyelinerOpacity = 0.8,
    this.eyelinerEnabled = false,
    this.blushColor = Colors.transparent,
    this.blushOpacity = 0.3,
    this.blushEnabled = true,
    this.contourColor = Colors.transparent,
    this.contourOpacity = 0.2,
    this.contourEnabled = false,
    this.foundationColor = Colors.transparent,
    this.foundationOpacity = 0.3,
    this.foundationEnabled = false,
    this.jewelryColor = Colors.transparent,
    this.jewelryOpacity = 1.0,
    this.jewelryEnabled = false,
    this.mehndiColor = Colors.transparent,
    this.mehndiOpacity = 0.8,
    this.mehndiEnabled = false,
  });
}