// lib/screens/profile_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_detail_page.dart'; // ⭐ NEW IMPORT

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Controllers
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final landCtrl = TextEditingController();

  String? soilType;
  String? cropType;

  // Location fields
  String area = "";
  String city = "";
  String district = "";

  // Soil types
  final List<String> soilList = [
    "Loamy",
    "Sandy",
    "Clay",
    "Red Soil",
    "Black Soil",
    "Laterite",
    "Alluvial",
    "Mountain Soil",
  ];

  // Crop types
  final List<String> cropList = [
    "Rice",
    "Wheat",
    "Maize",
    "Sugarcane",
    "Cotton",
    "Tomato",
    "Banana",
  ];

  // -------------------- VALIDATION --------------------
  bool validateInputs() {
    if (nameCtrl.text.trim().isEmpty) {
      showWarn("Name Required", "Please enter your full name");
      return false;
    }
    if (phoneCtrl.text.trim().isEmpty || phoneCtrl.text.length != 10) {
      showWarn("Invalid Phone Number", "Enter a valid 10-digit number");
      return false;
    }
    if (soilType == null) {
      showWarn("Soil Type Missing", "Please select your soil type");
      return false;
    }
    if (cropType == null) {
      showWarn("Crop Preference Missing", "Please choose your main crop");
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

  // -------------------- LOCATION FETCH --------------------
  Future<void> fetchLocation() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      showWarn("Location Disabled", "Enable your GPS to fetch address.");
      return;
    }

    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }

    if (p == LocationPermission.deniedForever ||
        p == LocationPermission.denied) {
      showWarn("Permission Denied", "Location permission required.");
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final placemarks =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);
    final place = placemarks.first;

    setState(() {
      area = place.subLocality ?? "";
      city = place.locality ?? "";
      district = place.subAdministrativeArea ?? "";
    });
  }

  // -------------------- SAVE PROFILE --------------------
  void saveProfile() async {
    if (!validateInputs()) return;

    try {
      String phone = phoneCtrl.text.trim();

      await FirebaseFirestore.instance.collection("users").doc(phone).set({
        "name": nameCtrl.text.trim(),
        "phone": phone,
        "email": emailCtrl.text.trim(),
        "land_size": landCtrl.text.trim(),
        "soil_type": soilType,
        "crop_type": cropType,
        "area": area,
        "city": city,
        "district": district,
        "updated_at": DateTime.now(),
      });

      Get.snackbar(
        "Profile Saved",
        "Your profile has been updated successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to save profile: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  // --------------------------------------------------------
  // UI STARTS HERE
  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // HEADER GRADIENT
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
                  const SizedBox(height: 20),
                  _profileAvatar(),
                  const SizedBox(height: 20),
                  _profileInputCard(),
                  const SizedBox(height: 30),
                  _saveButton(),
                  const SizedBox(height: 10),
                  _viewProfileButton(), // ⭐ ADDED BUTTON
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- PROFILE AVATAR ----------------
  Widget _profileAvatar() {
    return CircleAvatar(
      radius: 55,
      backgroundColor: Colors.white,
      child: const Icon(Icons.person, size: 60, color: Colors.grey),
    );
  }

  // ---------------- INPUT CARD ----------------
  Widget _profileInputCard() {
    return Container(
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
          _textField("Full Name", nameCtrl),
          const SizedBox(height: 16),
          _textField("Phone Number", phoneCtrl, type: TextInputType.phone),
          const SizedBox(height: 16),
          _textField("Email (Optional)", emailCtrl,
              type: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _locationTile(),
          const SizedBox(height: 16),
          _textField("Land Size (Acres)", landCtrl, type: TextInputType.number),
          const SizedBox(height: 16),
          _dropdown("Soil Type", soilList, soilType,
              (v) => setState(() => soilType = v)),
          const SizedBox(height: 16),
          _dropdown("Preferred Crop", cropList, cropType,
              (v) => setState(() => cropType = v)),
        ],
      ),
    );
  }

  // ---------------- LOCATION TILE ----------------
  Widget _locationTile() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  area.isEmpty ? "Tap GPS to fetch location" : area,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  city.isEmpty ? "" : "$city, $district",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: fetchLocation,
            icon: const Icon(Icons.my_location, color: Colors.green),
          ),
        ],
      ),
    );
  }

  // ---------------- TEXT FIELD ----------------
  Widget _textField(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: "Enter $label",
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButton<String>(
            value: selectedValue,
            isExpanded: true,
            hint: const Text("Select"),
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

  // ---------------- SAVE BUTTON ----------------
  Widget _saveButton() {
    return ElevatedButton(
      onPressed: saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: const Text(
        "Save Profile",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------------- VIEW PROFILE DETAILS BUTTON ----------------
  Widget _viewProfileButton() {
    return TextButton(
      onPressed: () {
        if (phoneCtrl.text.trim().isEmpty) {
          Get.snackbar("Phone Missing", "Enter phone number first",
              backgroundColor: Colors.orange, colorText: Colors.white);
          return;
        }

        Get.to(() => ProfileDetailPage(
              phone: phoneCtrl.text.trim(),
            ));
      },
      child: const Text(
        "View Profile Details",
        style: TextStyle(
          color: Colors.green,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
