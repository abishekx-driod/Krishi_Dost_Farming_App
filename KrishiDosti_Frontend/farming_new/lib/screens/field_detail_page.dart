import 'package:flutter/material.dart';
import '../models/field_model.dart';

class FieldDetailPage extends StatelessWidget {
  final FieldModel field;

  const FieldDetailPage({super.key, required this.field});

  // ---------------------------------------------------------------------------
  // SIMPLE AGRONOMY LOGIC (based on farmer input)
  // ---------------------------------------------------------------------------

  DateTime? _parseSowingDate() {
    if (field.sowingDate == null || field.sowingDate!.isEmpty) return null;
    try {
      return DateTime.parse(field.sowingDate!);
    } catch (_) {
      return null;
    }
  }

  int? _daysSinceSowing() {
    final sowing = _parseSowingDate();
    if (sowing == null) return null;
    return DateTime.now().difference(sowing).inDays;
  }

  String _growthStageLabel() {
    final days = _daysSinceSowing();
    if (days == null) return "Unknown";

    if (days < 7) return "Sowing";
    if (days < 25) return "Early growth";
    if (days < 50) return "Vegetative";
    if (days < 80) return "Flowering";
    if (days < 110) return "Grain filling";
    return "Near harvest";
  }

  // Simple 1–10 yield score
  int _yieldScore() {
    int score = 6;

    // Irrigation effect
    switch ((field.irrigationType ?? "").toLowerCase()) {
      case "regular":
        score += 2;
        break;
      case "sometimes":
        score += 1;
        break;
      case "none":
        score -= 2;
        break;
    }

    // Fertilizer given or not
    if (field.fertilizerType != null &&
        field.fertilizerType!.trim().isNotEmpty) {
      score += 1;
    } else {
      score -= 1;
    }

    // Very early or very late -> less certain
    final days = _daysSinceSowing();
    if (days != null) {
      if (days < 7) score -= 1;
      if (days > 120) score -= 1;
    }

    if (score < 1) score = 1;
    if (score > 10) score = 10;
    return score;
  }

  String _yieldText() {
    final score = _yieldScore();
    if (score >= 8) return "High";
    if (score >= 5) return "Medium";
    return "Low";
  }

  // 0 = low, 1 = medium, 2 = high
  int _diseaseRiskLevel() {
    int level = 1; // base: medium

    final crop = (field.crop ?? "").toLowerCase();
    final irrig = (field.irrigationType ?? "").toLowerCase();
    final days = _daysSinceSowing() ?? 0;

    // Paddy + regular irrigation -> higher fungal risk
    if (crop.contains("paddy") || crop.contains("rice")) {
      if (irrig == "regular" && days > 30) level = 2;
    }

    // Very dry fields at flowering -> stress, moderate/high risk
    if (irrig == "none" && days > 40 && days < 90) {
      level = 2;
    }

    // Very young crop -> usually lower risk
    if (days < 15) {
      level = 0;
    }

    if (level < 0) level = 0;
    if (level > 2) level = 2;
    return level;
  }

  String _diseaseRiskText() {
    switch (_diseaseRiskLevel()) {
      case 0:
        return "Low";
      case 2:
        return "High";
      default:
        return "Medium";
    }
  }

  Color _diseaseChipColor() {
    switch (_diseaseRiskLevel()) {
      case 0:
        return Colors.green.shade100;
      case 2:
        return Colors.red.shade100;
      default:
        return Colors.orange.shade100;
    }
  }

  Color _diseaseChipTextColor() {
    switch (_diseaseRiskLevel()) {
      case 0:
        return Colors.green.shade800;
      case 2:
        return Colors.red.shade800;
      default:
        return Colors.orange.shade800;
    }
  }

  // Overall "health score" (0–100) used in header analytics
  int _overallHealthScore() {
    final yieldScore = _yieldScore(); // 1–10
    final disease = _diseaseRiskLevel(); // 0–2

    int base = yieldScore * 8; // 8–80
    if (disease == 0) base += 15; // low risk -> +15
    if (disease == 2) base -= 15; // high risk -> -15

    if (base < 10) base = 10;
    if (base > 95) base = 95;
    return base;
  }

