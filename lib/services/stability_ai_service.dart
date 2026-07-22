// lib/services/stability_ai_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class StabilityAIService {
  static const String _apiKey = 'sk-cgGrCg8JNjJCvPcrjf3VLjfoXiH92HvrG18CA8Esh8sGFRWs'; // Replace with your key
  static const String _baseUrl = 'https://api.stability.ai/v1';

  // ===========================================================================
  // BRIDAL MAKEOVER - Image-to-Image with ControlNet
  // ===========================================================================

  static Future<File?> applyBridalMakeup({
    required File image,
    required String theme,
    required String jewelry,
    required String intensity,
  }) async {
    try {
      final bytes = await image.readAsBytes();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/generation/stable-diffusion-xl-1024-v1-0/image-to-image'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'image/png',
      });

      // Attach image
      request.files.add(
        http.MultipartFile.fromBytes(
          'init_image',
          bytes,
          filename: 'image.png',
        ),
      );

      // Build prompt based on selections
      final prompt = _buildBridalPrompt(theme, jewelry, intensity);

      request.fields.addAll({
        'prompt': prompt,
        'negative_prompt': 'blurry, low quality, distorted, deformed, extra limbs, asymmetrical, cartoon, anime',
        'strength': '0.45', // Lower strength preserves face features
        'cfg_scale': '7',
        'samples': '1',
        'steps': '30',
        'style_preset': 'photographic',
      });

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/bridal_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(responseData.bodyBytes);
        return file;
      } else {
        print('Stability AI Error: ${response.statusCode} - ${responseData.body}');
        return null;
      }
    } catch (e) {
      print('Bridal makeup error: $e');
      return null;
    }
  }

  static String _buildBridalPrompt(String theme, String jewelry, String intensity) {
    final style = intensity == 'Glamorous & Defined' 
        ? 'dramatic, high-fashion, editorial, bold makeup' 
        : 'soft, luminous, natural, romantic makeup';
    
    return '''
Professional bridal makeup portrait photo. $theme bridal theme with $jewelry jewelry.
$style with flawless foundation, defined eyeshadow, winged eyeliner, 
volumized lashes, matte lipstick, subtle highlighter.
Studio lighting, 8k resolution, photorealistic, high quality, magazine cover style.
''';
  }

  // ===========================================================================
  // JEWELRY TRY-ON - Image-to-Image
  // ===========================================================================

  static Future<File?> applyJewelry({
    required File image,
    required String jewelryType,
    required String metal,
    required double size,
  }) async {
    try {
      final bytes = await image.readAsBytes();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/generation/stable-diffusion-xl-1024-v1-0/image-to-image'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'image/png',
      });

      request.files.add(
        http.MultipartFile.fromBytes(
          'init_image',
          bytes,
          filename: 'image.png',
        ),
      );

      final prompt = _buildJewelryPrompt(jewelryType, metal, size);

      request.fields.addAll({
        'prompt': prompt,
        'negative_prompt': 'blurry, distorted, deformed, extra limbs, cartoon, anime',
        'strength': '0.35', // Lower to preserve face
        'cfg_scale': '7',
        'samples': '1',
        'steps': '30',
        'style_preset': 'photographic',
      });

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/jewelry_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(responseData.bodyBytes);
        return file;
      } else {
        print('Jewelry API Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Jewelry error: $e');
      return null;
    }
  }

  static String _buildJewelryPrompt(String jewelryType, String metal, double size) {
    final sizeDesc = size > 1.2 ? 'large, prominent' : size < 0.8 ? 'delicate, subtle' : 'moderate sized';
    
    return '''
Add virtual $metal ${_getJewelryDescription(jewelryType)} jewelry to this person's face.
$sizeDesc jewelry piece positioned correctly on the face.
Realistic metal reflection, 3D appearance, studio lighting, photorealistic.
''';
  }

  static String _getJewelryDescription(String type) {
    switch (type) {
      case 'Maang Tikka': return 'Maang Tikka (forehead ornament) placed on center of forehead';
      case 'Nath': return 'Nath (nose ring) on the left side of nose';
      case 'Necklace': return 'Necklace around the neck';
      case 'Earrings': return 'Earrings on both ears';
      case 'Full Set': return 'Full bridal set: Maang Tikka, Nath, Necklace, and Earrings';
      default: return 'jewelry';
    }
  }

  // ===========================================================================
  // MEHNDI APPLICATION - Image-to-Image
  // ===========================================================================

  static Future<File?> applyMehndi({
    required File image,
    required String style,
    required String color,
    required double density,
  }) async {
    try {
      final bytes = await image.readAsBytes();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/generation/stable-diffusion-xl-1024-v1-0/image-to-image'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'image/png',
      });

      request.files.add(
        http.MultipartFile.fromBytes(
          'init_image',
          bytes,
          filename: 'image.png',
        ),
      );

      final prompt = _buildMehndiPrompt(style, color, density);

      request.fields.addAll({
        'prompt': prompt,
        'negative_prompt': 'blurry, distorted, deformed, cartoon, anime',
        'strength': '0.4',
        'cfg_scale': '7',
        'samples': '1',
        'steps': '30',
        'style_preset': 'photographic',
      });

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/mehndi_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(responseData.bodyBytes);
        return file;
      } else {
        print('Mehndi API Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Mehndi error: $e');
      return null;
    }
  }

  static String _buildMehndiPrompt(String style, String color, double density) {
    final densityDesc = density > 0.8 ? 'full coverage, dense pattern' : 
                         density > 0.5 ? 'medium coverage, balanced pattern' : 
                         'light coverage, sparse pattern';
    
    return '''
Apply $style mehndi (henna) design to this hand. $color color, $densityDesc.
Traditional bridal mehndi pattern with intricate details, natural look, photorealistic.
''';
  }

  // ===========================================================================
  // SKIN ANALYSIS - Using Gemini Vision
  // ===========================================================================

  static Future<Map<String, dynamic>?> analyzeSkin(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      const geminiKey = 'YOUR_GEMINI_API_KEY';
      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=$geminiKey'
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''
You are a professional dermatologist. Analyze this face photo and provide a detailed skin analysis.

Return ONLY valid JSON in this format:
{
  "skinTone": "string",
  "skinType": "string",
  "confidence": number,
  "ageEstimate": number,
  "recommendations": {
    "lipstick": ["color1", "color2", "color3"],
    "blush": "string",
    "eyeshadow": "string",
    "foundation": "string",
    "skincare": ["product1", "product2", "product3"]
  },
  "concerns": ["concern1", "concern2", "concern3"],
  "glowScore": number,
  "skinHealth": {
    "hydration": number,
    "elasticity": number,
    "evenness": number
  },
  "bestLooks": ["look1", "look2", "look3"]
}
'''
                },
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}') + 1;
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          return jsonDecode(text.substring(jsonStart, jsonEnd));
        }
      }
      return null;
    } catch (e) {
      print('Skin analysis error: $e');
      return null;
    }
  }
}