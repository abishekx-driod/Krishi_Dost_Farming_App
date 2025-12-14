// lib/screens/choose_crop_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/crop_predictor.dart';
import '../services/weather_service.dart';

class ChooseCropPage extends StatefulWidget {
  const ChooseCropPage({super.key});

  @override
  State<ChooseCropPage> createState() => _ChooseCropPageState();
}

class _ChooseCropPageState extends State<ChooseCropPage> {
  final _formKey = GlobalKey<FormState>();

  final CropPredictor cropPredictor = CropPredictor();
  final WeatherService weatherService = WeatherService();

  String? predictedCrop;
  double? predictedProbability;

  // Market price list
  List<Map<String, String>> priceList = [];

  // Best market near user
  Map<String, String>? bestMarket;

  // From weather
  String userState = "";
  String userDistrict = "";

  // ML crop → API crop name mapping
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
    _loadUserLocation();
  }

  // ----------------------------------------------------------------------
  // 1️⃣ Load user location from weather service
  // ----------------------------------------------------------------------
  Future<void> _loadUserLocation() async {
    try {
      // Example coordinates for testing
      final weather = await weatherService.fetchWeather(23.7957, 86.4304);

      userState = weather["state"];
      userDistrict = weather["district"];

      print("🌍 User State = $userState");
      print("🌍 User District = $userDistrict");

      setState(() {});
    } catch (e) {
      print("❌ Error loading location: $e");
    }
  }

  // ----------------------------------------------------------------------
  // 2️⃣ SAFE Market Price API Function (NO CRASH)
  // ----------------------------------------------------------------------
  Future<List<Map<String, String>>> fetchMarketPrice(String cropName) async {
    String apiKey = "579b464db66ec23bdd000001cdd3946e44ce4aad7209ff7b23ac571b";

    final url =
        "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070"
        "?api-key=$apiKey&format=json&limit=100&filters[commodity]=$cropName";

    print("🔗 Market API URL: $url");

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["records"] != null && data["records"].isNotEmpty) {
          List records = data["records"];

          // 🔥 SAFE converter (NEVER crashes)
          return records.map<Map<String, String>>((item) {
            return {
              "market": item["market"].toString(),
              "district": item["district"].toString(),
              "state": item["state"].toString(),
              "price": item["modal_price"].toString(),
            };
          }).toList();
        }
      }
    } catch (e) {
      print("❌ Market API failed: $e");
    }

    return [];
  }

  // ----------------------------------------------------------------------
  // 3️⃣ UI Inputs
  // ----------------------------------------------------------------------

  final List<String> _soilTypes = [
    "Alluvial",
    "Red",
    "Laterite",
    "Black",
    "Sandy",
    "Mountain",
  ];

  final List<String> _seasons = ["Kharif", "Rabi", "Zaid"];

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
    "December",
  ];

  String? _selectedSoil;
  String? _selectedSeason;
  String? _selectedMonth;

  final TextEditingController n = TextEditingController();
  final TextEditingController p = TextEditingController();
  final TextEditingController k = TextEditingController();
  final TextEditingController ph = TextEditingController();
  final TextEditingController temp = TextEditingController();
  final TextEditingController humidity = TextEditingController();
  final TextEditingController rainfall = TextEditingController();

  @override
  void dispose() {
    n.dispose();
    p.dispose();
    k.dispose();
    ph.dispose();
    temp.dispose();
    humidity.dispose();
    rainfall.dispose();
    super.dispose();
  }

  int soilMatch(String? selected, String soil) => selected == soil ? 1 : 0;

  InputDecoration inputBox(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      fillColor: Colors.grey[100],
      filled: true,
    );
  }

  // ----------------------------------------------------------------------
  // 4️⃣ Predict crop + fetch price + pick best market
  // ----------------------------------------------------------------------
  void _submit() async {
    if (_selectedSoil == null || _selectedSeason == null) {
      Get.snackbar("Error", "Please select soil and season");
      return;
    }

    // Month one-hot
    List<int> month = List.filled(12, 0);
    if (_selectedMonth != null) {
      int idx = _months.indexOf(_selectedMonth!);
      month[idx] = 1;
    }

    // ML Input Vector
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
      ...month.map((e) => e.toDouble())
    ];

    // ML Prediction
    final result = cropPredictor.predictRaw(inputs);
    predictedCrop = result["crop"];
    predictedProbability = result["probability"];

    // Clear old data
    setState(() {
      priceList = [];
      bestMarket = null;
    });

    // Correct crop name for API
    String apiCrop = apiCropMap[predictedCrop!] ?? predictedCrop!;

    // Fetch prices
    List<Map<String, String>> results = await fetchMarketPrice(apiCrop);

    // Filter by user's state
    List<Map<String, String>> sameState = results
        .where(
            (item) => item["state"]!.toLowerCase() == userState.toLowerCase())
        .toList();

    // Highest price market
    if (sameState.isNotEmpty) {
      sameState.sort((a, b) => int.parse(b["price"]!) - int.parse(a["price"]!));
      bestMarket = sameState.first;
    }

    setState(() {
      priceList = results;
    });
  }

  // ----------------------------------------------------------------------
  // 5️⃣ UI
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crop Prediction"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField(
                decoration: inputBox("Soil Type"),
                items: _soilTypes
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSoil = v as String?),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField(
                decoration: inputBox("Season"),
                items: _seasons
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedSeason = v as String?),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField(
                decoration: inputBox("Month (optional)"),
                items: _months
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMonth = v as String?),
              ),
              const SizedBox(height: 15),
              TextFormField(
                  controller: n, decoration: inputBox("Nitrogen (N)")),
              const SizedBox(height: 15),
              TextFormField(
                  controller: p, decoration: inputBox("Phosphorus (P)")),
              const SizedBox(height: 15),
              TextFormField(
                  controller: k, decoration: inputBox("Potassium (K)")),
              const SizedBox(height: 15),
              TextFormField(controller: ph, decoration: inputBox("pH")),
              const SizedBox(height: 15),
              TextFormField(
                  controller: temp, decoration: inputBox("Temperature")),
              const SizedBox(height: 15),
              TextFormField(
                  controller: humidity, decoration: inputBox("Humidity")),
              const SizedBox(height: 15),
              TextFormField(
                  controller: rainfall, decoration: inputBox("Rainfall")),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 40),
                  ),
                  child: const Text("Predict Crop",
                      style: TextStyle(fontSize: 17)),
                ),
              ),
              const SizedBox(height: 30),
              if (predictedCrop != null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Crop Suggested",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),

                      Text("Crop: $predictedCrop",
                          style: const TextStyle(fontSize: 18)),
                      Text(
                        "Probability: ${(predictedProbability! * 100).toStringAsFixed(2)}%",
                        style: const TextStyle(fontSize: 18),
                      ),

                      const SizedBox(height: 20),

                      // ⭐ BEST MARKET CARD
                      if (bestMarket != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Best Market Near You ($userState)",
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text("Market: ${bestMarket!['market']}"),
                              Text("District: ${bestMarket!['district']}"),
                              const SizedBox(height: 4),
                              Text(
                                "Highest Price: ₹ ${bestMarket!['price']} / Quintal",
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      const Text("All Market Prices",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),

                      priceList.isEmpty
                          ? const Text("Fetching prices...")
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: priceList.length,
                              itemBuilder: (context, index) {
                                final item = priceList[index];
                                return Card(
                                  elevation: 3,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Market: ${item['market']}",
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                        Text("District: ${item['district']}"),
                                        Text("State: ${item['state']}"),
                                        const SizedBox(height: 5),
                                        Text(
                                          "Price: ₹ ${item['price']} / Quintal",
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.green),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
