// lib/models/jewelry_models.dart
import 'package:flutter/material.dart';

class JewelryAsset {
  final String id;
  final String name;
  final String category;
  final String assetPath;
  final Color defaultColor;
  final double defaultScale;
  final String icon;
  final String description;
  final Map<String, double> offset;
  final double rotation;

  const JewelryAsset({
    required this.id,
    required this.name,
    required this.category,
    required this.assetPath,
    required this.defaultColor,
    this.defaultScale = 1.0,
    required this.icon,
    this.description = '',
    this.offset = const {},
    this.rotation = 0.0,
  });

  JewelryAsset copyWith({
    String? id,
    String? name,
    String? category,
    String? assetPath,
    Color? defaultColor,
    double? defaultScale,
    String? icon,
    String? description,
    Map<String, double>? offset,
    double? rotation,
  }) {
    return JewelryAsset(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      assetPath: assetPath ?? this.assetPath,
      defaultColor: defaultColor ?? this.defaultColor,
      defaultScale: defaultScale ?? this.defaultScale,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      offset: offset ?? this.offset,
      rotation: rotation ?? this.rotation,
    );
  }
}

class JewelryAssets {
  static const List<JewelryAsset> all = [
    // Forehead Jewelry
    JewelryAsset(
      id: 'maang_tikka',
      name: 'Maang Tikka',
      category: 'Forehead',
      assetPath: 'assets/jewelry/maang_tikka.png',
      defaultColor: Color(0xFFFFD700),
      defaultScale: 0.28,
      icon: '👑',
      description: 'Traditional forehead ornament',
      offset: {'x': 0.0, 'y': -0.12},
    ),
    JewelryAsset(
      id: 'mathapatti',
      name: 'Mathapatti',
      category: 'Forehead',
      assetPath: 'assets/jewelry/mathapatti.png',
      defaultColor: Color(0xFFFFD700),
      defaultScale: 0.35,
      icon: '✨',
      description: 'Regal headpiece with chains',
      offset: {'x': 0.0, 'y': -0.08},
    ),
    JewelryAsset(
      id: 'tikka',
      name: 'Side Tikka',
      category: 'Forehead',
      assetPath: 'assets/jewelry/tikka.png',
      defaultColor: Color(0xFFFFD700),
      defaultScale: 0.15,
      icon: '💎',
      description: 'Side forehead decoration',
      offset: {'x': 0.25, 'y': -0.10},
    ),
    
    // Nose Jewelry
    JewelryAsset(
      id: 'nath',
      name: 'Bridal Nath',
      category: 'Nose',
      assetPath: 'assets/jewelry/nath.png',
      defaultColor: Color(0xFFFFD700),
      defaultScale: 0.22,
      icon: '💍',
      description: 'Traditional nose ring with pearl',
      offset: {'x': -0.03, 'y': 0.0},
    ),
    JewelryAsset(
      id: 'nath_small',
      name: 'Small Nath',
      category: 'Nose',
      assetPath: 'assets/jewelry/nath_small.png',
      defaultColor: Color(0xFFFFD700),
      defaultScale: 0.15,
      icon: '🔱',
      description: 'Minimal nose ring',
      offset: {'x': -0.02, 'y': 0.0},
    ),
    
    // Neck Jewelry
    JewelryAsset(
      id: 'necklace',
      name: 'Gold Necklace',
      category: 'Neck',
      assetPath: 'assets/jewelry/necklace.png',
      defaultColor: Color(0xFFFFD700),
      defaultScale: 1.2,
      icon: '📿',
      description: 'Elegant gold necklace with pendant',
      offset: {'x': 0.0, 'y': 0.05},
    ),
    JewelryAsset(
      id: 'kundan_necklace',
      name: 'Kundan Necklace',
      category: 'Neck',
      assetPath: 'assets/jewelry/kundan_necklace.png',
      defaultColor: Color(0xFFFFD700),
      defaultScale: 1.4,
      icon: '💠',
      description: 'Royal kundan necklace set',
      offset: {'x': 0.0, 'y': 0.08},
    ),
    JewelryAsset(
      id: 'pendant',
      name: 'Pendant',
      category: 'Neck',
      assetPath: 'assets/jewelry/pendant.png',
      defaultColor: Color(0xFFFFD700),
      defaultScale: 0.3,
      icon: '🔮',
      description: 'Beautiful pendant',
      offset: {'x': 0.0, 'y': 0.12},
    ),
    
    // Ear Jewelry
    JewelryAsset(
      id: 'jhumka',
      name: 'Jhumka',
      category: 'Ears',
      assetPath: 'assets/jewelry/jhumka.png',
      defaultColor: Color(0xFFFFD700),
      defaultScale: 0.2,
      icon: '🔔',
      description: 'Traditional bell-shaped earrings',
      offset: {'x': 0.0, 'y': 0.02},
    ),
    JewelryAsset(
      id: 'earrings',
      name: 'Chandbali',
      category: 'Ears',
      assetPath: 'assets/jewelry/earrings.png',
      defaultColor: Color(0xFFFFD700),
      defaultScale: 0.18,
      icon: '🌙',
      description: 'Moon-shaped earrings',
      offset: {'x': 0.0, 'y': 0.02},
    ),
    
    // Hand Jewelry
    JewelryAsset(
      id: 'bracelet',
      name: 'Bracelet',
      category: 'Hand',
      assetPath: 'assets/jewelry/bracelet.png',
      defaultColor: Color(0xFFFFD700),
      defaultScale: 0.25,
      icon: '⌚',
      description: 'Stylish bracelet',
      offset: {'x': 0.0, 'y': 0.0},
    ),
  ];

