import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../services/soil_api_service.dart';
import 'soil_details_page.dart';

class SoilIdentificationPage extends StatefulWidget {
  final String crop; // crop selected by user

  const SoilIdentificationPage({super.key, required this.crop});

  @override
  State<SoilIdentificationPage> createState() => _SoilIdentificationPageState();
}

class _SoilIdentificationPageState extends State<SoilIdentificationPage> {
  File? pickedImage;
  bool isLoading = false;
  String? predictedSoil;

  Future<void> pickImage() async {
    final imageFile = await ImagePicker().pickImage(source: ImageSource.camera);

    if (imageFile == null) return;

    setState(() {
      pickedImage = File(imageFile.path);
      predictedSoil = null;
    });

    await _predict(File(imageFile.path));
  }

  Future<void> _predict(File img) async {
    setState(() => isLoading = true);

    final soil = await SoilApiService.predictSoil(img);

    if (soil == null) {
      Get.snackbar("Error", "Failed to detect soil.",
          backgroundColor: Colors.red, colorText: Colors.white);
    } else {
      predictedSoil = soil;
    }

    setState(() => isLoading = false);
  }

  void _goNext() {
    if (predictedSoil == null) {
      Get.snackbar("No Soil", "Please capture a soil image first");
      return;
    }

    // Go to SoilDetailsPage with soil pre-filled
    Get.to(() => SoilDetailsPage(
          crop: widget.crop,
          detectedSoil: predictedSoil,
          detectedPh: "", // User will fill
          detectedMoisture: "", // User will fill
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Soil Identification"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImage,
        backgroundColor: Colors.green,
        child: const Icon(Icons.camera_alt_rounded),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pickedImage == null
                ? const Text(
                    "Tap the camera button to capture soil image",
                    style: TextStyle(fontSize: 16),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      pickedImage!,
                      height: 240,
                      fit: BoxFit.cover,
                    ),
                  ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : predictedSoil != null
                    ? Column(
                        children: [
                          const Text(
                            "Detected Soil Type:",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            predictedSoil!,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.green),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _goNext,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 40)),
                            child: const Text(
                              "Use this Soil",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
