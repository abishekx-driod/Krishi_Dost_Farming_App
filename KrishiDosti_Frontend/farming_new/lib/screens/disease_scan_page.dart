// lib/screens/disease_scan_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/disease_api_service.dart';
import 'disease_result_page.dart';

class DiseaseScanPage extends StatefulWidget {
  const DiseaseScanPage({super.key});

  @override
  State<DiseaseScanPage> createState() => _DiseaseScanPageState();
}

class _DiseaseScanPageState extends State<DiseaseScanPage> {
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null) return;

      final file = File(picked.path);

      setState(() => _loading = true);

      // This returns Map<String, dynamic>? from API
      final Map<String, dynamic> result =
          await DiseaseApiService.analyzeDisease(file);

      setState(() => _loading = false);

      if (!mounted) return;

      // From here, result is non-null → pass to DiseaseResultPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiseaseResultPage(
            result: result, // non-null Map<String, dynamic>
            image: file,
          ),
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to analyze image: $e")),
      );
    }
  }

  Widget _buildButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(text),
        ),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crop disease detection"),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_florist,
                  size: 70,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Scan your crop leaf for disease detection.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Use a clear, close-up photo of the affected leaf.\n"
                  "Avoid blur and strong shadows.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 30),
                _buildButton(
                  icon: Icons.photo_camera_outlined,
                  text: "Take a picture",
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(height: 10),
                _buildButton(
                  icon: Icons.photo_library_outlined,
                  text: "Upload from gallery",
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
