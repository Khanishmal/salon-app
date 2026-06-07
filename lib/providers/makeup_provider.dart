// lib/providers/makeup_provider.dart
import 'package:flutter/material.dart';
import '../models/makeup_configuration.dart';

class MakeupProvider with ChangeNotifier {
  final MakeupConfiguration _config = MakeupConfiguration();

  MakeupConfiguration get config => _config;

  // Update specific color selections cleanly
  void updateColors({
    Color? lipstick,
    Color? eyeshadow,
    Color? eyeliner,
    Color? blush,
    Color? foundation,
    Color? contour,
    Color? jewelry, // FIX: Recognized parameter
    Color? mehndi,  // FIX: Recognized parameter
  }) {
    if (lipstick != null) _config.lipstickColor = lipstick;
    if (eyeshadow != null) _config.eyeshadowColor = eyeshadow;
    if (eyeliner != null) _config.eyelinerColor = eyeliner;
    if (blush != null) _config.blushColor = blush;
    if (foundation != null) _config.foundationColor = foundation;
    if (contour != null) _config.contourColor = contour;
    if (jewelry != null) _config.jewelryColor = jewelry;   // FIX: Valid setter
    if (mehndi != null) _config.mehndiColor = mehndi;       // FIX: Valid setter
    notifyListeners();
  }

  // Handle fine-grained layer opacity adjustments
  void updateOpacity(String category, double value) {
    switch (category) {
      case 'Lipstick': _config.lipstickOpacity = value; break;
      case 'Eyeshadow': _config.eyeshadowOpacity = value; break;
      case 'Eyeliner': _config.eyelinerOpacity = value; break;
      case 'Blush': _config.blushOpacity = value; break;
      case 'Foundation': _config.foundationOpacity = value; break;
      case 'Contour': _config.contourOpacity = value; break;
      case 'Jewelry': _config.jewelryOpacity = value; break; // FIX: Valid setter
      case 'Mehndi': _config.mehndiOpacity = value; break;   // FIX: Valid setter
    }
    notifyListeners();
  }

  // Toggle active rendering visibility overlays
  void toggleLayer(String category, bool enabled) {
    switch (category) {
      case 'Lipstick': _config.lipstickEnabled = enabled; break;
      case 'Eyeshadow': _config.eyeshadowEnabled = enabled; break;
      case 'Eyeliner': _config.eyelinerEnabled = enabled; break;
      case 'Blush': _config.blushEnabled = enabled; break;
      case 'Foundation': _config.foundationEnabled = enabled; break;
      case 'Contour': _config.contourEnabled = enabled; break;
      case 'Jewelry': _config.jewelryEnabled = enabled; break;
      case 'Mehndi': _config.mehndiEnabled = enabled; break;
    }
    notifyListeners();
  }

  // Reset matrix back to clear transparent defaults
  void resetConfiguration() {
    _config.lipstickColor = Colors.transparent; _config.lipstickEnabled = false;
    _config.eyeshadowColor = Colors.transparent; _config.eyeshadowEnabled = false;
    _config.eyelinerColor = Colors.transparent; _config.eyelinerEnabled = false;
    _config.blushColor = Colors.transparent; _config.blushEnabled = false;
    _config.foundationColor = Colors.transparent; _config.foundationEnabled = false;
    _config.contourColor = Colors.transparent; _config.contourEnabled = false;
    _config.jewelryColor = Colors.transparent; _config.jewelryEnabled = false;
    _config.mehndiColor = Colors.transparent; _config.mehndiEnabled = false;
    notifyListeners();
  }
}