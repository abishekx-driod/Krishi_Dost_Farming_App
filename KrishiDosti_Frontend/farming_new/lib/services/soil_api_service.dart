import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SoilApiService {
  static const String baseUrl = "http://10.0.2.2:5000/predict";

  static Future<String?> predictSoil(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));

      // FIELD NAME must match backend: file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // <----- IMPORTANT
          imageFile.path,
        ),
      );

      var response = await request.send();
      String body = await response.stream.bytesToString();

      print("🔥 API RESPONSE BODY: $body");
      print("🔥 STATUS CODE: ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(body);
        return jsonData["soil"]; // backend returns {"soil": "Black_Soil"}
      }

      return null;
    } catch (e) {
      print("❌ Soil API error: $e");
      return null;
    }
  }
}
