// lib/screens/choose_crop_page.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import '../services/crop_predictor.dart';
import '../services/soil_api_service.dart';

class ChooseCropPage extends StatefulWidget {
  const ChooseCropPage({super.key});

  @override
  State<ChooseCropPage> createState() => _ChooseCropPageState();
}

class _ChooseCropPageState extends State<ChooseCropPage> {
  final _formKey = GlobalKey<FormState>();

  final CropPredictor cropPredictor = CropPredictor();
  final ImagePicker _picker = ImagePicker();

  // ML result
  String? predictedCrop;
  double? predictedProbability;

  // Market results
  List<Map<String, String>> marketPrices = [];
  Map<String, String>? bestMarket;

  // Detected user location
  String userState = "";
  String userDistrict = "";
  bool needManualLocation = false;

  // soil image prediction state
  bool _predictingSoil = false;
  File? _soilImageFile;

  // Section-level validation messages
  String? _nutrientError; // for N, P, K
  String? _weatherError; // for pH, temp, humidity, rainfall

  // Manual selection fields
  final List<String> indianStates = [
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
    "Andaman and Nicobar Islands",
    "Chandigarh",
    "Dadra and Nagar Haveli and Daman and Diu",
    "Delhi",
    "Jammu and Kashmir",
    "Ladakh",
    "Lakshadweep",
    "Puducherry"
  ];
  String? manualSelectedState;
  final TextEditingController manualDistrictController =
      TextEditingController();

  // UI form inputs for model
  final List<String> _soilTypes = [
    "Alluvial",
    "Red",
    "Laterite",
    "Black",
    "Sandy",
    "Mountain"
  ];
  final List<String> _seasons = ["Kharif", "Rabi", "Zaid"];

