// lib/data/photo_makeup_palettes.dart
import 'package:flutter/material.dart';

class PhotoMakeupShade {
  final String name;
  final Color color;
  final String hexCode;
  
  const PhotoMakeupShade(this.name, this.color, this.hexCode);
}

class PhotoMakeupPalettes {
  static const List<PhotoMakeupShade> lipstickShades = [
    PhotoMakeupShade('Nude', Color(0xFFD4A574), '#D4A574'),
    PhotoMakeupShade('Dusty Rose', Color(0xFFB76E79), '#B76E79'),
    PhotoMakeupShade('Classic Red', Color(0xFFB71C1C), '#B71C1C'),
    PhotoMakeupShade('Deep Wine', Color(0xFF6B041C), '#6B041C'),
    PhotoMakeupShade('Mauve', Color(0xFFAD7A8A), '#AD7A8A'),
    PhotoMakeupShade('Peach', Color(0xFFFF8A80), '#FF8A80'),
    PhotoMakeupShade('Berry', Color(0xFFAD1457), '#AD1457'),
    PhotoMakeupShade('Plum', Color(0xFF4A148C), '#4A148C'),
    PhotoMakeupShade('Coral', Color(0xFFFF6F60), '#FF6F60'),
    PhotoMakeupShade('Ruby', Color(0xFFC62828), '#C62828'),
    PhotoMakeupShade('Rose', Color(0xFFF06292), '#F06292'),
    PhotoMakeupShade('Brown', Color(0xFF8D6E63), '#8D6E63'),
  ];

  static const List<PhotoMakeupShade> foundationShades = [
    PhotoMakeupShade('Porcelain', Color(0xFFF5E6D3), '#F5E6D3'),
    PhotoMakeupShade('Ivory', Color(0xFFE8D5C4), '#E8D5C4'),
    PhotoMakeupShade('Fair', Color(0xFFDEC4B0), '#DEC4B0'),
    PhotoMakeupShade('Natural', Color(0xFFD4B8A0), '#D4B8A0'),
    PhotoMakeupShade('Medium', Color(0xFFC8A88E), '#C8A88E'),
    PhotoMakeupShade('Tan', Color(0xFFBA947C), '#BA947C'),
    PhotoMakeupShade('Deep', Color(0xFFA8846E), '#A8846E'),
    PhotoMakeupShade('Rich', Color(0xFF8B6D58), '#8B6D58'),
    PhotoMakeupShade('Dark', Color(0xFF7A5C4A), '#7A5C4A'),
    PhotoMakeupShade('Ebony', Color(0xFF4A3228), '#4A3228'),
  ];

  static const List<PhotoMakeupShade> blushShades = [
    PhotoMakeupShade('Baby Pink', Color(0xFFFFCDD2), '#FFCDD2'),
    PhotoMakeupShade('Soft Pink', Color(0xFFFFB6C1), '#FFB6C1'),
    PhotoMakeupShade('Warm Coral', Color(0xFFFF8A80), '#FF8A80'),
    PhotoMakeupShade('Peach', Color(0xFFFFAB91), '#FFAB91'),
    PhotoMakeupShade('Rose', Color(0xFFF48FB1), '#F48FB1'),
    PhotoMakeupShade('Berry', Color(0xFFFF80AB), '#FF80AB'),
    PhotoMakeupShade('Terracotta', Color(0xFFFF6F60), '#FF6F60'),
    PhotoMakeupShade('Deep Rose', Color(0xFFE57373), '#E57373'),
  ];

  static const List<PhotoMakeupShade> eyeshadowShades = [
    PhotoMakeupShade('Champagne', Color(0xFFF5E6CA), '#F5E6CA'),
    PhotoMakeupShade('Gold', Color(0xFFFFD700), '#FFD700'),
    PhotoMakeupShade('Copper', Color(0xFFB87333), '#B87333'),
    PhotoMakeupShade('Bronze', Color(0xFFCD7F32), '#CD7F32'),
    PhotoMakeupShade('Matte Brown', Color(0xFF8D6E63), '#8D6E63'),
    PhotoMakeupShade('Espresso', Color(0xFF4E342E), '#4E342E'),
    PhotoMakeupShade('Charcoal', Color(0xFF36454F), '#36454F'),
    PhotoMakeupShade('Shimmer Taupe', Color(0xFFBFA089), '#BFA089'),
    PhotoMakeupShade('Deep Purple', Color(0xFF4A148C), '#4A148C'),
    PhotoMakeupShade('Navy', Color(0xFF1A237E), '#1A237E'),
    PhotoMakeupShade('Emerald', Color(0xFF004D40), '#004D40'),
    PhotoMakeupShade('Rose Gold', Color(0xFFF06292), '#F06292'),
  ];

  static const List<PhotoMakeupShade> eyelinerShades = [
    PhotoMakeupShade('Pitch Black', Color(0xFF000000), '#000000'),
    PhotoMakeupShade('Deep Brown', Color(0xFF3E2723), '#3E2723'),
    PhotoMakeupShade('Navy', Color(0xFF0D47A1), '#0D47A1'),
    PhotoMakeupShade('Emerald', Color(0xFF00695C), '#00695C'),
    PhotoMakeupShade('Plum', Color(0xFF6A1B9A), '#6A1B9A'),
    PhotoMakeupShade('Bronze', Color(0xFF8D6E63), '#8D6E63'),
    PhotoMakeupShade('Charcoal', Color(0xFF37474F), '#37474F'),
    PhotoMakeupShade('Royal Blue', Color(0xFF1565C0), '#1565C0'),
  ];

  static const List<PhotoMakeupShade> eyebrowShades = [
    PhotoMakeupShade('Blonde', Color(0xFFBCAAA4), '#BCAAA4'),
    PhotoMakeupShade('Soft Brown', Color(0xFF8D6E63), '#8D6E63'),
    PhotoMakeupShade('Medium Brown', Color(0xFF6D4C41), '#6D4C41'),
    PhotoMakeupShade('Dark Brown', Color(0xFF4E342E), '#4E342E'),
    PhotoMakeupShade('Auburn', Color(0xFF5D4037), '#5D4037'),
    PhotoMakeupShade('Ash Grey', Color(0xFF757575), '#757575'),
    PhotoMakeupShade('Black', Color(0xFF1A1A1A), '#1A1A1A'),
    PhotoMakeupShade('Taupe', Color(0xFFA1887F), '#A1887F'),
  ];

  static const Map<String, List<PhotoMakeupShade>> allPalettes = {
    'Lipstick': lipstickShades,
    'Foundation': foundationShades,
    'Blush': blushShades,
    'Eyeshadow': eyeshadowShades,
    'Eyeliner': eyelinerShades,
    'Eyebrow': eyebrowShades,
  };

  static const Map<String, String> categoryIcons = {
    'Lipstick': '💄',
    'Foundation': '🎨',
    'Blush': '🌸',
    'Eyeshadow': '🎭',
    'Eyeliner': '✒️',
    'Eyebrow': '👀',
  };

  static const Map<String, String> categoryLabels = {
    'Lipstick': 'Lipstick',
    'Foundation': 'Foundation',
    'Blush': 'Blush',
    'Eyeshadow': 'Eyeshadow',
    'Eyeliner': 'Eyeliner',
    'Eyebrow': 'Eyebrows',
  };
}