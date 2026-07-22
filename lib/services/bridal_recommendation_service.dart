// lib/services/bridal_recommendation_service.dart
import 'package:flutter/material.dart';
import 'face_analysis_service.dart';

class BridalLook {
  final String id;
  final String name;
  final String category;
  final String description;
  final Map<String, dynamic> makeupParams;
  final List<String> jewelryItems;
  final String icon;
  final Color color;
  final List<String> tags;

  BridalLook({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.makeupParams,
    required this.jewelryItems,
    required this.icon,
    required this.color,
    required this.tags,
  });
}

class BridalRecommendationService {
  // ===========================================================================
  // BRIDAL LOOKS LIBRARY - Expert Curated
  // ===========================================================================

  static final List<BridalLook> _bridalLooks = [
    BridalLook(
      id: 'classic_red',
      name: 'Classic Red Bridal',
      category: 'Traditional',
      description: 'Timeless red bridal look with gold jewelry',
      makeupParams: {
        'lipColor': '#D91A5B',
        'lipFinish': 'matte',
        'blushColor': '#FF6B81',
        'eyeshadowColor': '#4A0020',
        'eyelinerStyle': 'winged',
        'foundationOpacity': 0.4,
        'highlighterOpacity': 0.6,
      },
      jewelryItems: ['Maang Tikka', 'Nath', 'Necklace', 'Earrings'],
      icon: '👰',
      color: Color(0xFF8B0000),
      tags: ['traditional', 'red', 'gold', 'bridal', 'classic'],
    ),
    BridalLook(
      id: 'soft_glam',
      name: 'Soft Glam Peach',
      category: 'Minimalist',
      description: 'Soft, romantic peach-toned bridal look',
      makeupParams: {
        'lipColor': '#FFB6C1',
        'lipFinish': 'gloss',
        'blushColor': '#FF9E80',
        'eyeshadowColor': '#FFD700',
        'eyelinerStyle': 'natural',
        'foundationOpacity': 0.3,
        'highlighterOpacity': 0.7,
      },
      jewelryItems: ['Maang Tikka', 'Earrings'],
      icon: '🌸',
      color: Color(0xFFFFB6C1),
      tags: ['soft', 'peach', 'romantic', 'minimalist', 'modern'],
    ),
    BridalLook(
      id: 'royal_emerald',
      name: 'Royal Emerald',
      category: 'Luxury',
      description: 'Regal emerald green with antique gold',
      makeupParams: {
        'lipColor': '#8B0000',
        'lipFinish': 'matte',
        'blushColor': '#D4505A',
        'eyeshadowColor': '#006400',
        'eyelinerStyle': 'dramatic',
        'foundationOpacity': 0.5,
        'highlighterOpacity': 0.4,
      },
      jewelryItems: ['Maang Tikka', 'Nath', 'Necklace', 'Earrings', 'Bracelet'],
      icon: '💚',
      color: Color(0xFF006400),
      tags: ['royal', 'emerald', 'luxury', 'dramatic', 'gold'],
    ),
    BridalLook(
      id: 'nude_elegance',
      name: 'Nude Elegance',
      category: 'Modern',
      description: 'Minimalist nude with pearl accents',
      makeupParams: {
        'lipColor': '#D4956A',
        'lipFinish': 'satin',
        'blushColor': '#F0C0A0',
        'eyeshadowColor': '#C8A080',
        'eyelinerStyle': 'natural',
        'foundationOpacity': 0.25,
        'highlighterOpacity': 0.8,
      },
      jewelryItems: ['Earrings', 'Necklace'],
      icon: '🤍',
      color: Color(0xFFF5F5DC),
      tags: ['nude', 'minimalist', 'elegant', 'modern', 'pearl'],
    ),
    BridalLook(
      id: 'sunset_gold',
      name: 'Sunset Gold',
      category: 'Warm',
      description: 'Golden hour glow with warm tones',
      makeupParams: {
        'lipColor': '#FF6080',
        'lipFinish': 'gloss',
        'blushColor': '#FF6F61',
        'eyeshadowColor': '#FF8C00',
        'eyelinerStyle': 'winged',
        'foundationOpacity': 0.35,
        'highlighterOpacity': 0.9,
      },
      jewelryItems: ['Maang Tikka', 'Earrings', 'Necklace'],
      icon: '🌅',
      color: Color(0xFFFF8C00),
      tags: ['warm', 'golden', 'sunset', 'glowy', 'summer'],
    ),
    BridalLook(
      id: 'pink_romance',
      name: 'Pink Romance',
      category: 'Romantic',
      description: 'Soft pink bridal with silver jewelry',
      makeupParams: {
        'lipColor': '#FF8A9B',
        'lipFinish': 'gloss',
        'blushColor': '#FFB6C1',
        'eyeshadowColor': '#E8A0B0',
        'eyelinerStyle': 'natural',
        'foundationOpacity': 0.3,
        'highlighterOpacity': 0.6,
      },
      jewelryItems: ['Earrings', 'Necklace'],
      icon: '🌹',
      color: Color(0xFFFF8A9B),
      tags: ['pink', 'romantic', 'soft', 'silver', 'girly'],
    ),
  ];

