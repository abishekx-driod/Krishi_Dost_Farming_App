import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

class ProfitCalculatorPage extends StatefulWidget {
  const ProfitCalculatorPage({super.key});

  @override
  State<ProfitCalculatorPage> createState() => _ProfitCalculatorPageState();
}

class _ProfitCalculatorPageState extends State<ProfitCalculatorPage> {
  final seedCtrl = TextEditingController();
  final fertCtrl = TextEditingController();
  final laborCtrl = TextEditingController();
  final otherCtrl = TextEditingController();
  final yieldCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  double? totalCost;
  double? totalRevenue;
  double? profit;

  // ---------------- VALIDATION ----------------
  bool validateInputs() {
    if (seedCtrl.text.trim().isEmpty) {
      showWarn("Seed Cost Required", "Enter the seed cost.");
      return false;
    }
    if (fertCtrl.text.trim().isEmpty) {
      showWarn("Fertilizer Cost Required", "Enter the fertilizer cost.");
      return false;
    }
    if (laborCtrl.text.trim().isEmpty) {
      showWarn("Labour Cost Required", "Enter labour cost.");
      return false;
    }
    if (otherCtrl.text.trim().isEmpty) {
      showWarn("Other Expenses Required", "Enter other expenses or 0.");
      return false;
    }
    if (yieldCtrl.text.trim().isEmpty) {
      showWarn("Expected Yield Missing", "Please enter expected yield (kg).");
      return false;
    }
    if (priceCtrl.text.trim().isEmpty) {
      showWarn("Market Price Missing", "Enter current market price per kg.");
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

    final s = double.tryParse(seedCtrl.text) ?? 0;
    final f = double.tryParse(fertCtrl.text) ?? 0;
    final l = double.tryParse(laborCtrl.text) ?? 0;
    final o = double.tryParse(otherCtrl.text) ?? 0;
    final y = double.tryParse(yieldCtrl.text) ?? 0;
    final p = double.tryParse(priceCtrl.text) ?? 0;

    final cost = s + f + l + o;
    final revenue = y * p;
    final pf = revenue - cost;

    setState(() {
      totalCost = cost;
      totalRevenue = revenue;
      profit = pf;
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Profit Calculator",
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // INPUT CARD
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
                        _input("Seed Cost (₹)", seedCtrl),
                        const SizedBox(height: 14),
                        _input("Fertilizer Cost (₹)", fertCtrl),
                        const SizedBox(height: 14),
                        _input("Labour Cost (₹)", laborCtrl),
                        const SizedBox(height: 14),
                        _input("Other Expenses (₹)", otherCtrl),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        _input("Expected Yield (kg)", yieldCtrl),
                        const SizedBox(height: 14),
                        _input("Market Price (₹ per kg)", priceCtrl),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: calculate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
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
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // RESULT CARD
                  if (profit != null)
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
                          Text(
                            "Total Cost: ₹${totalCost!.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Total Revenue: ₹${totalRevenue!.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Profit: ₹${profit!.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: profit! >= 0 ? Colors.green : Colors.red,
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

  // ---------------- TEXTFIELD ----------------
  Widget _input(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),

          // 🔥 Accept ONLY numbers & decimals
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
}
