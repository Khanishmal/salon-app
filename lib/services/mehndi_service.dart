// lib/services/mehndi_service.dart
//
// AI mehndi application service.
//
// KEY FIX vs. the previous version: stable-diffusion-v1-5 through the plain
// HF Inference API is a TEXT-TO-IMAGE model. It never looks at the uploaded
// hand photo, so the "henna" you got back was a random AI image blended on
// top of the hand — never actually aligned to fingers/palm lines. That is
// why it never looked right.
//
// To put henna ON the actual hand you must use an IMAGE-TO-IMAGE (or
// ControlNet/inpainting) model that is conditioned on the uploaded photo.
// This file calls HF's image-to-image endpoint (instruct-pix2pix, which is
// built for "edit this exact photo" tasks) as the primary path, with an
// optional Replicate ControlNet path as a stronger secondary option, and a
// clearly-labeled local fallback so the UI never lies about what produced
// the result.
//
// SECURITY: no API keys are hardcoded here. Pass them at build/run time:
//   flutter run --dart-define=HF_TOKEN=hf_xxx --dart-define=REPLICATE_TOKEN=r8_xxx
// or wire up flutter_dotenv and read from a gitignored .env file.
// If a token was ever committed to source control, it must be revoked and
// rotated at the provider dashboard — treat it as compromised.

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/mehndi_models.dart';

/// Which stage produced the final image — the UI uses this to be honest
/// with the user instead of pretending everything came from AI.
enum MehndiSource { aiHuggingFace, aiReplicate, localFallback }

class MehndiResult {
  final File file;
  final MehndiSource source;
  final String? note;
  MehndiResult(this.file, this.source, {this.note});
}

class MehndiService {
  // ---- Credentials (never hardcode literals here) -----------------------
  static const String _hfToken = String.fromEnvironment('HF_TOKEN');
  static const String _replicateToken =
      String.fromEnvironment('REPLICATE_TOKEN');

  // Image-to-image model: preserves the input photo's structure and edits
  // it per instruction. Good free-tier fit for "add henna to this hand".
  static const String _hfImg2ImgEndpoint =
      'https://api-inference.huggingface.co/models/timbrooks/instruct-pix2pix';

  // Optional stronger path: a ControlNet model on Replicate conditioned on
  // the hand's edges/pose so the henna truly follows finger contours.
  // Replicate requires a specific model "version" id, which changes as
  // model owners publish new versions — grab the current one from the
  // model's page on replicate.com and paste it here before using this path.
  static const String _replicateControlNetVersion =
      'PASTE_CURRENT_VERSION_ID_FROM_REPLICATE_MODEL_PAGE';
  static const String _replicateModel =
      'jagilley/controlnet-canny'; // swap for a henna-tuned model if you find one

  static const Duration _requestTimeout = Duration(seconds: 45);

  /// Main entry point. Tries AI providers in order, falls back to a local
  /// asset-based overlay only if every AI path fails, and always reports
  /// which one actually produced the image.
  static Future<MehndiResult?> applyMehndiPattern({
    required File imageFile,
    required String patternAssetPath,
    required Color color,
    required double opacity,
    bool useAI = true,
    String? patternId,
  }) async {
    if (!useAI) {
      final local = await _applyLocalAssetOverlay(
          imageFile, patternAssetPath, color, opacity);
      return local == null
          ? null
          : MehndiResult(local, MehndiSource.localFallback);
    }

    final String prompt = _buildEditPrompt(patternId, color);

    if (_hfToken.isNotEmpty) {
      final hf = await _applyWithHuggingFaceImg2Img(imageFile, prompt);
      if (hf != null) return MehndiResult(hf, MehndiSource.aiHuggingFace);
    }

    if (_replicateToken.isNotEmpty &&
        _replicateControlNetVersion != 'PASTE_CURRENT_VERSION_ID_FROM_REPLICATE_MODEL_PAGE') {
      final rp = await _applyWithReplicateControlNet(imageFile, prompt);
      if (rp != null) return MehndiResult(rp, MehndiSource.aiReplicate);
    }

    // Every AI path failed (no key set, model cold/overloaded, rate
    // limited, network down, etc.) — fall back but say so.
    final local = await _applyLocalAssetOverlay(
        imageFile, patternAssetPath, color, opacity);
    return local == null
        ? null
        : MehndiResult(
            local,
            MehndiSource.localFallback,
            note: _hfToken.isEmpty && _replicateToken.isEmpty
                ? 'No AI provider configured — showing a local pattern preview.'
                : 'AI generation failed or timed out — showing a local pattern preview.',
          );
  }

  // ---- Provider 1: Hugging Face image-to-image ---------------------------

  static Future<File?> _applyWithHuggingFaceImg2Img(
      File imageFile, String prompt) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final b64 = base64Encode(bytes);

      // instruct-pix2pix's Inference API contract: base64 image + text
      // instruction under "parameters". image_guidance_scale keeps the
      // output close to the original hand; raise guidance_scale for a
      // stronger henna effect.
      final body = jsonEncode({
        'inputs': prompt,
        'parameters': {
          'image': b64,
          'guidance_scale': 7.5,
          'image_guidance_scale': 1.5,
          'num_inference_steps': 30,
        },
      });