  // only for display in result card
  final List<String> _months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];

  String? _selectedSoil;
  String? _selectedSeason;

  final TextEditingController n = TextEditingController();
  final TextEditingController p = TextEditingController();
  final TextEditingController k = TextEditingController();
  final TextEditingController ph = TextEditingController();
  final TextEditingController temp = TextEditingController();
  final TextEditingController humidity = TextEditingController();
  final TextEditingController rainfall = TextEditingController();

  // ML→API crop name mapping
  final Map<String, String> apiCropMap = {
    "banana": "Banana",
    "barley": "Barley",
    "brinjal": "Brinjal",
    "cauliflower": "Cauliflower",
    "cotton": "Cotton",
    "ground_nuts": "Groundnut",
    "guava": "Guava",
    "jackfruit": "Jack Fruit",
    "maize": "Maize",
    "mango": "Mango",
    "millets": "Jowar",
    "oil_seeds": "Sunflower",
    "paddy": "Paddy",
    "potato": "Potato",
    "pulses": "Tur",
    "sugarcane": "Sugarcane",
    "tobacco": "Tobacco",
    "tomato": "Tomato",
    "wheat": "Wheat",
  };

  @override
  void initState() {
    super.initState();
    cropPredictor.load();
    _detectLocationHybrid();
  }

  @override
  void dispose() {
    n.dispose();
    p.dispose();
    k.dispose();
    ph.dispose();
    temp.dispose();
    humidity.dispose();
    rainfall.dispose();
    manualDistrictController.dispose();
    super.dispose();
  }

  // ---------- COMMON INPUT DECOR ----------
  InputDecoration inputBox(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB0BEC5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.green, width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFF7F9FB),
    );
  }

  // Same as above but hides the default error text under the field.
  InputDecoration inputBoxHideError(String label) {
    return inputBox(label).copyWith(
      errorStyle: const TextStyle(height: 0, fontSize: 0),
    );
  }

  int soilMatch(String? selected, String soil) => selected == soil ? 1 : 0;

  // ---------- RANGE VALIDATION ----------
  String? _validateRange({
    required String field,
    required String? value,
    required double min,
    required double max,
  }) {
    if (value == null || value.trim().isEmpty) {
      return "Enter $field";
    }
    final v = double.tryParse(value.trim());
    if (v == null) {
      return "Enter valid number for $field";
    }
    if (v < min || v > max) {
      return "$field should be between $min and $max";
    }
    return null;
  }

  // ---------- SECTION ERROR COMPUTE ----------
  void _recheckNutrientError() {
    final errors = [
      _validateRange(field: "Nitrogen (N)", value: n.text, min: 0, max: 200),
      _validateRange(field: "Phosphorus (P)", value: p.text, min: 0, max: 200),
      _validateRange(field: "Potassium (K)", value: k.text, min: 0, max: 200),
    ];
    final firstError = errors.firstWhere((e) => e != null, orElse: () => null);
    setState(() {
      _nutrientError = firstError;
    });
  }

  void _recheckWeatherError() {
    final errors = [
      _validateRange(field: "pH", value: ph.text, min: 3.5, max: 10),
      _validateRange(field: "Temperature", value: temp.text, min: 0, max: 60),
      _validateRange(field: "Humidity", value: humidity.text, min: 0, max: 100),
      _validateRange(field: "Rainfall", value: rainfall.text, min: 0, max: 500),
    ];
    final firstError = errors.firstWhere((e) => e != null, orElse: () => null);
    setState(() {
      _weatherError = firstError;
    });
  }

  // -----------------------------
  // Hybrid location detection
  // -----------------------------
  Future<void> _detectLocationHybrid() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        needManualLocation = true;
        setState(() {});
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low);

      List<Placemark> places =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (places.isNotEmpty) {
        Placemark pMark = places.first;

        String country = (pMark.country ?? "").trim();
        String state = (pMark.administrativeArea ?? "").trim();
        String district = (pMark.subAdministrativeArea ?? "").trim();
        String locality = (pMark.locality ?? "").trim();

        if (country.toLowerCase() == "india" || state.isNotEmpty) {
          userState = state;
          userDistrict = district.isNotEmpty ? district : locality;
          needManualLocation = false;
          setState(() {});
          return;
        } else {
          needManualLocation = true;
          setState(() {});
          return;
        }
      } else {
        needManualLocation = true;
        setState(() {});
        return;
      }
    } catch (e) {
      print("Location detection error: $e");
      needManualLocation = true;
      setState(() {});
    }
  }

  // -----------------------------
  // Market API with 3-level fallback
  // -----------------------------
  Future<List<Map<String, String>>> fetchMarketPriceWithFallback(
      String cropName,
      {String? district,
      String? state}) async {
    const apiKey = "579b464db66ec23bdd000001cdd3946e44ce4aad7209ff7b23ac571b";

    Future<List<Map<String, String>>> fetch(String extraFilter) async {
      final url =
          "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
          "?api-key=$apiKey&format=json&limit=200&filters[commodity]=$cropName$extraFilter";

      print("🔗 Market API URL: $url");

      try {
        final resp = await http.get(Uri.parse(url));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          if (data["records"] != null && data["records"].isNotEmpty) {
            List records = data["records"];
            return records.map<Map<String, String>>((item) {
              return {
                "market": (item["market"] ?? "").toString(),
                "district": (item["district"] ?? "").toString(),
                "state": (item["state"] ?? "").toString(),
                "price": (item["modal_price"] ?? "0").toString(),
              };
            }).toList();
          }
        } else {
          print("Market API responded ${resp.statusCode}");
        }
      } catch (e) {
        print("Market API error: $e");
      }
      return [];
    }

    // 1) district
    if (district != null && district.trim().isNotEmpty) {
      var res = await fetch(
          "&filters[district]=${Uri.encodeComponent(district.trim())}");
      if (res.isNotEmpty) return res;
    }

    // 2) state
    if (state != null && state.trim().isNotEmpty) {
      var res =
          await fetch("&filters[state]=${Uri.encodeComponent(state.trim())}");
      if (res.isNotEmpty) return res;
    }

    // 3) national fallback
    var res = await fetch("");
    res.sort((a, b) {
      int pa = int.tryParse(a["price"] ?? "") ?? 0;
      int pb = int.tryParse(b["price"] ?? "") ?? 0;
      return pb - pa;
    });
    return res.take(20).toList();
  }

  // -----------------------------
  // Submit => run model, fetch prices, compute best market
  // -----------------------------
  void _submit() async {
    // update section-level errors first
    _recheckNutrientError();
    _recheckWeatherError();

    // validate all fields (soil type, season, manual state/district etc.)
    if (!_formKey.currentState!.validate()) return;

    // block if any section still invalid
    if (_nutrientError != null || _weatherError != null) {
      Get.snackbar(
        "Invalid values",
        "Please correct the highlighted sections before predicting.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_selectedSoil == null) {
      Get.snackbar("Error", "Select soil type");
      return;
    }
    if (_selectedSeason == null) {
      Get.snackbar("Error", "Select season");
      return;
    }

    // Manual location
    String useState = userState;
    String useDistrict = userDistrict;
    if (needManualLocation) {
      if (manualSelectedState == null) {
        Get.snackbar("Error", "Select state (manual)");
        return;
      }
      if (manualDistrictController.text.trim().isEmpty) {
        Get.snackbar("Error", "Enter district (manual)");
        return;
      }
      useState = manualSelectedState!;
      useDistrict = manualDistrictController.text.trim();
    }

    // Auto month one-hot
    List<int> monthOH = List.filled(12, 0);
    int currentMonthIndex = DateTime.now().month - 1;
    if (currentMonthIndex >= 0 && currentMonthIndex < 12) {
      monthOH[currentMonthIndex] = 1;
    }

    // build model input vector (28 dims)
    List<double> inputs = [
      double.parse(n.text),
      double.parse(p.text),
      double.parse(k.text),
      double.parse(temp.text),
      double.parse(humidity.text),
      double.parse(ph.text),
      double.parse(rainfall.text),
      soilMatch(_selectedSoil, "Alluvial").toDouble(),
      soilMatch(_selectedSoil, "Red").toDouble(),
      soilMatch(_selectedSoil, "Laterite").toDouble(),
      soilMatch(_selectedSoil, "Black").toDouble(),
      soilMatch(_selectedSoil, "Sandy").toDouble(),
      soilMatch(_selectedSoil, "Mountain").toDouble(),
      _selectedSeason == "Kharif" ? 1 : 0,
      _selectedSeason == "Rabi" ? 1 : 0,
      _selectedSeason == "Zaid" ? 1 : 0,
      ...monthOH.map((e) => e.toDouble()),
    ];

    final result = cropPredictor.predictRaw(inputs);
    predictedCrop = result["crop"];
    predictedProbability = result["probability"];

    setState(() {
      marketPrices = [];
      bestMarket = null;
    });

    String apiCrop = apiCropMap[predictedCrop!] ?? predictedCrop!;
    List<Map<String, String>> prices = await fetchMarketPriceWithFallback(
      apiCrop,
      district: useDistrict,
      state: useState,
    );

    if (prices.isNotEmpty) {
      prices.sort((a, b) {
        int pa = int.tryParse(a["price"] ?? "") ?? 0;
        int pb = int.tryParse(b["price"] ?? "") ?? 0;
        return pb - pa;
      });
      bestMarket = prices.first;
    } else {
      bestMarket = null;
    }

    setState(() {
      marketPrices = prices;
    });
  }

  // ---------- STEPPER NUMBER FIELD (for N,P,K) ----------
  Widget _buildNumberFieldWithStepper({
    required String label,
    required String fieldName,
    required TextEditingController controller,
    double step = 1,
    double min = 0,
    double max = 500,
  }) {
    void changeValue(bool increase) {
      double current = double.tryParse(controller.text) ?? 0;
      current = increase ? current + step : current - step;
      if (current < min) current = min;
      if (current > max) current = max;
      controller.text = current.toStringAsFixed(0);

      setState(() {});
      _recheckNutrientError();
      _formKey.currentState?.validate();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB0BEC5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => changeValue(false),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 48,
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                errorStyle: TextStyle(height: 0, fontSize: 0), // hide text
              ),
              onChanged: (_) {
                _recheckNutrientError();
                _formKey.currentState?.validate();
              },
              validator: (v) => _validateRange(
                field: fieldName,
                value: v,
                min: min,
                max: max,
              ),
            ),
          ),
          IconButton(
            onPressed: () => changeValue(true),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  // ========== SOIL IMAGE PICK + PREDICTION SECTION ==========
  Future<void> _openSoilImageOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Text(
                  "Detect soil from photo",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text("Take a photo"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickSoilImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text("Choose from gallery"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickSoilImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickSoilImage(ImageSource source) async {
    try {
      final XFile? picked =
          await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;

      setState(() {
        _predictingSoil = true;
        _soilImageFile = File(picked.path);
      });

      final String? predictedSoil =
          await _predictSoilTypeFromImage(_soilImageFile!);

      // ------------------------------------
      // CASE 1: API returned NOTHING
      // ------------------------------------
      if (predictedSoil == null) {
        Get.snackbar(
          "Soil detection",
          "Could not detect soil type from image.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      String raw = predictedSoil.trim().toLowerCase();
      debugPrint("RAW SOIL FROM API: $raw");

      // ------------------------------------
      // CASE 2: INVALID IMAGE → do not assign
      // ------------------------------------
      if (raw.contains("invalid") ||
          raw.contains("not") ||
          raw.contains("no soil")) {
        setState(() => _selectedSoil = null);

        Get.snackbar(
          "Invalid Image",
          "No soil detected from this image.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // ------------------------------------
      // CLEAN RAW SOIL LABEL
      // ------------------------------------
      raw = raw
          .replaceAll("_soil", "")
          .replaceAll("soil", "")
          .replaceAll("  ", " ")
          .trim();

      String apiSoil = raw.replaceAll(" ", "_");

      // ------------------------------------
      // SUPPORTED SOILS
      // ------------------------------------
      const allowedMap = {
        "alluvial": "Alluvial",
        "red": "Red",
        "laterite": "Laterite",
        "black": "Black",
        "sandy": "Sandy",
        "mountain": "Mountain",
      };

      // ALIASES
      const aliasMap = {
        "yellow": "Red",
        "yellow_soil": "Red",
        "clay": "Alluvial",
        "loam": "Alluvial",
        "arid": "Sandy",
      };

      String? mappedSoil;

      if (allowedMap.containsKey(apiSoil)) {
        mappedSoil = allowedMap[apiSoil];
      } else if (aliasMap.containsKey(apiSoil)) {
        mappedSoil = aliasMap[apiSoil];
      } else {
        // UNKNOWN SOIL
        Get.snackbar(
          "Unknown Soil",
          "Detected soil \"$predictedSoil\" is not supported.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // ------------------------------------
      // UPDATE UI SAFELY
      // ------------------------------------
      setState(() {
        _selectedSoil = mappedSoil;
      });

      Get.snackbar(
        "Soil detected",
        "Predicted soil type: $mappedSoil",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint("Soil image error: $e");
      Get.snackbar(
        "Error",
        "Failed to process soil image",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _predictingSoil = false);
      }
    }
  }

  Future<String?> _predictSoilTypeFromImage(File imageFile) async {
    try {
      final result = await SoilApiService.predictSoil(imageFile);

      if (result == "Error") return null;

      return result; // e.g. "Black_Soil", "yellow_soil", "Invalid Image — No Soil Detected"
    } catch (e) {
      debugPrint("Soil API error: $e");
      return null;
    }
  }

  // -----------------------------
  // UI builder
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text("Crop Prediction"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              // -------- First card: soil + season --------
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Field basics",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),

                    // Row: Soil dropdown + camera icon
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField(
                            decoration: inputBox("Soil Type"),
                            initialValue: _selectedSoil,
                            items: _soilTypes
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedSoil = v as String?),
                            validator: (v) =>
                                v == null ? "Select soil type" : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _predictingSoil ? null : _openSoilImageOptions,
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _predictingSoil
                                  ? Colors.grey.shade300
                                  : Colors.green.withOpacity(0.1),
                            ),
                            child: _predictingSoil
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.green,
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    DropdownButtonFormField(
                      decoration: inputBox("Season"),
                      initialValue: _selectedSeason,
                      items: _seasons
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedSeason = v as String?),
                      validator: (v) => v == null ? "Select season" : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // -------- Second card: N, P, K with steppers + other soil params --------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_nutrientError != null) // warning ABOVE container
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                      child: Text(
                        _nutrientError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Soil nutrients",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Allowed range: 0 – 200 (kg/ha) each for N, P, K.",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        _buildNumberFieldWithStepper(
                          label: "Nitrogen (N)",
                          fieldName: "Nitrogen (N)",
                          controller: n,
                          min: 0,
                          max: 200,
                        ),
                        _buildNumberFieldWithStepper(
                          label: "Phosphorus (P)",
                          fieldName: "Phosphorus (P)",
                          controller: p,
                          min: 0,
                          max: 200,
                        ),
                        _buildNumberFieldWithStepper(
                          label: "Potassium (K)",
                          fieldName: "Potassium (K)",
                          controller: k,
                          min: 0,
                          max: 200,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // -------- Soil & weather container with group error --------
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_weatherError != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                      child: Text(
                        _weatherError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Soil & weather",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Ranges:  pH 3.5–10  •  Temp 0–60°C  •  Humidity 0–100%  •  Rainfall 0–500 mm",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: ph,
                          decoration: inputBoxHideError("pH"),
                          keyboardType: TextInputType.number,
                          onChanged: (_) {
                            _recheckWeatherError();
                            _formKey.currentState?.validate();
                          },
                          validator: (v) => _validateRange(
                            field: "pH",
                            value: v,
                            min: 3.5,
                            max: 10,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: temp,
                          decoration: inputBoxHideError("Temperature (°C)"),
                          keyboardType: TextInputType.number,
                          onChanged: (_) {
                            _recheckWeatherError();
                            _formKey.currentState?.validate();
                          },
                          validator: (v) => _validateRange(
                            field: "Temperature",
                            value: v,
                            min: 0,
                            max: 60,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: humidity,
                          decoration: inputBoxHideError("Humidity (%)"),
                          keyboardType: TextInputType.number,
                          onChanged: (_) {
                            _recheckWeatherError();
                            _formKey.currentState?.validate();
                          },
                          validator: (v) => _validateRange(
                            field: "Humidity",
                            value: v,
                            min: 0,
                            max: 100,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: rainfall,
                          decoration: inputBoxHideError("Rainfall (mm)"),
                          keyboardType: TextInputType.number,
                          onChanged: (_) {
                            _recheckWeatherError();
                            _formKey.currentState?.validate();
                          },
                          validator: (v) => _validateRange(
                            field: "Rainfall",
                            value: v,
                            min: 0,
                            max: 500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // -------- Predict button --------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    "Predict Crop",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (predictedCrop != null) _resultCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------- RESULT CARD -----------------
  Widget _resultCard() {
    final currentMonthName =
        _months[DateTime.now().month - 1]; // for display only

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(top: 10),
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
          const Text(
            "Crop Suggested",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Crop: $predictedCrop",
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            "Probability: ${(predictedProbability! * 100).toStringAsFixed(2)}%",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            "Month considered: $currentMonthName",
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          const Text(
            "Best Market Near You",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (bestMarket == null)
            const Text(
              "Fetching or no market data found for your area.",
              style: TextStyle(fontSize: 15),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bestMarket!['market'] ?? "",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${bestMarket!['district']}, ${bestMarket!['state']}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Highest Price: ₹ ${bestMarket!['price']} / Quintal",
                    style: const TextStyle(fontSize: 16, color: Colors.green),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          const Text(
            "All Market Prices",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (marketPrices.isEmpty)
            const Text("Fetching prices...", style: TextStyle(fontSize: 15))
          else
            Column(
              children: marketPrices.map((e) {
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e["market"] ?? "",
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "${e["district"]}, ${e["state"]}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "₹ ${e["price"]}",
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
