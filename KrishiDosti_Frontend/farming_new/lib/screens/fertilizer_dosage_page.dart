import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

class FertilizerDosagePage extends StatefulWidget {
  const FertilizerDosagePage({super.key});

  @override
  State<FertilizerDosagePage> createState() => _FertilizerDosagePageState();
}

class _FertilizerDosagePageState extends State<FertilizerDosagePage> {
  final landCtrl = TextEditingController();

  String? selectedCrop;
  String? selectedSoil;

  double? neededN;
  double? neededP;
  double? neededK;

  // ------------------- NPK Values per Acre -------------------
  final npkCropValues = {
    "Rice": {"N": 60.0, "P": 40.0, "K": 40.0},
    "Wheat": {"N": 50.0, "P": 25.0, "K": 20.0},
    "Maize": {"N": 80.0, "P": 55.0, "K": 40.0},
    "Cotton": {"N": 70.0, "P": 30.0, "K": 40.0},
    "Sugarcane": {"N": 100.0, "P": 50.0, "K": 100.0},
    "Tomato": {"N": 60.0, "P": 40.0, "K": 40.0},
  };

  // ------------------- SOIL MULTIPLIER -------------------
  final soilEffect = {
    "Loamy": 1.0,
    "Sandy": 1.2,
    "Clay": 0.8,
    "Red Soil": 1.1,
    "Black Soil": 0.95,
    "Laterite Soil": 1.25,
    "Alluvial Soil": 1.0,
    "Mountain Soil": 1.15,
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
    if (selectedSoil == null) {
      showWarn("Select Soil Type", "Choose a soil type.");
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
    );
  }

  // ---------------- CALCULATE ----------------
  void calculate() {
    if (!validateInputs()) return;

    final land = double.tryParse(landCtrl.text) ?? 0;
    final crop = npkCropValues[selectedCrop]!;
    final soilMod = soilEffect[selectedSoil]!;

    setState(() {
      neededN = crop["N"]! * land * soilMod;
      neededP = crop["P"]! * land * soilMod;
      neededK = crop["K"]! * land * soilMod;
    });
  }

  // -----------------------------------------------------
  // UI LAYOUT
  // -----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Fertilizer Dosage Guide",
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
                          color: Colors.black26,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _inputField("Land Area (Acres)", landCtrl),
                        const SizedBox(height: 16),
                        _dropdown(
                          "Select Crop",
                          npkCropValues.keys.toList(),
                          selectedCrop,
                          (v) => setState(() => selectedCrop = v),
                        ),
                        const SizedBox(height: 16),
                        _dropdown(
                          "Select Soil Type",
                          soilEffect.keys.toList(),
                          selectedSoil,
                          (v) => setState(() => selectedSoil = v),
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
                              borderRadius: BorderRadius.circular(18),
                            ),
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

                  const SizedBox(height: 26),

                  if (neededN != null) _resultCard(),

                  const SizedBox(height: 26),

                  nutrientInfoCard(),

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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
  Widget _dropdown(
    String label,
    List<String> items,
    String? selected,
    Function(String?) onChanged,
  ) {
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
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ---------------- RESULT CARD ----------------
  Widget _resultCard() {
    return Container(
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
            "Recommended Dosage",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _resultTile("Nitrogen (N)", neededN!),
          _resultTile("Phosphorus (P)", neededP!),
          _resultTile("Potassium (K)", neededK!),
        ],
      ),
    );
  }

  Widget _resultTile(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        "$label : ${value.toStringAsFixed(1)} kg",
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.green,
        ),
      ),
    );
  }

  // ---------------- NUTRIENT INFO CARD ----------------
  Widget nutrientInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFF5FFF2), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 5),
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.eco_rounded, color: Colors.green, size: 26),
              SizedBox(width: 10),
              Text(
                "Nutrient Meaning",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          nutrientTile(
            label: "Nitrogen (N)",
            color: Colors.green,
            emoji: "🌿",
            meaning:
                "Supports leaf development & plant growth.\n• Helps plants stay green & grow faster.",
          ),
          const SizedBox(height: 14),
          nutrientTile(
            label: "Phosphorus (P)",
            color: Colors.blue,
            emoji: "🟦",
            meaning:
                "Essential for roots & flowering.\n• Promotes strong roots and healthy flowering.",
          ),
          const SizedBox(height: 14),
          nutrientTile(
            label: "Potassium (K)",
            color: Colors.orange,
            emoji: "🔥",
            meaning:
                "Boosts plant immunity & stress resistance.\n• Helps plants survive diseases & harsh weather.",
          ),
        ],
      ),
    );
  }

  // ---------------- NUTRIENT TILE ----------------
  Widget nutrientTile({
    required String label,
    required String emoji,
    required Color color,
    required String meaning,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.85),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color.darken(0.3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meaning,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- EXTENSION (DARKEN COLOR) ----------------
extension ColorDarken on Color {
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
