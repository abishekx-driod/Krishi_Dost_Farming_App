import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ProfileDetailPage extends StatefulWidget {
  final String phone; // Document ID

  const ProfileDetailPage({super.key, required this.phone});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.phone)
          .get();

      if (doc.exists) {
        setState(() {
          profileData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar(
        "Error",
        "Unable to load profile: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(
              color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold),
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
                  Color(0xFFE3F6E8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          isLoading
              ? const Center(child: CircularProgressIndicator())
              : profileData == null
                  ? const Center(
                      child: Text("No Profile Found",
                          style: TextStyle(fontSize: 18)))
                  : SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _profileImage(),
                            const SizedBox(height: 20),
                            _profileCard(),
                          ],
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  // ---------------- PROFILE IMAGE ----------------
  Widget _profileImage() {
    return CircleAvatar(
      radius: 55,
      backgroundColor: Colors.white,
      child: const Icon(Icons.person, size: 65, color: Colors.grey),
    );
  }

  // ---------------- PROFILE DATA CARD ----------------
  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 18),
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
          _item("Full Name", profileData?["name"]),
          _item("Phone Number", profileData?["phone"]),
          _item("Email", profileData?["email"] ?? "Not Provided"),
          _item(
              "Land Size (Acres)", profileData?["land_size"] ?? "Not Provided"),
          _item("Soil Type", profileData?["soil_type"]),
          _item("Preferred Crop", profileData?["crop_type"]),
          _item("Area", profileData?["area"]),
          _item("City", profileData?["city"]),
          _item("District", profileData?["district"]),
        ],
      ),
    );
  }

  // ---------------- ROW ITEM ----------------
  Widget _item(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ",
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          Expanded(
            child: Text(
              value ?? "Not Provided",
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
