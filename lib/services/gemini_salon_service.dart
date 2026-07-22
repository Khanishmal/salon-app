import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/salon_model.dart';

class GeminiSalonService {
  // Using the same working API key from your gemini_service.dart
  static const String _apiKey = 'Gemini api key';
  static const String _textModel = 'gemini-3.5-flash';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  /// Get AI-powered salon recommendations based on user preferences
  static Future<List<SalonRecommendation>> getSalonRecommendations({
    required double userLat,
    required double userLng,
    required List<Map<String, dynamic>> nearbySalons,
    String? query,
    String? category,
  }) async {
    try {
      if (nearbySalons.isEmpty) return [];

      // Build salon data string
      final salonData = nearbySalons.map((s) {
        return '- ${s['name']}: ${s['category']}, Rating: ${s['rating'] ?? 0.0}, ${s['distance']?.toStringAsFixed(1) ?? '?'}km away';
      }).join('\n');

      final prompt = '''
You are GlowSalon AI Beauty Assistant helping users find the best salons near them.

USER LOCATION: $userLat, $userLng
USER SEARCH: ${query ?? 'Any'}
CATEGORY PREFERENCE: ${category ?? 'Any'}

NEARBY SALONS (${nearbySalons.length} total):
$salonData

Analyze these salons and recommend the best 5 based on:
1. Proximity to user
2. Rating
3. Category match
4. Services offered

Return ONLY valid JSON. No extra text.

{
  "recommendations": [
    {
      "salonName": "string",
      "reason": "Why this salon is recommended",
      "matchScore": number (0-100),
      "bestServices": ["service1", "service2"]
    }
  ],
  "overallAdvice": "string (brief advice on choosing the right salon)",
  "bestCategory": "string (best category for user)"
}
''';

      final url = '$_baseUrl/$_textModel:generateContent?key=$_apiKey';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];

        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}') + 1;
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonString = text.substring(jsonStart, jsonEnd);
          final result = jsonDecode(jsonString);
          return _parseRecommendations(result);
        }
        return [];
      } else {
        print('❌ Gemini API Error: ${response.statusCode}');
        return _getFallbackRecommendations(nearbySalons);
      }
    } catch (e) {
      print('❌ Gemini recommendation error: $e');
      return _getFallbackRecommendations(nearbySalons);
    }
  }

  static List<SalonRecommendation> _parseRecommendations(Map<String, dynamic> data) {
    final List<SalonRecommendation> recommendations = [];
    
    if (data['recommendations'] != null) {
      for (final rec in data['recommendations'] as List) {
        recommendations.add(SalonRecommendation(
          salonName: rec['salonName'] ?? '',
          reason: rec['reason'] ?? '',
          matchScore: (rec['matchScore'] ?? 0).toDouble(),
          bestServices: List<String>.from(rec['bestServices'] ?? []),
        ));
      }
    }
    
    return recommendations;
  }

  static List<SalonRecommendation> _getFallbackRecommendations(List<Map<String, dynamic>> salons) {
    // Sort by distance and rating
    final sorted = List<Map<String, dynamic>>.from(salons);
    sorted.sort((a, b) {
      final distA = a['distance'] ?? double.infinity;
      final distB = b['distance'] ?? double.infinity;
      return distA.compareTo(distB);
    });

    final recommendations = <SalonRecommendation>[];
    for (int i = 0; i < sorted.length && i < 5; i++) {
      final s = sorted[i];
      recommendations.add(SalonRecommendation(
        salonName: s['name'] ?? '',
        reason: '${s['distance']?.toStringAsFixed(1) ?? '?'} km away • Rating: ${s['rating'] ?? 0.0}',
        matchScore: 80 - (i * 10),
        bestServices: List<String>.from(s['services'] ?? []).take(2).toList(),
      ));
    }
    return recommendations;
  }

  /// Get intelligent salon search suggestions
  static Future<List<String>> getSearchSuggestions(String query) async {
    if (query.length < 2) return [];

    try {
      final prompt = '''
You are GlowSalon AI. Suggest 5 salon search terms for: "$query"
Return ONLY valid JSON array. No extra text.
["suggestion1", "suggestion2", "suggestion3", "suggestion4", "suggestion5"]
''';

      final url = '$_baseUrl/$_textModel:generateContent?key=$_apiKey';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        final jsonStart = text.indexOf('[');
        final jsonEnd = text.lastIndexOf(']') + 1;
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonString = text.substring(jsonStart, jsonEnd);
          final result = jsonDecode(jsonString);
          return List<String>.from(result);
        }
        return [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
