import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'soil_identification_page.dart';

import 'profit_calculator_page.dart';
import 'water_requirement_page.dart';
import 'seed_quantity_page.dart';
import 'fertilizer_dosage_page.dart';
import 'seasonal_crop_page.dart'; // ⭐ REQUIRED IMPORT

class ServicesPage extends StatelessWidget {
  final double temperature;
  final double humidity;
  final String description;

  const ServicesPage({
    super.key,
    double? temp,
    double? hum,
    String? desc,
  })  : temperature = temp ?? 30,
        humidity = hum ?? 60,
        description = desc ?? "clear";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Services",
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Header gradient
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
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _serviceCard(
                    title: "Predict Soil Type",
                    subtitle: "Click a photo to detect soil type.",
                    icon: Icons.camera_alt_rounded,
                    iconGradient: const [Color(0xFFD2B48C), Color(0xFFB08B5A)],
                    onTap: () {
                      Get.to(() => SoilIdentificationPage(crop: "Wheat"));
                    },
                  ),
                  const SizedBox(height: 18),
                  _serviceCard(
                    title: "Profit Calculator",
                    subtitle: "Calculate expected profit & revenue.",
                    icon: Icons.calculate_rounded,
                    iconGradient: const [Color(0xFF6EC3F5), Color(0xFF3A8DDA)],
                    onTap: () {
                      Get.to(() => const ProfitCalculatorPage());
                    },
                  ),
                  const SizedBox(height: 18),
                  _serviceCard(
                    title: "Water Requirement",
                    subtitle: "Daily irrigation suggestions.",
                    icon: Icons.water_drop_rounded,
                    iconGradient: const [Color(0xFF99E0FF), Color(0xFF4EBDF2)],
                    onTap: () {
                      Get.to(() => WaterRequirementPage(
                            temperature: temperature,
                            humidity: humidity,
                            description: description,
                          ));
                    },
                  ),
                  const SizedBox(height: 18),
                  _serviceCard(
                    title: "Seed Quantity Calculator",
                    subtitle: "Find seeds needed for your land.",
                    icon: Icons.grass_rounded,
                    iconGradient: const [Color(0xFFB6F08A), Color(0xFF67C65A)],
                    onTap: () {
                      Get.to(() => const SeedQuantityPage());
                    },
                  ),
                  const SizedBox(height: 18),
                  _serviceCard(
                    title: "Fertilizer Dosage Guide",
                    subtitle: "Correct NPK dosage for crops.",
                    icon: Icons.science_rounded,
                    iconGradient: const [Color(0xFFD8B7FF), Color(0xFF9C6BDF)],
                    onTap: () {
                      Get.to(() => const FertilizerDosagePage());
                    },
                  ),
                  const SizedBox(height: 18),
                  _serviceCard(
                    title: "Seasonal Crop Suitability",
                    subtitle: "Crops best suited for today's climate.",
                    icon: Icons.sunny_snowing,
                    iconGradient: const [Color(0xFFFFD59F), Color(0xFFF9A544)],
                    onTap: () {
                      Get.to(() => SeasonalCropPage(
                            temperature: temperature,
                            humidity: humidity,
                            description: description,
                          ));
                    },
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

  // ---------------------------------------------------------
  // SERVICE CARD WIDGET
  // ---------------------------------------------------------
  Widget _serviceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> iconGradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
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
        child: Row(
          children: [
            // ICON BOX
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: iconGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    color: iconGradient.last.withOpacity(0.45),
                  ),
                ],
              ),
              child: Icon(icon, size: 30, color: Colors.white),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87)),
                  const SizedBox(height: 6),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.3)),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios_rounded,
                size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
