//lib/providers/makeup_provider.dart
import 'package:flutter/material.dart';
import '../models/makeup_configuration.dart';

class MakeupProvider extends ChangeNotifier {
  // Master application configuration state
  final MakeupConfiguration _config = MakeupConfiguration(
    lipstickColor: const Color(0xFFD91A5B),
    blushColor: const Color(0xFFFFB6C1),
    eyeshadowColor: const Color(0xFF8C0327),
    eyelinerColor: const Color(0xFF000000),
    contourColor: const Color(0xFF5C4033),
    jewelryColor: const Color(0xFFFFD700),
    mehndiColor: const Color(0xFF4A2C00),
  );

  MakeupConfiguration get config => _config;

  // Global modifiers that trigger UI redraw pipelines automatically
  void updateColor(String category, Color color) {
    switch (category) {
      case 'Lipstick': _config.lipstickColor = color; break;
      case 'Blush': _config.blushColor = color; break;
      case 'Eyeshadow': _config.eyeshadowColor = color; break;
      case 'Eyeliner': _config.eyelinerColor = color; break;
      case 'Contour': _config.contourColor = color; break;
      case 'Jewelry': _config.jewelryColor = color; break;
      case 'Mehndi': _config.mehndiColor = color; break;
    }
    notifyListeners();
  }

  void updateOpacity(String category, double opacity) {
    switch (category) {
      case 'Lipstick': _config.lipstickOpacity = opacity; break;
      case 'Blush': _config.blushOpacity = opacity; break;
      case 'Eyeshadow': _config.eyeshadowOpacity = opacity; break;
      case 'Eyeliner': _config.eyelinerOpacity = opacity; break;
      case 'Contour': _config.contourOpacity = opacity; break;
      case 'Jewelry': _config.jewelryOpacity = opacity; break;
      case 'Mehndi': _config.mehndiOpacity = opacity; break;
    }
    notifyListeners();
  }

  // Resets profile selections back to clean defaults
  void clearMakeover() {
    _config.lipstickColor = Colors.transparent;
    _config.blushColor = Colors.transparent;
    _config.eyeshadowColor = Colors.transparent;
    _config.eyelinerColor = Colors.transparent;
    _config.contourColor = Colors.transparent;
    _config.jewelryColor = Colors.transparent;
    _config.mehndiColor = Colors.transparent;
    notifyListeners();
  }
}

