// lib/providers/makeup_provider.dart
import 'package:flutter/material.dart';
import '../models/makeup_configuration.dart';

class MakeupProvider extends ChangeNotifier {
  final MakeupConfiguration _config = MakeupConfiguration();
  bool _isCapturing = false;
  bool _isCompareMode = false;
  
  MakeupConfiguration get config => _config;
  bool get isCapturing => _isCapturing;
  bool get isCompareMode => _isCompareMode;
  
  void setCapturing(bool value) {
    _isCapturing = value;
    notifyListeners();
  }
  
  void toggleCompareMode() {
    _isCompareMode = !_isCompareMode;
    notifyListeners();
  }

  void updateColor(String category, Color color) {
    switch (category) {
      case 'Lipstick': _config.lipstickColor = color; break;
      case 'Foundation': _config.foundationColor = color; break;
      case 'Blush': _config.blushColor = color; break;
      case 'Eyeshadow': _config.eyeshadowColor = color; break;
      case 'Eyeliner': _config.eyelinerColor = color; break;
      case 'Eyebrow': _config.eyebrowColor = color; break;
      case 'Highlighter': _config.highlighterColor = color; break;
      case 'Bronzer': _config.bronzerColor = color; break;
    }
    notifyListeners();
  }

  void updateOpacity(String category, double opacity) {
    switch (category) {
      case 'Lipstick': _config.lipstickOpacity = opacity; break;
      case 'Foundation': _config.foundationOpacity = opacity; break;
      case 'Blush': _config.blushOpacity = opacity; break;
      case 'Eyeshadow': _config.eyeshadowOpacity = opacity; break;
      case 'Eyeliner': _config.eyelinerOpacity = opacity; break;
      case 'Eyebrow': _config.eyebrowOpacity = opacity; break;
      case 'Highlighter': _config.highlighterOpacity = opacity; break;
      case 'Bronzer': _config.bronzerOpacity = opacity; break;
    }
    notifyListeners();
  }
  
  void updateIntensity(double value) {
    _config.intensity = value;
    notifyListeners();
  }

  void clearMakeover() {
    _config.lipstickColor = Colors.transparent;
    _config.foundationColor = Colors.transparent;
    _config.blushColor = Colors.transparent;
    _config.eyeshadowColor = Colors.transparent;
    _config.eyelinerColor = Colors.transparent;
    _config.eyebrowColor = Colors.transparent;
    _config.highlighterColor = Colors.transparent;
    _config.bronzerColor = Colors.transparent;
    notifyListeners();
  }
}