      final result = await _postWithModelWarmupRetry(
        Uri.parse(_hfImg2ImgEndpoint),
        headers: {
          'Authorization': 'Bearer $_hfToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (result == null) return null;

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFile = File('${directory.path}/mehndi_hf_$timestamp.png');
      await outputFile.writeAsBytes(result);
      return outputFile;
    } catch (e) {
      // ignore: avoid_print
      print('HF image-to-image failed: $e');
      return null;
    }
  }

  /// HF serverless models return 503 with an `estimated_time` while they
  /// spin up ("cold start"). Retrying with that wait time is the difference
  /// between "the API is broken" and "it just needed 20 seconds".
  static Future<List<int>?> _postWithModelWarmupRetry(
    Uri url, {
    required Map<String, String> headers,
    required String body,
    int maxAttempts = 3,
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      http.Response response;
      try {
        response = await http
            .post(url, headers: headers, body: body)
            .timeout(_requestTimeout);
      } on TimeoutException {
        // ignore: avoid_print
        print('HF request timed out (attempt $attempt)');
        continue;
      }

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }

      if (response.statusCode == 503) {
        double waitSeconds = 10;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['estimated_time'] != null) {
            waitSeconds = (decoded['estimated_time'] as num).toDouble();
          }
        } catch (_) {}
        // ignore: avoid_print
        print('Model loading, waiting ${waitSeconds}s (attempt $attempt)');
        await Future.delayed(Duration(seconds: waitSeconds.ceil().clamp(1, 30)));
        continue;
      }

      // ignore: avoid_print
      print('HF API error ${response.statusCode}: ${response.body}');
      return null;
    }
    return null;
  }

  // ---- Provider 2: Replicate ControlNet (optional, stronger) -------------
  //
  // Replicate's flow is async: create a prediction, poll until it succeeds.

  static Future<File?> _applyWithReplicateControlNet(
      File imageFile, String prompt) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final b64 = 'data:image/png;base64,${base64Encode(bytes)}';

      final createResponse = await http
          .post(
            Uri.parse('https://api.replicate.com/v1/predictions'),
            headers: {
              'Authorization': 'Token $_replicateToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'version': _replicateControlNetVersion,
              'input': {
                'image': b64,
                'prompt': prompt,
                'num_inference_steps': 25,
              },
            }),
          )
          .timeout(_requestTimeout);

      if (createResponse.statusCode != 201 && createResponse.statusCode != 200) {
        // ignore: avoid_print
        print('Replicate create failed: ${createResponse.statusCode} ${createResponse.body}');
        return null;
      }

      final created = jsonDecode(createResponse.body);
      final String getUrl = created['urls']['get'];

      // Poll for completion.
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 2));
        final poll = await http.get(
          Uri.parse(getUrl),
          headers: {'Authorization': 'Token $_replicateToken'},
        );
        final polled = jsonDecode(poll.body);
        final status = polled['status'];

        if (status == 'succeeded') {
          final output = polled['output'];
          final String imageUrl = output is List ? output.last : output;
          final imgResponse = await http.get(Uri.parse(imageUrl));
          if (imgResponse.statusCode == 200) {
            final directory = await getTemporaryDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final outputFile =
                File('${directory.path}/mehndi_replicate_$timestamp.png');
            await outputFile.writeAsBytes(imgResponse.bodyBytes);
            return outputFile;
          }
          return null;
        }
        if (status == 'failed' || status == 'canceled') {
          // ignore: avoid_print
          print('Replicate prediction $status: ${polled['error']}');
          return null;
        }
        // else "starting" / "processing" — keep polling
      }
      return null; // timed out waiting
    } catch (e) {
      // ignore: avoid_print
      print('Replicate ControlNet failed: $e');
      return null;
    }
  }

  // ---- Prompt building ----------------------------------------------------

  static String _buildEditPrompt(String? patternId, Color color) {
    final style = _getPatternStyle(patternId);
    final colorName = _colorToName(color);
    // instruct-pix2pix wants an *instruction*, not a scene description.
    return 'Add intricate $style henna mehndi tattoo patterns in $colorName '
        'ink onto the hand in this photo, following the natural lines of the '
        'fingers and palm, keep the hand shape, skin tone and pose exactly '
        'the same, only add the henna design, photorealistic';
  }

  static String _colorToName(Color color) {
    final r = color.red, g = color.green, b = color.blue;
    if (r > 200 && g < 100 && b < 100) return 'deep red';
    if (r > 180 && g > 100 && b < 80) return 'reddish brown';
    if (r > 150 && g > 100 && b < 80) return 'brown';
    if (r > 120 && g > 80 && b < 60) return 'dark brown';
    if (r < 100 && g < 80 && b < 60) return 'very dark brown';
    if (r > 180 && g > 150 && b < 100) return 'golden brown';
    return 'natural henna';
  }

  static String _getPatternStyle(String? patternId) {
    if (patternId == null) return 'traditional';
    const styles = {
      'arabic_vines': 'Arabic vine',
      'arabic_leaves': 'Arabic leaf',
      'mandala_classic': 'mandala',
      'mandala_flower': 'floral mandala',
      'bridal_full': 'bridal full-hand',
      'bridal_wrist': 'wrist and bracelet',
      'minimal_dots': 'minimalist dotted',
      'geometric_lines': 'geometric line',
    };
    return styles[patternId] ?? 'traditional';
  }

  // ---- Local fallback: honest asset overlay, not a random blend ----------
  //
  // This is intentionally the LAST resort, and is labeled as such in the
  // UI via MehndiResult.source — it overlays a real pattern asset rather
  // than scattering pixels from an unrelated generated image.

  static Future<File?> _applyLocalAssetOverlay(
      File imageFile, String patternAssetPath, Color color, double opacity) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return null;

      img.Image? pattern;
      if (patternAssetPath.isNotEmpty) {
        try {
          final patternData = await rootBundle.load(patternAssetPath);
          pattern = img.decodeImage(patternData.buffer.asUint8List());
        } catch (_) {
          pattern = null;
        }
      }

      final result = img.Image.from(original);

      if (pattern != null) {
        final scaleFactor = 0.4;
        final scaledWidth = (original.width * scaleFactor).toInt();
        final scaledHeight = (original.height * scaleFactor).toInt();
        final resizedPattern =
            img.copyResize(pattern, width: scaledWidth, height: scaledHeight);
        final offsetX = (original.width - scaledWidth) ~/ 2;
        final offsetY = (original.height - scaledHeight) ~/ 2;

        for (int y = 0; y < resizedPattern.height; y++) {
          for (int x = 0; x < resizedPattern.width; x++) {
            final p = resizedPattern.getPixel(x, y);
            if (p.a > 30) {
              final tx = offsetX + x, ty = offsetY + y;
              if (tx < original.width && ty < original.height) {
                final orig = result.getPixel(tx, ty);
                final blend = (p.a / 255.0) * opacity * 0.8;
                result.setPixel(
                    tx,
                    ty,
                    img.ColorRgb8(
                      (orig.r * (1 - blend) + color.red * blend).toInt().clamp(0, 255),
                      (orig.g * (1 - blend) + color.green * blend).toInt().clamp(0, 255),
                      (orig.b * (1 - blend) + color.blue * blend).toInt().clamp(0, 255),
                    ));
              }
            }
          }
        }
      } else {
        // No asset available either — draw a simple radial mandala guide
        // so the preview isn't blank. Clearly a placeholder, not "AI henna".
        final centerX = original.width ~/ 2;
        final centerY = original.height ~/ 2;
        final radius = (original.width * 0.20).toInt();
        for (int i = 0; i < 360; i += 6) {
          final angle = i * math.pi / 180;
          for (double rf = 0.3; rf <= 1.0; rf += 0.1) {
            final r = radius * rf;
            final x = centerX + (r * math.cos(angle)).toInt();
            final y = centerY + (r * math.sin(angle)).toInt();
            if (x >= 0 && x < original.width && y >= 0 && y < original.height) {
              final orig = result.getPixel(x, y);
              final blend = 0.6 * opacity;
              result.setPixel(
                  x,
                  y,
                  img.ColorRgb8(
                    (orig.r * (1 - blend) + color.red * blend).toInt().clamp(0, 255),
                    (orig.g * (1 - blend) + color.green * blend).toInt().clamp(0, 255),
                    (orig.b * (1 - blend) + color.blue * blend).toInt().clamp(0, 255),
                  ));
            }
          }
        }
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFile = File('${directory.path}/mehndi_local_$timestamp.png');
      await outputFile.writeAsBytes(img.encodePng(result));
      return outputFile;
    } catch (e) {
      // ignore: avoid_print
      print('Local overlay error: $e');
      return null;
    }
  }

  // ---- History (unchanged logic, kept intact) -----------------------------

  static Future<void> saveToHistory({
    required String originalPath,
    required String processedPath,
    required String patternName,
    required String color,
    required String source,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? historyJson = prefs.getString('mehndi_history');
      List<dynamic> history = [];
      if (historyJson != null && historyJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(historyJson);
          if (decoded is List) history = decoded;
        } catch (_) {
          history = [];
        }
      }
      history.insert(0, {
        'originalImagePath': originalPath,
        'processedImagePath': processedPath,
        'patternName': patternName,
        'color': color,
        'source': source,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await prefs.setString('mehndi_history', jsonEncode(history));
    } catch (e) {
      // ignore: avoid_print
      print('Error saving history: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('mehndi_history');
      if (historyJson == null || historyJson.isEmpty) return [];
      final decoded = jsonDecode(historyJson);
      if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> deleteHistoryItem(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('mehndi_history');
      if (historyJson == null || historyJson.isEmpty) return;
      final List<dynamic> history = jsonDecode(historyJson);
      if (index < history.length) {
        history.removeAt(index);
        await prefs.setString('mehndi_history', jsonEncode(history));
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting history: $e');
    }
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mehndi_history');
  }
}