  // ===========================================================================
  // RECOMMENDATION ENGINE
  // ===========================================================================

  static BridalLook getRecommendation(FaceMetrics metrics) {
    // Score each look based on face metrics
    final scores = _bridalLooks.map((look) {
      double score = 0.0;
      
      // Face shape matching
      score += _matchFaceShape(metrics.faceShape, look.tags);
      
      // Skin tone matching
      score += _matchSkinTone(metrics.skinTone, look.tags);
      
      // Symmetry score (higher symmetry = more dramatic looks work)
      if (metrics.symmetryScore > 0.85) {
        if (look.tags.contains('dramatic') || look.tags.contains('royal')) {
          score += 0.3;
        }
      } else {
        if (look.tags.contains('soft') || look.tags.contains('natural')) {
          score += 0.2;
        }
      }
      
      // Eye shape matching
      score += _matchEyeShape(metrics.eyeShape, look.tags);
      
      // Lip shape matching
      score += _matchLipShape(metrics.lipShape, look.tags);
      
      return MapEntry(look, score);
    }).toList();
    
    // Sort by score and return highest
    scores.sort((a, b) => b.value.compareTo(a.value));
    return scores.first.key;
  }

  static double _matchFaceShape(String faceShape, List<String> tags) {
    final matches = {
      'Round': {'tags': ['soft', 'natural', 'pink'], 'weight': 0.4},
      'Oval': {'tags': ['dramatic', 'royal', 'classic'], 'weight': 0.4},
      'Heart': {'tags': ['romantic', 'soft', 'golden'], 'weight': 0.4},
      'Square': {'tags': ['minimalist', 'elegant', 'nude'], 'weight': 0.4},
    };
    
    final match = matches[faceShape];
    if (match == null) return 0.0;
    
    final matchedTags = match['tags'] as List<String>;
    final weight = match['weight'] as double;
    
    final matchCount = tags.where((tag) => matchedTags.contains(tag)).length;
    return (matchCount / matchedTags.length) * weight;
  }

  static double _matchSkinTone(String skinTone, List<String> tags) {
    final matches = {
      'Warm': {'tags': ['warm', 'golden', 'peach', 'gold'], 'weight': 0.3},
      'Cool': {'tags': ['cool', 'pink', 'silver', 'rose'], 'weight': 0.3},
      'Neutral': {'tags': ['natural', 'nude', 'soft'], 'weight': 0.3},
      'Medium': {'tags': ['classic', 'traditional', 'red'], 'weight': 0.3},
    };
    
    final match = matches[skinTone];
    if (match == null) return 0.0;
    
    final matchedTags = match['tags'] as List<String>;
    final weight = match['weight'] as double;
    
    final matchCount = tags.where((tag) => matchedTags.contains(tag)).length;
    return (matchCount / matchedTags.length) * weight;
  }

  static double _matchEyeShape(String eyeShape, List<String> tags) {
    final matches = {
      'Round': {'tags': ['soft', 'natural'], 'weight': 0.15},
      'Almond': {'tags': ['dramatic', 'winged'], 'weight': 0.15},
      'Hooded': {'tags': ['natural', 'soft'], 'weight': 0.15},
    };
    
    final match = matches[eyeShape];
    if (match == null) return 0.0;
    
    final matchedTags = match['tags'] as List<String>;
    final weight = match['weight'] as double;
    
    final matchCount = tags.where((tag) => matchedTags.contains(tag)).length;
    return (matchCount / matchedTags.length) * weight;
  }

  static double _matchLipShape(String lipShape, List<String> tags) {
    final matches = {
      'Thin': {'tags': ['gloss', 'soft', 'nude'], 'weight': 0.15},
      'Medium': {'tags': ['classic', 'satin', 'natural'], 'weight': 0.15},
      'Full': {'tags': ['matte', 'dramatic', 'bold'], 'weight': 0.15},
    };
    
    final match = matches[lipShape];
    if (match == null) return 0.0;
    
    final matchedTags = match['tags'] as List<String>;
    final weight = match['weight'] as double;
    
    final matchCount = tags.where((tag) => matchedTags.contains(tag)).length;
    return (matchCount / matchedTags.length) * weight;
  }

  // ===========================================================================
  // GET ALL LOOKS
  // ===========================================================================

  static List<BridalLook> getAllLooks() {
    return _bridalLooks;
  }

  static BridalLook? getLookById(String id) {
    try {
      return _bridalLooks.firstWhere((look) => look.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<BridalLook> getLooksByCategory(String category) {
    return _bridalLooks.where((look) => look.category == category).toList();
  }
}