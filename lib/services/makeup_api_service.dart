// lib/services/makeup_api_service.dart
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class MakeupApiService {
  static const String apiKey = 'sk-4puzhwJCyIZBD7eOr_SnVbTjsJE2y7SyXINfNXJksi4LQbGOJAciHiseyPABgkdP'; // Replace with your real key
  static const String endpoint = 'https://yce.perfectcorp.com/api/v1/makeup/apply';

  Future<Uint8List?> applyAutoMakeup(Uint8List imageBytes) async {
    var request = http.MultipartRequest('POST', Uri.parse(endpoint));
    
    // Auth & File
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.files.add(
      http.MultipartFile.fromBytes('image', imageBytes, filename: 'input.jpg'),
    );

    // Automatic parameters - YouCam usually requires a template or "look" ID
    request.fields['lookId'] = 'NATURAL_01'; // Example ID for a pre-set look
    
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return response.bodyBytes; // This is your new makeup image
      } else {
        print('Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Connection Error: $e');
      return null;
    }
  }
}