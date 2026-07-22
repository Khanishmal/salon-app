// lib/services/jewelry_asset_loader.dart
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';

class JewelryAssetLoader {
  static final Map<String, ui.Image> _cache = {};

  static Future<ui.Image?> loadAsset(String assetPath) async {
    if (_cache.containsKey(assetPath)) {
      return _cache[assetPath];
    }

    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      
      _cache[assetPath] = frame.image;
      return frame.image;
    } catch (e) {
      print('Error loading asset $assetPath: $e');
      return null;
    }
  }

  static Future<Map<String, ui.Image?>> loadMultipleAssets(List<String> assetPaths) async {
    final Map<String, ui.Image?> results = {};
    for (final path in assetPaths) {
      results[path] = await loadAsset(path);
    }
    return results;
  }

  static void clearCache() {
    _cache.clear();
  }
}