// lib/services/gemini_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/skin_analysis_models.dart';

class GeminiService {
  // ===========================================================================
  // API KEY - Working!
  // ===========================================================================
  
  static const String _apiKey = 'GEMINI_API_KEY';

  // ===========================================================================
  // CONFIRMED WORKING MODELS
  // ===========================================================================

  // ✅ CONFIRMED WORKING: gemini-3.5-flash
  static const String _visionModel = 'gemini-3.5-flash';
  static const String _textModel = 'gemini-3.5-flash';

  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  // ===========================================================================
  // SKIN ANALYSIS - VISION API
  // ===========================================================================

  static Future<SkinAnalysisResult?> analyzeSkin(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prompt = '''
You are a professional dermatologist and beauty expert. Analyze this face photo and provide a detailed skin analysis.

IMPORTANT: Return ONLY valid JSON. No extra text.

{
  "skinTone": "string (e.g., Warm Olive, Cool Fair, Neutral Medium, Deep Warm)",
  "skinType": "string (e.g., Oily, Dry, Combination, Normal, Sensitive)",
  "confidence": number (0-100),
  "ageEstimate": number,
  "recommendations": {
    "lipstick": ["color1", "color2", "color3"],
    "blush": "string",
    "eyeshadow": "string",
    "foundation": "string",
    "skincare": ["product1", "product2", "product3"],
    "hairStyle": "string"
  },
  "concerns": ["concern1", "concern2", "concern3"],
  "glowScore": number (0-10),
  "skinHealth": {
    "hydration": number (0-100),
    "elasticity": number (0-100),
    "evenness": number (0-100)
  },
  "bestLooks": ["look1", "look2", "look3"],
  "celebrityMatch": "string"
}
''';

      final url = '$_baseUrl/$_visionModel:generateContent?key=$_apiKey';
      
      print('📤 Sending request to: $_visionModel');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ]
        }),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];

        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}') + 1;
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final jsonString = text.substring(jsonStart, jsonEnd);
          final result = jsonDecode(jsonString);
          print('✅ Analysis successful');
          return SkinAnalysisResult.fromJson(result);
        }
        print('❌ Could not extract JSON from response');
        return null;
      } else if (response.statusCode == 429) {
        print('❌ Rate limit exceeded. Please wait 1-2 minutes.');
        return null;
      } else {
        print('❌ API Error: ${response.statusCode}');
        print('📄 Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Analysis error: $e');
      return null;
    }
  }

  // ===========================================================================
  // CHAT - TEXT API
  // ===========================================================================

  static Future<String> sendChatMessage(String message, {String? context}) async {
    try {
      final systemPrompt = '''
You are GlowSalon AI Beauty Assistant, a professional beauty and skincare advisor for Pakistani users.

${context != null ? 'User skin analysis context: $context' : ''}

Keep responses helpful, professional, and concise (2-3 paragraphs max).
''';

      final url = '$_baseUrl/$_textModel:generateContent?key=$_apiKey';
      
      print('📤 Sending chat request to: $_textModel');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': systemPrompt},
                {'text': 'User: $message\nAssistant:'}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        return text.isNotEmpty ? text : _getFallbackResponse(message);
      } else if (response.statusCode == 429) {
        print('❌ Rate limit exceeded. Please wait 1-2 minutes.');
        return _getFallbackResponse(message);
      } else {
        print('❌ Chat API Error: ${response.statusCode}');
        return _getFallbackResponse(message);
      }
    } catch (e) {
      print('❌ Chat error: $e');
      return _getFallbackResponse(message);
    }
  }

  // ===========================================================================
  // DEMO ANALYSIS (Fallback)
  // ===========================================================================

  static SkinAnalysisResult getDemoAnalysis(File image) {
    return SkinAnalysisResult(
      skinTone: 'Warm Olive',
      skinType: 'Combination',
      confidence: 85,
      ageEstimate: 25,
      recommendations: SkinRecommendations(
        lipstick: ['Ruby Red', 'Coral Pink', 'Mauve'],
        blush: 'Peach',
        eyeshadow: 'Gold & Bronze',
        foundation: 'Medium with yellow undertones',
        skincare: ['Vitamin C Serum', 'Hyaluronic Acid', 'Sunscreen SPF 50'],
        hairStyle: 'Soft waves with side part',
      ),
      concerns: ['Mild redness', 'Slight unevenness'],
      glowScore: 8,
      health: SkinHealth(
        hydration: 75,
        elasticity: 82,
        evenness: 70,
      ),
      bestLooks: ['Bridal Classic', 'Natural Glow', 'Golden Hour'],
      celebrityMatch: 'Mahira Khan',
      analysisDate: DateTime.now().toIso8601String(),
      photoSource: 'Photo',
    );
  }

  // ===========================================================================
  // FALLBACK RESPONSES
  // ===========================================================================

  static String _getFallbackResponse(String message) {
    final lower = message.toLowerCase();
    
    if (lower.contains('skin tone') || lower.contains('skin type')) {
      return "I can help you find the perfect products for your skin! Please use the Skin Analysis feature to upload your photo for personalized recommendations.";
    }
    
    if (lower.contains('bridal') || lower.contains('wedding')) {
      return "Our bridal package includes personalized makeup, hair styling, and mehndi. Book a consultation to start your bridal beauty journey!";
    }
    
    if (lower.contains('skincare') || lower.contains('routine')) {
      return "For glowing skin: Gentle cleanser → Vitamin C (morning) → SPF 50. At night: Double cleanse → Hyaluronic acid → Retinol (2-3x/week).";
    }
    
    if (lower.contains('product') || lower.contains('recommend')) {
      return "I'd love to recommend products! Please use our Skin Analysis feature first for personalized suggestions.";
    }
    
    if (lower.contains('hello') || lower.contains('hi')) {
      return "Assalam-o-Alaikum! 👋 Welcome to GlowSalon AI Beauty Assistant! How can I help you with your beauty needs today?";
    }
    
    return "That's a great question! For personalized advice, please use our Skin Analysis feature first. I'm here to help with all your beauty needs! ✨";
  }
}
