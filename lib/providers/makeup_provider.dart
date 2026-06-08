import 'package:flutter/material.dart';
import '../models/makeup_configuration.dart';

class MakeupProvider extends ChangeNotifier {
  final MakeupConfiguration _configuration = MakeupConfiguration();

  MakeupConfiguration get configuration => _configuration;

  // Color Updaters
  void updateContourColor(Color color) {
    _configuration.contourColor = color;
    notifyListeners();
  }

  void updateJewelryColor(Color color) {
    _configuration.jewelryColor = color;
    notifyListeners();
  }

  void updateMehndiColor(Color color) {
    _configuration.mehndiColor = color;
    notifyListeners();
  }

  // Opacity Updaters
  void updateOpacity(String feature, double opacity) {
    switch (feature) {
      case 'lipstick':
        _configuration.lipstickOpacity = opacity;
        break;
      case 'eyeshadow':
        _configuration.eyeshadowOpacity = opacity;
        break;
      case 'eyeliner':
        _configuration.eyelinerOpacity = opacity;
        break;
      case 'blush':
        _configuration.blushOpacity = opacity;
        break;
      case 'foundation':
        _configuration.foundationOpacity = opacity;
        break;
      case 'contour':
        _configuration.contourOpacity = opacity;
        break;
      case 'jewelry':
        _configuration.jewelryOpacity = opacity;
        break;
      case 'mehndi':
        _configuration.mehndiOpacity = opacity;
        break;
    }
    notifyListeners();
  }

  // Toggle Feature States
  void toggleFeature(String feature, bool enabled) {
    switch (feature) {
      case 'lipstick':
        _configuration.lipstickEnabled = enabled;
        break;
      case 'eyeshadow':
        _configuration.eyeshadowEnabled = enabled;
        break;
      case 'eyeliner':
        _configuration.eyelinerEnabled = enabled;
        break;
      case 'blush':
        _configuration.blushEnabled = enabled;
        break;
      case 'foundation':
        _configuration.foundationEnabled = enabled;
        break;
      case 'contour':
        _configuration.contourEnabled = enabled;
        break;
      case 'jewelry':
        _configuration.jewelryEnabled = enabled;
        break;
      case 'mehndi':
        _configuration.mehndiEnabled = enabled;
        break;
    }
    notifyListeners();
  }

  // Reset Methods
  void resetConfiguration() {
    _configuration.lipstickEnabled = false;
    _configuration.eyeshadowEnabled = false;
    _configuration.eyelinerEnabled = false;
    _configuration.blushEnabled = false;
    _configuration.foundationEnabled = false;
    _configuration.contourEnabled = false;
    _configuration.jewelryEnabled = false;
    _configuration.mehndiEnabled = false;
    notifyListeners();
  }
}