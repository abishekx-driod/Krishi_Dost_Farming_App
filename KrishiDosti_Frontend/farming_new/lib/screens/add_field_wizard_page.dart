import 'package:flutter/material.dart';

/// Farmer-friendly multi-step Add Field flow.
/// No complex forms, mostly big buttons & simple choices.
class AddFieldWizardPage extends StatefulWidget {
  const AddFieldWizardPage({super.key});

  @override
  State<AddFieldWizardPage> createState() => _AddFieldWizardPageState();
}

class _AddFieldWizardPageState extends State<AddFieldWizardPage> {
  int _step = 0;

  // Collected values
  String? _selectedCrop;
  String? _sizeCategory; // "small" | "medium" | "large"
  double? _exactArea; // optional

  String? _sowingTimeCategory; // "this_week" | "15_30_days" | "1_2_months"
  DateTime? _sowingDate; // optional

  String? _irrigationLevel; // "none" | "sometimes" | "regular"

  String? _locationMode; // "gps" | "village"
  String? _villageName; // simple text for now

  // This would be a file path / XFile in a real app
  bool _photoAdded = false;

  final _villageController = TextEditingController();
  final _areaController = TextEditingController();

  @override
  void dispose() {
    _villageController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  // -------------------- STEP NAVIGATION --------------------

  void _goNext() {
    if (_step < 5) {
      setState(() => _step++);
    } else {
      _onFinish();
    }
  }

  void _goBack() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  bool _canGoNext() {
    switch (_step) {
      case 0:
        return _selectedCrop != null;
      case 1:
        // size category required, exact area optional
        return _sizeCategory != null;
      case 2:
        return _sowingTimeCategory != null || _sowingDate != null;
      case 3:
        return _irrigationLevel != null;
      case 4:
        if (_locationMode == "village") {
          return _villageName != null && _villageName!.trim().isNotEmpty;
        }
        if (_locationMode == "gps") {
          // for now we assume GPS always works; later you can validate
          return true;
        }
        return false;
      case 5:
        // Photo optional, can always finish
        return true;
      default:
        return false;
    }
  }

  // -------------------- FINISH HANDLER --------------------

  void _onFinish() {
    // Here you can integrate with your FieldService / Firestore.
    // For now we just pop with a result map.
    final result = {
      "crop": _selectedCrop,
      "sizeCategory": _sizeCategory,
      "exactArea": _exactArea,
      "sowingTimeCategory": _sowingTimeCategory,
      "sowingDate": _sowingDate?.toIso8601String(),
      "irrigationLevel": _irrigationLevel,
      "locationMode": _locationMode,
      "villageName": _villageName,
      "photoAdded": _photoAdded,
    };

    Navigator.pop(context, result);
  }

  // -------------------- BUILD --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        title: const Text(
          "Add Field",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildStepIndicator(),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildStepContent(),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // -------------------- STEP INDICATOR --------------------

  Widget _buildStepIndicator() {
    const labels = [
      "Crop",
      "Area",
      "Sowing",
      "Water",
      "Location",
      "Photo",
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isActive = index == _step;
          final isDone = index < _step;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index <= _step
                              ? Colors.green
                              : Colors.grey.shade300,
                        ),
                      ),
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone || isActive
                            ? Colors.green
                            : Colors.grey.shade300,
                      ),
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDone || isActive
                              ? Colors.white
                              : Colors.black54,
                        ),
                      ),
                    ),
                    if (index < labels.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < _step
                              ? Colors.green
                              : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? Colors.black : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // -------------------- STEP CONTENT --------------------

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildCropStep();
      case 1:
        return _buildAreaStep();
      case 2:
        return _buildSowingStep();
      case 3:
        return _buildWaterStep();
      case 4:
        return _buildLocationStep();
      case 5:
        return _buildPhotoStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 0: CROP SELECTION
  Widget _buildCropStep() {
    final crops = [
      {"label": "Wheat", "icon": Icons.grain},
      {"label": "Paddy", "icon": Icons.rice_bowl},
      {"label": "Maize", "icon": Icons.spa},
      {"label": "Vegetables", "icon": Icons.local_florist},
      {"label": "Potato", "icon": Icons.agriculture},
      {"label": "Sugarcane", "icon": Icons.grass},
    ];

    return Column(
      key: const ValueKey("crop_step"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          "Which crop is growing here?",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Tap on a crop below.",
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            itemCount: crops.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3 / 2,
            ),
            itemBuilder: (_, index) {
              final crop = crops[index];
              final label = crop["label"] as String;
              final icon = crop["icon"] as IconData;
              final isSelected = _selectedCrop == label;

              return InkWell(
                onTap: () {
                  setState(() => _selectedCrop = label);
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: isSelected ? Colors.green.shade600 : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 30,
                        color:
                            isSelected ? Colors.white : Colors.green.shade700,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // STEP 1: AREA SELECTION
  Widget _buildAreaStep() {
    return Column(
      key: const ValueKey("area_step"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          "How big is your field?",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Choose approximate size. Exact area is optional.",
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _areaChoice("Small", "small", "< 1 acre"),
            const SizedBox(width: 10),
            _areaChoice("Medium", "medium", "1–3 acre"),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _areaChoice("Large", "large", "> 3 acre"),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          "Exact area (optional)",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _areaController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: "e.g. 2.5",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  setState(() => _exactArea = parsed);
                },
              ),
            ),
            const SizedBox(width: 8),
            const Text("acre"),
          ],
        ),
      ],
    );
  }

  Widget _areaChoice(String title, String value, String subtitle) {
    final isSelected = _sizeCategory == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _sizeCategory = value);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected ? Colors.green.shade600 : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 2: SOWING TIME
  Widget _buildSowingStep() {
    return Column(
      key: const ValueKey("sowing_step"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          "When did you plant the crop?",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Choose roughly. Exact date is optional.",
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        _sowingChoice(
          label: "This week",
          value: "this_week",
        ),
        const SizedBox(height: 8),
        _sowingChoice(
          label: "15–30 days ago",
          value: "15_30_days",
        ),
        const SizedBox(height: 8),
        _sowingChoice(
          label: "1–2 months ago",
          value: "1_2_months",
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: now,
              firstDate: DateTime(now.year - 1),
              lastDate: now,
            );
            if (picked != null) {
              setState(() {
                _sowingDate = picked;
                _sowingTimeCategory = null; // override category
              });
            }
          },
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(
            _sowingDate == null
                ? "Pick exact date (optional)"
                : "Sowing date: ${_sowingDate!.day}/${_sowingDate!.month}/${_sowingDate!.year}",
          ),
        ),
      ],
    );
  }

  Widget _sowingChoice({required String label, required String value}) {
    final isSelected = _sowingTimeCategory == value;
    return InkWell(
      onTap: () {
        setState(() {
          _sowingTimeCategory = value;
          _sowingDate = null; // override date
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // STEP 3: WATER / IRRIGATION
  Widget _buildWaterStep() {
    return Column(
      key: const ValueKey("water_step"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          "Do you get water easily?",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Choose one option.",
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        _waterChoice(
          label: "No irrigation",
          value: "none",
          icon: Icons.do_disturb_alt,
        ),
        const SizedBox(height: 10),
        _waterChoice(
          label: "Sometimes water available",
          value: "sometimes",
          icon: Icons.water_drop,
        ),
        const SizedBox(height: 10),
        _waterChoice(
          label: "Regular irrigation available",
          value: "regular",
          icon: Icons.water,
        ),
      ],
    );
  }

  Widget _waterChoice({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _irrigationLevel == value;
    return InkWell(
      onTap: () {
        setState(() => _irrigationLevel = value);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isSelected ? Colors.green.shade600 : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.blue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 4: LOCATION
  Widget _buildLocationStep() {
    return Column(
      key: const ValueKey("location_step"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          "Where is your field?",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "You can use GPS or select your village.",
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _locationChoice(
              label: "Use my location",
              value: "gps",
              icon: Icons.my_location,
            ),
            const SizedBox(width: 10),
            _locationChoice(
              label: "Select village",
              value: "village",
              icon: Icons.location_city,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_locationMode == "village") ...[
          const Text(
            "Village name",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _villageController,
            decoration: InputDecoration(
              hintText: "Enter village name",
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() => _villageName = value);
            },
          ),
        ],
        if (_locationMode == "gps") ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "In real app, this will read GPS and fill location automatically.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _locationChoice({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _locationMode == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _locationMode = value;
            if (value == "gps") {
              _villageName = null;
              _villageController.clear();
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected ? Colors.green.shade600 : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.blueGrey,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 5: PHOTO (OPTIONAL)
  Widget _buildPhotoStep() {
    return Column(
      key: const ValueKey("photo_step"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          "Do you want to add a field photo?",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "This is optional, but helps you recognize fields.",
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: _photoAdded
                ? const Text(
                    "Photo added (mock)\nIntegrate image picker here.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13),
                  )
                : const Text(
                    "No photo yet.\nYou can add one now or skip.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Integrate ImagePicker, then:
                setState(() => _photoAdded = true);
              },
              icon: const Icon(Icons.photo_camera),
              label: const Text("Take Photo"),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () {
                setState(() => _photoAdded = false);
              },
              child: const Text("Skip"),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------- BOTTOM BAR --------------------

  Widget _buildBottomBar() {
    final isLast = _step == 5;
    final canNext = _canGoNext();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: _goBack,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(_step == 0 ? "Cancel" : "Back"),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: canNext ? _goNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey.shade400,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              isLast ? "Save Field" : "Next",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
