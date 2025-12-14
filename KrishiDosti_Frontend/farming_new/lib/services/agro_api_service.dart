import 'dart:convert';
import 'package:http/http.dart' as http;

class AgroApi {
  static String baseUrl = "http://10.0.2.2:8000";

  // -------------------------------------------------------
  // 1️⃣ TEXT → AI REPLY  (English/Hindi)
  // -------------------------------------------------------
  static Future<String> getBotReply(String text, String lang) async {
    try {
      final url = Uri.parse("$baseUrl/chat");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "lang": lang, // send language to backend
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["reply"] ?? "No reply received";
      }

      return "❌ Server error: ${response.statusCode}";
    } catch (e) {
      return "❌ Network error: $e";
    }
  }

  // -------------------------------------------------------
  // 2️⃣ SPEECH → TEXT
  // -------------------------------------------------------
  static Future<String> speechToText(String lang) async {
    try {
      final url = Uri.parse("$baseUrl/stt?lang=$lang");

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["text"] ?? "";
      }

      return "";
    } catch (e) {
      return "";
    }
  }

  // -------------------------------------------------------
  // 3️⃣ TEXT → SPEECH (future use)
  // -------------------------------------------------------
  static Future<String> textToSpeech(String text) async {
    try {
      final url = Uri.parse("$baseUrl/tts");

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return "$baseUrl${data['file']}";
      }

      return "";
    } catch (e) {
      return "";
    }
  }
}
