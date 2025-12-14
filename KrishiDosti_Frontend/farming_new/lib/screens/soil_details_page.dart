// lib/screens/soil_details_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'result_page.dart';

class SoilDetailsPage extends StatefulWidget {
  final String crop;

  const SoilDetailsPage(
      {super.key,
      required this.crop,
      required String detectedMoisture,
      String? detectedSoil,
      required String detectedPh});

  @override
  State<SoilDetailsPage> createState() => _SoilDetailsPageState();
}

class _SoilDetailsPageState extends State<SoilDetailsPage> {
  final soilType = TextEditingController();
  final soilPh = TextEditingController();
  final moisture = TextEditingController();

  void _next() {
    if (soilType.text.isEmpty || soilPh.text.isEmpty || moisture.text.isEmpty) {
      Get.snackbar('Missing data', 'Please fill all details');
      return;
    }

    Get.to(
      () => ResultPage(
        crop: widget.crop,
        soilType: soilType.text.trim(),
        soilPh: soilPh.text.trim(),
        moisture: moisture.text.trim(),
        season: '',
      ),
    );
  }

  @override
  void dispose() {
    soilType.dispose();
    soilPh.dispose();
    moisture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Soil details for ${widget.crop}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: soilType,
              decoration: const InputDecoration(
                labelText: 'Soil type (e.g. Loamy, Clay, Sandy)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: soilPh,
              decoration: const InputDecoration(
                labelText: 'Soil pH (e.g. 6.5)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: moisture,
              decoration: const InputDecoration(
                labelText: 'Moisture level (e.g. Low / Medium / High)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                child: const Text('Show result'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
