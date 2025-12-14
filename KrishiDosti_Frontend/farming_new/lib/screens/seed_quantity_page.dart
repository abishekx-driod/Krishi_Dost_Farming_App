import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

class SeedQuantityPage extends StatefulWidget {
  const SeedQuantityPage({super.key});

  @override
  State<SeedQuantityPage> createState() => _SeedQuantityPageState();
}

class _SeedQuantityPageState extends State<SeedQuantityPage> {
  final landCtrl = TextEditingController();

  String? selectedCrop;
  double? seedRequiredKg;

  // Seed rate per acre (example values — you can edit later)
  final seedRate = {
    "Rice": 30.0,
    "Wheat": 50.0,
    "Maize": 20.0,
    "Groundnut": 15.0,
    "Cotton": 2.5,
    "Tomato": 0.25,
  };

  // ---------------- VALIDATION ----------------
  bool validateInputs() {
    if (landCtrl.text.trim().isEmpty) {
      showWarn("Land Area Required", "Enter land size in acres.");
      return false;
    }
    if (selectedCrop == null) {
      showWarn("Select Crop", "Choose a crop first.");
      return false;
    }
    return true;
  }

  void showWarn(String title, String msg) {
    Get.snackbar(
      title,
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );
  }

  // ---------------- CALCULATE ----------------
  void calculate() {
    if (!validateInputs()) return;

    final land = double.tryParse(landCtrl.text) ?? 0;
    final rate = seedRate[selectedCrop]!;

    final result = land * rate;

    setState(() {
      seedRequiredKg = result;
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Seed Quantity Calculator",
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 240,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF5EC78C),
                  Color(0xFF90E0A4),
                  Color(0xFFE3F6E8),
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
                  const SizedBox(height: 30),

                  // ---------------- INPUT CARD ----------------
                  Container(
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
                          blurRadius: 15,
                          offset: Offset(0, 6),
                          color: Colors.black12,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Land Size
                        _inputField("Land Size (in acres)", landCtrl),
                        const SizedBox(height: 16),

                        // Crop Dropdown
                        _dropdown(
                          "Select Crop",
                          seedRate.keys.toList(),
                          selectedCrop,
                          (v) => setState(() => selectedCrop = v),
                        ),

                        const SizedBox(height: 26),

                        ElevatedButton(
                          onPressed: calculate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 40),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          child: const Text(
                            "Calculate",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ---------------- RESULT CARD ----------------
                  if (seedRequiredKg != null)
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB8F5C0), Color(0xFFE8FFF0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 15,
                            offset: Offset(0, 6),
                            color: Colors.black12,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Seed Required",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "${seedRequiredKg!.toStringAsFixed(2)} Kg",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- INPUT FIELD ----------------
  Widget _inputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
          ],
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: "Enter value",
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- DROPDOWN ----------------
  Widget _dropdown(String label, List<String> items, String? selected,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButton<String>(
            value: selected,
            hint: const Text("Select"),
            isExpanded: true,
            underline: const SizedBox(),
            items: items
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
