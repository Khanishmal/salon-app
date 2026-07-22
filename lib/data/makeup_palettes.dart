// lib/data/makeup_palettes.dart
import 'package:flutter/material.dart';

class MakeupPalettes {
  static const Map<String, List<MakeupShade>> colorPalettes = {
    // 💄 Lipstick - 12 Professional Shades
    'Lipstick': [
      MakeupShade('Nude', Color(0xFFD4A574)),
      MakeupShade('Dusty Rose', Color(0xFFB76E79)),
      MakeupShade('Classic Red', Color(0xFFB71C1C)),
      MakeupShade('Deep Wine', Color(0xFF6B041C)),
      MakeupShade('Mauve', Color(0xFFAD7A8A)),
      MakeupShade('Peach', Color(0xFFFF8A80)),
      MakeupShade('Berry', Color(0xFFAD1457)),
      MakeupShade('Plum', Color(0xFF4A148C)),
      MakeupShade('Coral', Color(0xFFFF6F60)),
      MakeupShade('Ruby', Color(0xFFC62828)),
      MakeupShade('Rose', Color(0xFFF06292)),
      MakeupShade('Brown', Color(0xFF8D6E63)),
    ],
    
    // 🎨 Foundation - 12 Skin Tones
    'Foundation': [
      MakeupShade('Porcelain', Color(0xFFF5E6D3)),
      MakeupShade('Ivory', Color(0xFFE8D5C4)),
      MakeupShade('Fair', Color(0xFFDEC4B0)),
      MakeupShade('Natural', Color(0xFFD4B8A0)),
      MakeupShade('Medium', Color(0xFFC8A88E)),
      MakeupShade('Tan', Color(0xFFBA947C)),
      MakeupShade('Deep', Color(0xFFA8846E)),
      MakeupShade('Rich', Color(0xFF8B6D58)),
      MakeupShade('Dark', Color(0xFF7A5C4A)),
      MakeupShade('Deep Dark', Color(0xFF6A4C3C)),
      MakeupShade('Ebony', Color(0xFF5A3E30)),
      MakeupShade('Rich Ebony', Color(0xFF4A3228)),
    ],
    
    // 🌸 Blush - 12 Soft Shades
    'Blush': [
      MakeupShade('Baby Pink', Color(0xFFFFCDD2)),
      MakeupShade('Soft Pink', Color(0xFFFFB6C1)),
      MakeupShade('Warm Coral', Color(0xFFFF8A80)),
      MakeupShade('Peach', Color(0xFFFFAB91)),
      MakeupShade('Rose', Color(0xFFF48FB1)),
      MakeupShade('Berry', Color(0xFFFF80AB)),
      MakeupShade('Terracotta', Color(0xFFFF6F60)),
      MakeupShade('Deep Rose', Color(0xFFE57373)),
      MakeupShade('Ballet Pink', Color(0xFFF8BBD0)),
      MakeupShade('Mauve', Color(0xFFEF9A9A)),
      MakeupShade('Bronze', Color(0xFFFF9E80)),
      MakeupShade('Dusty Rose', Color(0xFFE8A0A0)),
    ],
    
    // 🎭 Eyeshadow - 16 Professional Shades
    'Eyeshadow': [
      MakeupShade('Champagne', Color(0xFFF5E6CA)),
      MakeupShade('Gold', Color(0xFFFFD700)),
      MakeupShade('Copper', Color(0xFFB87333)),
      MakeupShade('Bronze', Color(0xFFCD7F32)),
      MakeupShade('Matte Brown', Color(0xFF8D6E63)),
      MakeupShade('Espresso', Color(0xFF4E342E)),
      MakeupShade('Charcoal', Color(0xFF36454F)),
      MakeupShade('Shimmer Taupe', Color(0xFFBFA089)),
      MakeupShade('Amber', Color(0xFFFFBF00)),
      MakeupShade('Deep Purple', Color(0xFF4A148C)),
      MakeupShade('Navy', Color(0xFF1A237E)),
      MakeupShade('Emerald', Color(0xFF004D40)),
      MakeupShade('Rose Gold', Color(0xFFF06292)),
      MakeupShade('Lavender', Color(0xFFCE93D8)),
      MakeupShade('Teal', Color(0xFF00897B)),
      MakeupShade('Mocha', Color(0xFF5D4037)),
    ],
    
    // ✒️ Eyeliner - 12 Professional Shades
    'Eyeliner': [
      MakeupShade('Pitch Black', Color(0xFF000000)),
      MakeupShade('Deep Brown', Color(0xFF3E2723)),
      MakeupShade('Navy', Color(0xFF0D47A1)),
      MakeupShade('Emerald', Color(0xFF00695C)),
      MakeupShade('Plum', Color(0xFF6A1B9A)),
      MakeupShade('Bronze', Color(0xFF8D6E63)),
      MakeupShade('Slate', Color(0xFF607D8B)),
      MakeupShade('Charcoal', Color(0xFF37474F)),
      MakeupShade('Royal Blue', Color(0xFF1565C0)),
      MakeupShade('Amber', Color(0xFFFF6F00)),
      MakeupShade('Forest Green', Color(0xFF2E7D32)),
      MakeupShade('Grey', Color(0xFF757575)),
    ],
    
    // 👀 Eyebrows - 10 Natural Shades
    'Eyebrow': [
      MakeupShade('Blonde', Color(0xFFBCAAA4)),
      MakeupShade('Soft Brown', Color(0xFF8D6E63)),
      MakeupShade('Medium Brown', Color(0xFF6D4C41)),
      MakeupShade('Dark Brown', Color(0xFF4E342E)),
      MakeupShade('Auburn', Color(0xFF5D4037)),
      MakeupShade('Ash Grey', Color(0xFF757575)),
      MakeupShade('Charcoal', Color(0xFF2C2C2C)),
      MakeupShade('Black', Color(0xFF1A1A1A)),
      MakeupShade('Taupe', Color(0xFFA1887F)),
      MakeupShade('Warm Brown', Color(0xFF795548)),
    ],
    
    // ✨ Highlighter - 12 Glow Shades
    'Highlighter': [
      MakeupShade('Pearlescent', Color(0xFFFFF9C4)),
      MakeupShade('Champagne', Color(0xFFFFE082)),
      MakeupShade('Gold', Color(0xFFFFD54F)),
      MakeupShade('Rose Gold', Color(0xFFF48FB1)),
      MakeupShade('Bronze', Color(0xFFFFAB91)),
      MakeupShade('Silver', Color(0xFFE1E1E1)),
      MakeupShade('Icy White', Color(0xFFFFFFFF)),
      MakeupShade('Soft Pink', Color(0xFFF8BBD0)),
      MakeupShade('Lavender', Color(0xFFE1BEE7)),
      MakeupShade('Mint', Color(0xFF80CBC4)),
      MakeupShade('Peach', Color(0xFFFFCDD2)),
      MakeupShade('Opal', Color(0xFFB39DDB)),
    ],
    
    // 🌟 Bronzer - 12 Warm Shades
    'Bronzer': [
      MakeupShade('Light Tan', Color(0xFFD7A86E)),
      MakeupShade('Warm Gold', Color(0xFFC8965A)),
      MakeupShade('Soft Brown', Color(0xFFB8844A)),
      MakeupShade('Medium Bronze', Color(0xFFA8723A)),
      MakeupShade('Deep Tan', Color(0xFF98602A)),
      MakeupShade('Rich Copper', Color(0xFF884E1A)),
      MakeupShade('Warm Cocoa', Color(0xFF78420A)),
      MakeupShade('Deep Coffee', Color(0xFF683600)),
      MakeupShade('Golden Bronze', Color(0xFFD4A050)),
      MakeupShade('Sun Kissed', Color(0xFFC08840)),
      MakeupShade('Sunkissed Bronze', Color(0xFFB07830)),
      MakeupShade('Deep Bronze', Color(0xFFA06820)),
    ],
  };
  
