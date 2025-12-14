// lib/screens/home_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../services/weather_service.dart';
import 'choose_crop_page.dart';
import 'disease_scan_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WeatherService _weatherService = WeatherService();

  bool _loading = false;

  String? _temperature;
  String? _description;
  String? _error;

  // location
  String? _area;
  String? _district;
  String? _city;
  String? _state;
  String? _country;

  // extra weather
  double? _humidity;
  double? _windSpeed;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  // ---------------------- LOCATION ----------------------
  Future<Position?> _tryGetLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        print("Location service disabled");
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        print("Location permission denied");
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("GOT POSITION: ${pos.latitude}, ${pos.longitude}");
      return pos;
    } catch (e) {
      print("LOCATION ERROR: $e");
      return null;
    }
  }

  // ------------------ REVERSE GEOCODING ------------------
  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;

        print('--- Placemark ---');
        print('subLocality: ${pm.subLocality}');
        print('locality: ${pm.locality}');
        print('subAdministrativeArea: ${pm.subAdministrativeArea}');
        print('administrativeArea: ${pm.administrativeArea}');
        print('country: ${pm.country}');

        setState(() {
          _area = pm.subLocality ?? "";
          _city = pm.locality ?? "";

          // District: prefer subAdministrativeArea; fallback to city
          if (pm.subAdministrativeArea != null &&
              pm.subAdministrativeArea!.isNotEmpty) {
            _district = pm.subAdministrativeArea;
          } else {
            _district = _city;
          }

          _state = pm.administrativeArea ?? "";
          _country = pm.country ?? "";
        });

        print("State: $_state");
        print("District: $_district");
        print("City: $_city");
      }
    } catch (e) {
      print("Reverse geocode error: $e");
    }
  }

  // ------------------ NORMALIZE WEATHER JSON ------------------
  Map<String, dynamic> _normalizeWeatherJson(Map<String, dynamic> raw) {
    // Standard OpenWeather:
    // { "main": {...}, "weather": [...], "wind": {...}, ... }
    if (raw['main'] != null || raw['weather'] != null || raw['wind'] != null) {
      return raw;
    }

    // Some APIs: { "data": { "main": {...}, "weather": [...], "wind": {...} } }
    if (raw['data'] is Map<String, dynamic>) {
      final inner = raw['data'] as Map<String, dynamic>;
      if (inner['main'] != null ||
          inner['weather'] != null ||
          inner['wind'] != null) {
        return inner;
      }
    }

    print("⚠ Unexpected weather JSON shape: $raw");
    return raw;
  }

  // ------------------ FETCH WEATHER ------------------
  Future<void> _fetchWeather() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pos = await _tryGetLocation();

      double lat = pos?.latitude ?? 13.0827;
      double lon = pos?.longitude ?? 80.2707;

      await _reverseGeocode(lat, lon);

      // raw JSON from service
      final rawData = await _weatherService.fetchWeather(lat, lon);

      print("🌐 Raw weather JSON keys: ${rawData.keys}");

      final data = _normalizeWeatherJson(rawData);

      print("✅ Normalized weather JSON keys: ${data.keys}");
      print("   main: ${data['main']}");
      print("   weather: ${data['weather']}");
      print("   wind: ${data['wind']}");

      double? temp;
      double? humidity;
      String? desc;
      double? windSpeed;

      // ---- MAIN (temp + humidity) ----
      if (data['main'] is Map) {
        final main = data['main'] as Map<String, dynamic>;
        temp = (main['temp'] as num?)?.toDouble();
        humidity = (main['humidity'] as num?)?.toDouble();
      }

      // ---- WEATHER DESCRIPTION ----
      if (data['weather'] is List && (data['weather'] as List).isNotEmpty) {
        final first = (data['weather'] as List).first;
        if (first is Map) {
          desc = first['description']?.toString();
        }
      } else if (data['description'] != null) {
        desc = data['description'].toString();
      }

      // ---- WIND ----
      if (data['wind'] is Map) {
        final wind = data['wind'] as Map<String, dynamic>;
        windSpeed = (wind['speed'] as num?)?.toDouble();
      }

      print("TEMP: $temp, HUMIDITY: $humidity, DESC: $desc, WIND: $windSpeed");

      if (temp == null &&
          humidity == null &&
          desc == null &&
          windSpeed == null) {
        setState(() {
          _error = "Unexpected weather data format.";
        });
      }

      setState(() {
        _temperature = temp?.toStringAsFixed(1) ?? "--";
        _description = desc ?? "--";
        _humidity = humidity;
        _windSpeed = windSpeed;
      });
    } catch (e) {
      print("FETCH WEATHER ERROR: $e");
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _getWeatherIcon() {
    if (_description == null) return Icons.cloud_outlined;
    final d = _description!.toLowerCase();

    if (d.contains('sun') || d.contains('clear')) return Icons.wb_sunny_rounded;
    if (d.contains('cloud')) return Icons.cloud_rounded;
    if (d.contains('rain') || d.contains('drizzle')) return Icons.grain_rounded;
    if (d.contains('storm')) return Icons.thunderstorm_rounded;
    if (d.contains('mist') || d.contains('fog')) return Icons.water_drop;
    return Icons.cloud_outlined;
  }

  String _buildLocationText() {
    final parts = <String>[];
    if (_area?.isNotEmpty ?? false) parts.add(_area!);
    if (_city?.isNotEmpty ?? false) parts.add(_city!);
    if (_district?.isNotEmpty ?? false && _district != _city) {
      parts.add(_district!);
    }
    if (_state?.isNotEmpty ?? false) parts.add(_state!);
    if (_country?.isNotEmpty ?? false) parts.add(_country!);
    return parts.join(', ');
  }

  String _cap(String? text) {
    if (text == null || text.isEmpty) return "--";
    return text[0].toUpperCase() + text.substring(1);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return "Good Morning 👋";
    if (hour < 17) return "Good Afternoon 👋";
    if (hour < 21) return "Good Evening 👋";
    return "Good Night 🌙";
  }

  // ---------------------- UI ----------------------
  @override
  Widget build(BuildContext context) {
    final location = _buildLocationText();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- GREETING ----------
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Text("👨‍🌾", style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const Text(
                        "Farmer",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.search, size: 26)),
                  IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none_rounded,
                          size: 26)),
                ],
              ),

              const SizedBox(height: 18),

              // ---------- WEATHER CARD ----------
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC8E6C9), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (location.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined,
                                          size: 18),
                                      const SizedBox(width: 4),
                                      Expanded(
                                          child: Text(location,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w600))),
                                    ],
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  _loading
                                      ? "Fetching weather..."
                                      : _cap(_description),
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                              ]),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("${_temperature ?? '--'}°C",
                                style: const TextStyle(
                                    fontSize: 36, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: Icon(_getWeatherIcon(),
                                  size: 32, color: Colors.orange),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 18, color: Colors.red),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Unable to load weather. Check internet or API key.",
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          )
                        ],
                      ),
                    ] else
                      Row(
                        children: [
                          _InfoChip(
                              icon: Icons.air_rounded,
                              label: "Wind",
                              value: _windSpeed != null
                                  ? "${_windSpeed!.toStringAsFixed(1)} m/s"
                                  : "--"),
                          _InfoChip(
                              icon: Icons.water_drop_outlined,
                              label: "Humidity",
                              value: _humidity != null
                                  ? "${_humidity!.toStringAsFixed(0)}%"
                                  : "--"),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _fetchWeather,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18))),
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text("Use precise location",
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ------------------ CROP CARD ------------------
              const Text("Crop for your land",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () => Get.to(() => const ChooseCropPage()),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDFF8E6), Color(0xFFFFFFFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1FAA59),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.agriculture_rounded,
                            size: 34, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Step into crop prediction",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              "Let AI analyse your soil and suggest best crops.",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                  height: 1.3),
                            ),
                            const SizedBox(height: 10),
                            const Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _TagChip(label: "Soil nutrients"),
                                _TagChip(label: "Season wise"),
                                _TagChip(label: "Location aware"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ------------------ HEAL YOUR CROP ------------------
              const Text("Heal your crop",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _HealStep(
                            icon: Icons.photo_camera_outlined,
                            title: "Take\npicture"),
                        Icon(Icons.arrow_forward_ios,
                            size: 18, color: Colors.grey),
                        _HealStep(
                            icon: Icons.receipt_long_outlined,
                            title: "Diagnosis"),
                        Icon(Icons.arrow_forward_ios,
                            size: 18, color: Colors.grey),
                        _HealStep(
                            icon: Icons.medication_liquid_outlined,
                            title: "Get\nMedicine"),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Get.to(() => const DiseaseScanPage()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Take a picture",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    )
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

// ---------------------------------- COMPONENTS ----------------------------------

class _HealStep extends StatelessWidget {
  final IconData icon;
  final String title;
  const _HealStep({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Colors.green),
        const SizedBox(height: 4),
        Text(title,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.green[700]),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black54)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
