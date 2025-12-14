// lib/screens/result_page.dart

import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final String crop;
  final String soilType;
  final String soilPh;
  final String moisture;

  const ResultPage({
    super.key,
    required this.crop,
    required this.soilType,
    required this.soilPh,
    required this.moisture,
    required String season,
  });

  // ---------- pH SUGGESTION ----------
  String _phSuggestion() {
    double? ph = double.tryParse(soilPh);
    if (ph == null) return "Invalid pH value received.";

    if (ph < 6.0) {
      return "Your soil is acidic. Apply lime, organic compost and maintain balanced NPK.";
    } else if (ph > 7.5) {
      return "Your soil is alkaline. Add organic matter, avoid over-liming and improve soil structure.";
    } else {
      return "Your soil pH is ideal for most crops. Maintain with organic matter.";
    }
  }

  // ---------- Moisture Suggestion ----------
  String _moistureSuggestion() {
    double? m = double.tryParse(moisture);
    if (m == null) return "Invalid moisture value.";

    if (m < 30) return "Soil moisture is low. Irrigation is recommended.";
    if (m > 80) return "Soil moisture is high. Ensure proper drainage.";
    return "Soil moisture level is suitable.";
  }

  @override
  Widget build(BuildContext context) {
    final phNote = _phSuggestion();
    final moistureNote = _moistureSuggestion();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        title: const Text("Crop Recommendation"),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ====== ⭐ CROP RESULT CARD ======
            _resultCard(
              title: "Recommended Crop",
              icon: Icons.eco,
              color: Colors.green.shade600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crop,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Based on your soil condition and weather inputs, this crop is the best recommended choice.",
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ====== ⭐ USER INPUT SUMMARY ======
            _resultCard(
              title: "Your Input Summary",
              icon: Icons.list_alt,
              color: Colors.blue.shade700,
              child: Column(
                children: [
                  _infoRow("Soil Type", soilType),
                  _infoRow("Soil pH", soilPh),
                  _infoRow("Moisture (%)", moisture),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ====== ⭐ INTERPRETATION CARD ======
            _resultCard(
              title: "Soil Health Report",
              icon: Icons.science,
              color: Colors.orange.shade700,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bulletPoint("pH Status", phNote),
                  _bulletPoint("Moisture Status", moistureNote),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ====== ⭐ GENERAL RECOMMENDATIONS ======
            _resultCard(
              title: "General Recommendations",
              icon: Icons.tips_and_updates,
              color: Colors.deepPurple,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "• Add organic compost regularly for soil health.",
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "• Use drip irrigation to maintain moisture balance.",
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "• Perform soil testing every 6 months for accuracy.",
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- CARD CONTAINER ----------
  Widget _resultCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ---------- ROW UI ----------
  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ),
          const Text(" : "),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- BULLET POINT ----------
  Widget _bulletPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•  ", style: TextStyle(fontSize: 15)),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: "$title: ",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w400,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
