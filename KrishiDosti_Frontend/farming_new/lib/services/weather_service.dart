// lib/services/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // 🔑 Your OpenWeather API key
  final String apiKey = "8c7da963c2884f63aaba5e4e86a99e43";

  Future<Map<String, dynamic>> fetchWeather(double lat, double lon) async {
    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey";

    print("➡ WeatherService: calling URL = $url");

    final response = await http.get(Uri.parse(url));

    print("⬅ WeatherService: status = ${response.statusCode}");
    print("⬅ WeatherService: body = ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        throw Exception("WeatherService: Unexpected JSON format (not a map)");
      }
    } else {
      throw Exception(
          "WeatherService: Failed with HTTP ${response.statusCode}");
    }
  }
}
