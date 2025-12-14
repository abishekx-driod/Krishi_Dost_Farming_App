import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class DiseaseApiService {
  static const String baseUrl = "http://10.0.2.2:7000/analyze";

  static Future<Map<String, dynamic>> analyzeDisease(File imageFile) async {
    final uri = Uri.parse(baseUrl);
    final request = http.MultipartRequest('POST', uri);

    // IMPORTANT: backend expects 'image' OR 'file'. We use 'image'.
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    print("🧪 Disease API status: ${streamed.statusCode}");
    print("🧪 Disease API response: $body");

    if (streamed.statusCode == 200) {
      try {
        final decoded = jsonDecode(body) as Map<String, dynamic>;
        return decoded;
      } catch (e) {
        throw Exception(
            "Failed to parse disease API JSON: $e\nResponse: $body");
      }
    } else {
      throw Exception("Disease API error: ${streamed.statusCode} $body");
    }
  }
}