  static List<JewelryAsset> getByCategory(String category) {
    return all.where((asset) => asset.category == category).toList();
  }

  static JewelryAsset? getById(String id) {
    try {
      return all.firstWhere((asset) => asset.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<String> get categories {
    return all.map((asset) => asset.category).toSet().toList();
  }
}

class JewelrySet {
  final String id;
  final String name;
  final Color color;
  final String style;
  final IconData icon;
  final String description;
  final List<String> assetIds;

  const JewelrySet({
    required this.id,
    required this.name,
    required this.color,
    required this.style,
    required this.icon,
    required this.description,
    this.assetIds = const [],
  });
}

class JewelrySets {
  static const List<JewelrySet> all = [
    JewelrySet(
      id: 'gold_bridal',
      name: 'Gold Bridal',
      color: Color(0xFFFFD700),
      style: 'Traditional',
      icon: Icons.diamond,
      description: 'Complete gold bridal set',
      assetIds: ['maang_tikka', 'nath', 'necklace', 'jhumka'],
    ),
    JewelrySet(
      id: 'rose_gold',
      name: 'Rose Gold',
      color: Color(0xFFE8C07A),
      style: 'Modern',
      icon: Icons.diamond_outlined,
      description: 'Modern rose gold finish',
      assetIds: ['mathapatti', 'nath_small', 'pendant', 'earrings'],
    ),
    JewelrySet(
      id: 'kundan',
      name: 'Kundan Royal',
      color: Color(0xFFFFD700),
      style: 'Royal',
      icon: Icons.auto_awesome,
      description: 'Royal kundan jewelry set',
      assetIds: ['mathapatti', 'kundan_necklace', 'jhumka'],
    ),
    JewelrySet(
      id: 'minimal',
      name: 'Minimal',
      color: Color(0xFFC0C0C0),
      style: 'Modern',
      icon: Icons.star,
      description: 'Minimal modern jewelry',
      assetIds: ['tikka', 'pendant', 'earrings', 'bracelet'],
    ),
  ];

  static JewelrySet? getById(String id) {
    try {
      return all.firstWhere((set) => set.id == id);
    } catch (e) {
      return null;
    }
  }
}