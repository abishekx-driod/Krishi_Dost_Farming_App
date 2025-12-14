// lib/screens/disease_result_page.dart
import 'dart:io';
import 'package:flutter/material.dart';

class DiseaseResultPage extends StatelessWidget {
  final Map<String, dynamic> result;
  final File image;

  const DiseaseResultPage({
    super.key,
    required this.result,
    required this.image,
  });

  String get status => result["status"] ?? "disease";

  String get message => result["message"] ?? "";

  // Disease fields
  String get plantName => result["plant_name"]?.toString() ?? "Unknown plant";
  String get diseaseName =>
      result["disease_name"]?.toString() ?? "Not identified";

  String get severity => result["severity"]?.toString() ?? "unknown";

  String get summary =>
      result["summary"]?.toString() ?? "No detailed summary available.";

  String get prevention =>
      result["prevention"]?.toString() ?? "No prevention advice available.";

  String get solutions =>
      result["solutions"]?.toString() ?? "No solutions provided.";

  String get fertilizers =>
      result["fertilizers"]?.toString() ??
      "No fertilizer recommendation available.";

  Color getSeverityColor() {
    final s = severity.toLowerCase();
    if (s.contains("severe")) return Colors.red;
    if (s.contains("moderate")) return Colors.orange;
    if (s.contains("mild")) return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    // ---------------------------------------
    // CASE 1: NO PLANT DETECTED
    // ---------------------------------------
    if (status == "no_plant") {
      return Scaffold(
        appBar: AppBar(title: const Text("Scan Result")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }

    // ---------------------------------------
    // CASE 2: HEALTHY PLANT
    // ---------------------------------------
    if (status == "healthy") {
      return Scaffold(
        appBar: AppBar(title: const Text("Plant Health Status")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.file(image, height: 220, fit: BoxFit.cover),
                const SizedBox(height: 20),
                const Text(
                  "The plant appears healthy 🌿",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ---------------------------------------
    // CASE 3: DISEASE FOUND
    // ---------------------------------------
    final sevColor = getSeverityColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crop Disease Report"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                image,
                height: 210,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              plantName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "Disease detected: $diseaseName",
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 10),

            // Severity chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sevColor.withOpacity(0.1),
                border: Border.all(color: sevColor),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Severity: $severity",
                style: TextStyle(color: sevColor, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 20),

            _section("Doctor Summary", summary),
            _section("Prevention", prevention),
            _section("Solutions", solutions),
            _section("Recommended Fertilizers", fertilizers),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFDCDCDC)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              body,
              style: const TextStyle(height: 1.4, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
