import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../services/weather_service.dart';

class WaterRequirementPage extends StatefulWidget {
  final double temperature;
  final double humidity;
  final String description;

  const WaterRequirementPage({
    super.key,
    required this.temperature,
    required this.humidity,
    required this.description,
  });

  @override
  State<WaterRequirementPage> createState() => _WaterRequirementPageState();
}

class _WaterRequirementPageState extends State<WaterRequirementPage> {
  final landCtrl = TextEditingController();

  String? selectedCrop;
  String? selectedSoil;

  double? totalWater;

  // Weather (live)
  double liveTemp = 30;
  double liveHumidity = 60;
  String liveDesc = "clear";

  // Location info
  String area = "";
  String city = "";
  String district = "";

  bool locationFetched = false;

  final weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    liveTemp = widget.temperature;
    liveHumidity = widget.humidity;
    liveDesc = widget.description;
  }

  // ---------------- LOCATION ----------------
  Future<Position?> getLocation() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      Get.snackbar(
        "Location Disabled",
        "Enable GPS from settings.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return null;
    }

    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.denied ||
        p == LocationPermission.deniedForever) {
      Get.snackbar(
        "Permission Denied",
        "Location permission is needed.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ---------------- REVERSE GEO ----------------
  Future<void> reverseGeocode(double lat, double lon) async {
    try {
      final marks = await placemarkFromCoordinates(lat, lon);
      if (marks.isNotEmpty) {
        final p = marks.first;
        setState(() {
          area = p.subLocality ?? "";
          city = p.locality ?? "";
          district = p.subAdministrativeArea ?? "";
        });
      }
    } catch (e) {
      print("Reverse geocode error: $e");
    }
  }

  // ---------------- FETCH LIVE WEATHER ----------------
  Future<void> useCurrentLocation() async {
    final pos = await getLocation();
    if (pos == null) return;

    final data = await weatherService.fetchWeather(pos.latitude, pos.longitude);

    try {
      final main = data["main"];
      final weather = data["weather"][0];

      setState(() {
        liveTemp = (main["temp"] ?? 30).toDouble();
        liveHumidity = (main["humidity"] ?? 60).toDouble();
        liveDesc = weather["description"] ?? "clear";
        locationFetched = true;
      });
    } catch (e) {
      print("Weather parse error: $e");
    }

    await reverseGeocode(pos.latitude, pos.longitude);
  }

  // ---------------- WEATHER CATEGORY ----------------
  String getWeatherCategory() {
    final d = liveDesc.toLowerCase();
    if (d.contains("rain")) return "Rainy";
    if (liveTemp >= 32) return "Hot";
    return "Normal";
  }

  // ---------------- FACTORS ----------------
  final cropFactor = {
    "Rice": 1.5,
    "Wheat": 1.0,
    "Maize": 0.9,
    "Sugarcane": 2.0,
    "Cotton": 1.2,
    "Tomato": 1.1,
  };

  final soilFactor = {
    "Loamy": 1.0,
    "Sandy": 1.3,
    "Clay": 0.8,
    "Red Soil": 1.1,
    "Black Soil": 0.95,
    "Laterite Soil": 1.25,
    "Alluvial Soil": 1.0,
    "Mountain Soil": 1.15,
  };

  final weatherFactor = {
    "Hot": 1.3,
    "Normal": 1.0,
    "Rainy": 0.7,
  };

  // ---------------- CALCULATE ----------------
  void calculateWater() {
    if (!locationFetched) {
      Get.snackbar(
        "Location Required",
        "Tap the GPS icon to fetch weather first.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (landCtrl.text.trim().isEmpty) {
      Get.snackbar("Land Size Missing", "Enter land size.",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final land = double.tryParse(landCtrl.text.trim());
    if (land == null || land <= 0) {
      Get.snackbar("Invalid Value", "Enter valid land size.",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (selectedCrop == null) {
      Get.snackbar("Crop Missing", "Select crop.",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (selectedSoil == null) {
      Get.snackbar("Soil Missing", "Select soil type.",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final water = cropFactor[selectedCrop]! *
        soilFactor[selectedSoil]! *
        weatherFactor[getWeatherCategory()]! *
        land *
        1000;

    setState(() => totalWater = water);
  }

  // --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Water Requirement",
          style: TextStyle(
              color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // gradient header
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
                  _inputCard(),
                  const SizedBox(height: 26),
                  if (totalWater != null) _resultCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- UI COMPONENTS ----------------

  Widget _inputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF7ED), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              blurRadius: 15, offset: Offset(0, 6), color: Colors.black12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _locationWeatherBox(),
          const SizedBox(height: 20),
          _inputField("Land Size (in acres)", landCtrl),
          const SizedBox(height: 16),
          _dropdown(
            "Crop Type",
            cropFactor.keys.toList(),
            selectedCrop,
            (v) => setState(() => selectedCrop = v),
          ),
          const SizedBox(height: 16),
          _dropdown(
            "Soil Type",
            soilFactor.keys.toList(),
            selectedSoil,
            (v) => setState(() => selectedSoil = v),
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              onPressed: calculateWater,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text(
                "Calculate",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationWeatherBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_rounded, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (area.isNotEmpty)
                  Text(area,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                if (city.isNotEmpty || district.isNotEmpty)
                  Text("$city, $district",
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                Text(
                  "Weather: ${getWeatherCategory()} • ${liveTemp.toStringAsFixed(1)}°C",
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.green),
            onPressed: useCurrentLocation,
          ),
        ],
      ),
    );
  }

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
        boxShadow: [
          BoxShadow(
              blurRadius: 15, offset: Offset(0, 6), color: Colors.black12),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Water Required Today",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            "${totalWater!.toStringAsFixed(0)} Liters",
            style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 8),
          Text(
            "Based on today's weather conditions.",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

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
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: "Enter value",
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _dropdown(String label, List<String> items, String? selectedValue,
      void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: DropdownButton<String>(
            value: selectedValue,
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
}
