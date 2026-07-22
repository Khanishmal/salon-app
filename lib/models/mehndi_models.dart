import 'package:flutter/material.dart';

class MehndiPattern {
  final String id;
  final String name;
  final String category;
  final String assetPath;
  final String icon;
  final String description;
  final List<String> tags;

  const MehndiPattern({
    required this.id,
    required this.name,
    required this.category,
    required this.assetPath,
    required this.icon,
    required this.description,
    this.tags = const [],
  });
}

class MehndiPatterns {
  static const List<MehndiPattern> all = [
    // Arabic Patterns
    MehndiPattern(
      id: 'arabic_leaves',
      name: 'Arabic Leaves',
      category: 'Arabic',
      assetPath: 'assets/mehndi/arabic_leaves.jpeg',
      icon: '🍃',
      description: 'Beautiful leaf motifs with elegant curves',
      tags: ['leaf', 'curved', 'delicate'],
    ),
    
    // Mandala Patterns
    MehndiPattern(
      id: 'mandala_flower',
      name: 'Flower Mandala',
      category: 'Mandala',
      assetPath: 'assets/mehndi/mandala_flower.jpeg',
      icon: '🌸',
      description: 'Floral mandala with intricate petal work',
      tags: ['floral', 'mandala', 'petals'],
    ),
    
    // Bridal Patterns
    MehndiPattern(
      id: 'bridal_full',
      name: 'Full Bridal',
      category: 'Bridal',
      assetPath: 'assets/mehndi/bridal.jpeg',
      icon: '👰',
      description: 'Complete bridal hand coverage',
      tags: ['bridal', 'dense', 'traditional'],
    ),
    
    // Modern Patterns
    MehndiPattern(
      id: 'geometric_lines',
      name: 'Geometric Lines',
      category: 'Modern',
      assetPath: 'assets/mehndi/geometric_lines.jpeg',
      icon: '📐',
      description: 'Modern geometric line art',
      tags: ['geometric', 'modern', 'lines'],
    ),
  ];

  static List<MehndiPattern> getByCategory(String category) {
    return all.where((p) => p.category == category).toList();
  }

  static List<String> get categories {
    return all.map((p) => p.category).toSet().toList();
  }

  static MehndiPattern? getById(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}