  static const Map<String, String> categoryIcons = {
    'Lipstick': '💄',
    'Foundation': '🎨',
    'Blush': '🌸',
    'Eyeshadow': '🎭',
    'Eyeliner': '✒️',
    'Eyebrow': '👀',
    'Highlighter': '✨',
    'Bronzer': '🌟',
  };
  
  static const Map<String, String> categoryLabels = {
    'Lipstick': 'Lipstick',
    'Foundation': 'Foundation',
    'Blush': 'Blush',
    'Eyeshadow': 'Eyeshadow',
    'Eyeliner': 'Eyeliner',
    'Eyebrow': 'Eyebrows',
    'Highlighter': 'Highlighter',
    'Bronzer': 'Bronzer',
  };
  
  static const Map<String, String> categoryImagePaths = {
    'Lipstick': 'assets/makeup_icons/lipstick.png',
    'Foundation': 'assets/makeup_icons/foundation.png',
    'Blush': 'assets/makeup_icons/blush.png',
    'Eyeshadow': 'assets/makeup_icons/eyeshadow.png',
    'Eyeliner': 'assets/makeup_icons/eyeliner.png',
    'Eyebrow': 'assets/makeup_icons/eyebrow.png',
    'Highlighter': 'assets/makeup_icons/highlighter.png',
    'Bronzer': 'assets/makeup_icons/bronzer.png',
  };
}

class MakeupShade {
  final String name;
  final Color color;
  
  const MakeupShade(this.name, this.color);
}