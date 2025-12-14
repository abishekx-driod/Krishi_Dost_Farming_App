// lib/screens/soil_scan_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// For real camera/gallery, add image_picker in pubspec and import it here.
// import 'package:image_picker/image_picker.dart';

class SoilScanPage extends StatefulWidget {
  const SoilScanPage({super.key});

  @override
  State<SoilScanPage> createState() => _SoilScanPageState();
}

class _SoilScanPageState extends State<SoilScanPage> {
  String? _selectedImagePath;
  String? _predictedSoil;

  Future<void> _takePhoto() async {
    // TODO: integrate camera using image_picker or your own logic.
    // final picker = ImagePicker();
    // final file = await picker.pickImage(source: ImageSource.camera);
    // if (file == null) return;
    // setState(() => _selectedImagePath = file.path);
    //
    // final predicted = await yourModel.predict(file.path);

    // TEMP demo logic:
    setState(() {
      _selectedImagePath = 'camera_image.jpg';
      _predictedSoil = 'Red'; // <- replace with your model result
    });
  }

  Future<void> _uploadPhoto() async {
    // TODO: integrate gallery picker.
    // final picker = ImagePicker();
    // final file = await picker.pickImage(source: ImageSource.gallery);
    // if (file == null) return;
    // setState(() => _selectedImagePath = file.path);
    //
    // final predicted = await yourModel.predict(file.path);

    // TEMP demo logic:
    setState(() {
      _selectedImagePath = 'gallery_image.jpg';
      _predictedSoil = 'Alluvial'; // <- replace with your model result
    });
  }

  void _usePredictedSoil() {
    if (_predictedSoil == null || _predictedSoil!.isEmpty) {
      Get.snackbar(
        'No prediction',
        'Please take or upload a photo first',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    // Return soil name back to previous page
    Get.back(result: _predictedSoil);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan soil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Icon(
              Icons.landscape_outlined,
              size: 72,
              color: Colors.green[700],
            ),
            const SizedBox(height: 12),
            const Text(
              'Take a photo or upload a soil image.\n'
              'Your model will predict the soil type.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Buttons row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uploadPhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Preview + prediction
            if (_selectedImagePath != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prediction',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text('Image: $_selectedImagePath'),
                    const SizedBox(height: 4),
                    Text(
                      _predictedSoil != null
                          ? 'Soil type: $_predictedSoil'
                          : 'Running model...',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _usePredictedSoil,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Use this soil type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
