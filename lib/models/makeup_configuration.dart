import 'package:flutter/material.dart';

class MakeupConfiguration {
  // Existing Colors
  Color lipstickColor;
  Color eyeshadowColor;
  Color eyelinerColor;
  Color blushColor;
  Color foundationColor;
  Color contourColor;
  Color jewelryColor;
  Color mehndiColor;

  // Existing Opacities
  double lipstickOpacity;
  double eyeshadowOpacity;
  double eyelinerOpacity;
  double blushOpacity;
  double foundationOpacity;
  double contourOpacity;
  double jewelryOpacity;
  double mehndiOpacity;

  // Existing Toggles
  bool lipstickEnabled;
  bool eyeshadowEnabled;
  bool eyelinerEnabled;
  bool blushEnabled;
  bool foundationEnabled;
  bool contourEnabled;
  bool jewelryEnabled;
  bool mehndiEnabled;

  // NEW: Virtual Jewelry Asset Paths
  String? selectedTikkaAsset;
  String? selectedNoseRingAsset;
  String? selectedNecklaceAsset;

  MakeupConfiguration({
    this.lipstickColor = Colors.red,
    this.eyeshadowColor = Colors.purple,
    this.eyelinerColor = Colors.black,
    this.blushColor = Colors.pink,
    this.foundationColor = const Color(0xFFF1C27D),
    this.contourColor = const Color(0xFF8D5524),
    this.jewelryColor = Colors.amber,
    this.mehndiColor = const Color(0xFF4A2E1B),
    this.lipstickOpacity = 0.5,
    this.eyeshadowOpacity = 0.3,
    this.eyelinerOpacity = 0.8,
    this.blushOpacity = 0.2,
    this.foundationOpacity = 0.4,
    this.contourOpacity = 0.3,
    this.jewelryOpacity = 1.0,
    this.mehndiOpacity = 0.5,
    this.lipstickEnabled = false,
    this.eyeshadowEnabled = false,
    this.eyelinerEnabled = false,
    this.blushEnabled = false,
    this.foundationEnabled = false,
    this.contourEnabled = false,
    this.jewelryEnabled = false,
    this.mehndiEnabled = false,
    // Initialize jewelry assets as unselected/null
    this.selectedTikkaAsset,
    this.selectedNoseRingAsset,
    this.selectedNecklaceAsset,
  });

  // Optional: Clean deep copy method for State management updates
  MakeupConfiguration copyWith({
    Color? lipstickColor,
    Color? eyeshadowColor,
    Color? eyelinerColor,
    Color? blushColor,
    Color? foundationColor,
    Color? contourColor,
    Color? jewelryColor,
    Color? mehndiColor,
    double? lipstickOpacity,
    double? eyeshadowOpacity,
    double? eyelinerOpacity,
    double? blushOpacity,
    double? foundationOpacity,
    double? contourOpacity,
    double? jewelryOpacity,
    double? mehndiOpacity,
    bool? lipstickEnabled,
    bool? eyeshadowEnabled,
    bool? eyelinerEnabled,
    bool? blushEnabled,
    bool? foundationEnabled,
    bool? contourEnabled,
    bool? jewelryEnabled,
    bool? mehndiEnabled,
    String? selectedTikkaAsset,
    String? selectedNoseRingAsset,
    String? selectedNecklaceAsset,
  }) {
    return MakeupConfiguration(
      lipstickColor: lipstickColor ?? this.lipstickColor,
      eyeshadowColor: eyeshadowColor ?? this.eyeshadowColor,
      eyelinerColor: eyelinerColor ?? this.eyelinerColor,
      blushColor: blushColor ?? this.blushColor,
      foundationColor: foundationColor ?? this.foundationColor,
      contourColor: contourColor ?? this.contourColor,
      jewelryColor: jewelryColor ?? this.jewelryColor,
      mehndiColor: mehndiColor ?? this.mehndiColor,
      lipstickOpacity: lipstickOpacity ?? this.lipstickOpacity,
      eyeshadowOpacity: eyeshadowOpacity ?? this.eyeshadowOpacity,
      eyelinerOpacity: eyelinerOpacity ?? this.eyelinerOpacity,
      blushOpacity: blushOpacity ?? this.blushOpacity,
      foundationOpacity: foundationOpacity ?? this.foundationOpacity,
      contourOpacity: contourOpacity ?? this.contourOpacity,
      jewelryOpacity: jewelryOpacity ?? this.jewelryOpacity,
      mehndiOpacity: mehndiOpacity ?? this.mehndiOpacity,
      lipstickEnabled: lipstickEnabled ?? this.lipstickEnabled,
      eyeshadowEnabled: eyeshadowEnabled ?? this.eyeshadowEnabled,
      eyelinerEnabled: eyelinerEnabled ?? this.eyelinerEnabled,
      blushEnabled: blushEnabled ?? this.blushEnabled,
      foundationEnabled: foundationEnabled ?? this.foundationEnabled,
      contourEnabled: contourEnabled ?? this.contourEnabled,
      jewelryEnabled: jewelryEnabled ?? this.jewelryEnabled,
      mehndiEnabled: mehndiEnabled ?? this.mehndiEnabled,
      selectedTikkaAsset: selectedTikkaAsset ?? this.selectedTikkaAsset,
      selectedNoseRingAsset: selectedNoseRingAsset ?? this.selectedNoseRingAsset,
      selectedNecklaceAsset: selectedNecklaceAsset ?? this.selectedNecklaceAsset,
    );
  }
}