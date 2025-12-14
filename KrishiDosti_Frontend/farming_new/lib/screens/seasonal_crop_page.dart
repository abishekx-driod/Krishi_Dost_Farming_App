import 'package:flutter/material.dart';

class SeasonalCropPage extends StatelessWidget {
  final double temperature;
  final double humidity;
  final String description;

  SeasonalCropPage({
    super.key,
    required this.temperature,
    required this.humidity,
    required this.description,
  });

  // ------------------------------------------------------------
  // WEATHER CATEGORY BASED ON VALUES
  // ------------------------------------------------------------
  String tempCategory() {
    if (temperature <= 18) return "Cold";
    if (temperature <= 28) return "Normal";
    if (temperature <= 35) return "Hot";
    return "Very Hot";
  }

  String humidityCategory() {
    if (humidity < 40) return "Low";
    if (humidity <= 60) return "Medium";
    return "High";
  }

  String weatherType() {
    final d = description.toLowerCase();
    if (d.contains("rain")) return "Rainy";
    if (d.contains("cloud")) return "Cloudy";
    if (d.contains("clear")) return "Clear";
    return "Normal";
  }

  // ------------------------------------------------------------
  // CROP SCORING BASED ON WEATHER
  // ------------------------------------------------------------
  final crops = {
    "Rice": ["High", "Normal", "Rainy"],
    "Wheat": ["Cold", "Medium", "Cloudy"],
    "Maize": ["Hot", "Low", "Clear"],
    "Sugarcane": ["High", "Hot", "Rainy"],
    "Groundnut": ["Very Hot", "Low", "Clear"],
    "Millets": ["Hot", "Low", "Clear"],
    "Potato": ["Cold", "Medium", "Cloudy"],
    "Carrot": ["Cold", "Medium", "Cloudy"],
    "Banana": ["High", "Normal", "Rainy"],
    "Cotton": ["Hot", "Low", "Clear"],
  };

  Map<String, int> calculateScores() {
    String t = tempCategory();
    String h = humidityCategory();
    String w = weatherType();

    Map<String, int> scores = {};

    crops.forEach((crop, criteria) {
      int score = 0;

      if (criteria.contains(t)) score++;
      if (criteria.contains(h)) score++;
      if (criteria.contains(w)) score++;

      scores[crop] = score;
    });

    return scores;
  }

  // ------------------------------------------------------------
  // UI WIDGETS
  // ------------------------------------------------------------
  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF7ED), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
              blurRadius: 15, offset: Offset(0, 6), color: Colors.black12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Climate",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _row("Temperature", "${temperature.toStringAsFixed(1)}°C"),
          _row("Humidity", "$humidity%"),
          _row("Weather", description),
          _row("Temp Category", tempCategory()),
          _row("Humidity Category", humidityCategory()),
          _row("Condition", weatherType()),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _cropList(String title, List<String> crops, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 12),
          if (crops.isEmpty)
            const Text("No crops found today",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          for (var crop in crops)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.eco_rounded, color: color),
                  const SizedBox(width: 8),
                  Text(crop,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: color)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD PAGE
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final scores = calculateScores();

    final high =
        scores.entries.where((e) => e.value >= 3).map((e) => e.key).toList();

    final medium =
        scores.entries.where((e) => e.value == 2).map((e) => e.key).toList();

    final low =
        scores.entries.where((e) => e.value <= 1).map((e) => e.key).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Seasonal Crop Suitability",
          style: TextStyle(
              color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Container(
            height: 240,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF5EC78C),
                  Color(0xFF90E0A4),
                  Color(0xFFE3F6E8)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _headerCard(),
                  const SizedBox(height: 22),
                  _cropList("Highly Suitable Crops", high, Colors.green),
                  const SizedBox(height: 20),
                  _cropList("Moderately Suitable Crops", medium, Colors.orange),
                  const SizedBox(height: 20),
                  _cropList("Not Recommended Today", low, Colors.red),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