  // Smart tasks for "Today"
  List<_TaskItem> _buildTodayTasks() {
    final stage = _growthStageLabel();
    final irrig = (field.irrigationType ?? "").toLowerCase();

    final List<_TaskItem> tasks = [];

    if (stage == "Sowing" || stage == "Early growth") {
      tasks.add(
        _TaskItem(
          icon: Icons.water_drop,
          title: "Light irrigation",
          subtitle: "Keep soil moist for better root growth.",
        ),
      );
      tasks.add(
        _TaskItem(
          icon: Icons.search,
          title: "Check seedling health",
          subtitle: "Look for yellow or damaged leaves.",
        ),
      );
    } else if (stage == "Vegetative") {
      tasks.add(
        _TaskItem(
          icon: Icons.grass,
          title: "Weeding",
          subtitle: "Remove weeds competing with the crop.",
        ),
      );
      tasks.add(
        _TaskItem(
          icon: Icons.bolt,
          title: "Nitrogen fertilizer",
          subtitle: "Apply recommended dose (e.g. Urea).",
        ),
      );
    } else if (stage == "Flowering" || stage == "Grain filling") {
      tasks.add(
        _TaskItem(
          icon: Icons.bug_report,
          title: "Inspect for pests",
          subtitle: "Check leaves and panicles for insects.",
        ),
      );
      tasks.add(
        _TaskItem(
          icon: Icons.science,
          title: "Disease monitoring",
          subtitle: "Look for spots, rust, or rotting.",
        ),
      );
    } else {
      tasks.add(
        _TaskItem(
          icon: Icons.agriculture,
          title: "Plan harvesting",
          subtitle: "Check grain maturity and market prices.",
        ),
      );
    }

    // Extra irrigation-specific advice
    if (irrig == "none") {
      tasks.insert(
        0,
        _TaskItem(
          icon: Icons.warning_amber_rounded,
          title: "Monitor moisture",
          subtitle: "No irrigation available, watch for wilting.",
        ),
      );
    } else if (irrig == "regular") {
      tasks.insert(
        0,
        _TaskItem(
          icon: Icons.schedule,
          title: "Irrigate in evening",
          subtitle: "Less evaporation, better water use.",
        ),
      );
    }

    return tasks;
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final growthStage = _growthStageLabel();
    final yieldScore = _yieldScore();
    final yieldText = _yieldText();
    final overallHealth = _overallHealthScore();
    final diseaseText = _diseaseRiskText();
    final tasks = _buildTodayTasks();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        title: Text(
          field.name.isNotEmpty ? field.name : "My Field",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: const [
          IconButton(
            icon: Icon(Icons.edit_outlined),
            onPressed: null, // TODO: connect edit screen
          ),
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: null, // TODO: connect delete
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          children: [
            _buildHeaderAnalyticsCard(
              growthStage: growthStage,
              overallHealth: overallHealth,
              yieldScore: yieldScore,
              yieldText: yieldText,
              diseaseText: diseaseText,
            ),
            const SizedBox(height: 12),
            _buildYieldPredictionCard(yieldScore, yieldText),
            const SizedBox(height: 12),
            _buildDiseaseCard(diseaseText),
            const SizedBox(height: 12),
            _buildSmartRecommendationsCard(
              growthStage: growthStage,
              irrig: field.irrigationType,
              fert: field.fertilizerType,
            ),
            const SizedBox(height: 12),
            _buildTodayTasksCard(tasks),
            const SizedBox(height: 12),
            _buildMapCard(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARDS
  // ---------------------------------------------------------------------------

  Widget _buildHeaderAnalyticsCard({
    required String growthStage,
    required int overallHealth,
    required int yieldScore,
    required String yieldText,
    required String diseaseText,
  }) {
    final crop = field.crop ?? "Unknown crop";
    final sizeText =
        field.size != null && field.size! > 0 ? "${field.size} acre" : "";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFDCFCE7), Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.terrain_outlined,
                    color: Colors.green, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 15),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            field.location ?? "Location not set",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (crop.isNotEmpty || sizeText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        [crop, sizeText].where((e) => e.isNotEmpty).join(" • "),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Circular health
              SizedBox(
                height: 48,
                width: 48,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: overallHealth / 100,
                      strokeWidth: 5,
                      backgroundColor: Colors.white.withOpacity(0.4),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        overallHealth >= 80
                            ? Colors.green
                            : (overallHealth >= 60
                                ? Colors.orange
                                : Colors.red),
                      ),
                    ),
                    Center(
                      child: Text(
                        "$overallHealth",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Field Analytics",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Stage: $growthStage • Yield: $yieldText",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _pill(
                    label: "Yield: $yieldScore / 10",
                    color: Colors.green.shade100,
                    textColor: Colors.green.shade800,
                  ),
                  const SizedBox(height: 6),
                  _pill(
                    label: "Disease: $diseaseText",
                    color: _diseaseChipColor(),
                    textColor: _diseaseChipTextColor(),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYieldPredictionCard(int yieldScore, String yieldText) {
    // we just show 3 bars: last, now, next
    final last = (yieldScore - 2).clamp(1, 10);
    final now = yieldScore;
    final next = (yieldScore + 1).clamp(1, 10);

    double _barHeight(int v) => 16.0 + (v * 4.0);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Yield Prediction",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Current expected yield: $yieldText ($yieldScore / 10)",
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _bar("Last", last, _barHeight(last)),
                _bar("Now", now, _barHeight(now)),
                _bar("Next", next, _barHeight(next)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(String label, int value, double height) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: height,
            width: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.green.shade400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseCard(String diseaseText) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 18, color: Colors.orange),
              const SizedBox(width: 6),
              const Text(
                "Disease Risk",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: _pill(
              label: diseaseText,
              color: _diseaseChipColor(),
              textColor: _diseaseChipTextColor(),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Risk level is estimated based on crop, growth stage and irrigation. Inspect the crop regularly and act early.",
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartRecommendationsCard({
    required String growthStage,
    required String? irrig,
    required String? fert,
  }) {
    final List<_RecoItem> recos = [];

    // Example AI-like advice
    if (irrig != null && irrig.toLowerCase() == "regular") {
      recos.add(
        _RecoItem(
          title: "Irrigate in the evening",
          subtitle: "Temperature is lower, so less water is lost.",
        ),
      );
    } else if (irrig != null && irrig.toLowerCase() == "none") {
      recos.add(
        _RecoItem(
          title: "Use mulching if possible",
          subtitle: "Mulch helps soil keep moisture when water is scarce.",
        ),
      );
    }

    if ((fert ?? "").isNotEmpty) {
      recos.add(
        _RecoItem(
          title: "Follow fertilizer schedule",
          subtitle: "Avoid overuse. Too much fertilizer can harm plants.",
        ),
      );
    } else {
      recos.add(
        _RecoItem(
          title: "Plan fertilizer dose",
          subtitle: "Based on crop stage: $growthStage.",
        ),
      );
    }

    recos.add(
      _RecoItem(
        title: "Walk through the field",
        subtitle: "Look for yellow leaves, pest damage, or wilting.",
      ),
    );

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline,
                  size: 18, color: Colors.orangeAccent),
              SizedBox(width: 6),
              Text(
                "Smart Recommendations",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final r in recos) ...[
            _recommendationItem(r),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _recommendationItem(_RecoItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.bolt, size: 18, color: Colors.orange),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayTasksCard(List<_TaskItem> tasks) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
              SizedBox(width: 6),
              Text(
                "Today's Tasks",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final t in tasks) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(t.icon, size: 18, color: Colors.green),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    final hasCoords = field.latitude != null && field.longitude != null;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.map_outlined, size: 18, color: Colors.blueGrey),
              SizedBox(width: 6),
              Text(
                "Field Location (Map)",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: hasCoords
                  ? Text(
                      "Lat: ${field.latitude!.toStringAsFixed(4)}, "
                      "Lng: ${field.longitude!.toStringAsFixed(4)}\n"
                      "You can replace this with Google Map widget.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    )
                  : const Text(
                      "Map preview here\n(Location not set)",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SMALL UI HELPERS
  // ---------------------------------------------------------------------------

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _pill({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SMALL DATA CLASSES FOR INTERNAL USE
// -----------------------------------------------------------------------------

class _TaskItem {
  final IconData icon;
  final String title;
  final String subtitle;

  _TaskItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _RecoItem {
  final String title;
  final String subtitle;

  _RecoItem({required this.title, required this.subtitle});
}
