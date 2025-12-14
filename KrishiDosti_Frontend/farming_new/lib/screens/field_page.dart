import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

import '../models/field_model.dart';
import '../services/field_service.dart';
import 'add_field_wizard_page.dart'; // ⬅️ NEW WIZARD
import 'field_detail_page.dart';

class FieldPage extends StatefulWidget {
  const FieldPage({super.key});

  @override
  State<FieldPage> createState() => _FieldPageState();
}

class _FieldPageState extends State<FieldPage> {
  final FieldService _fieldService = FieldService();

  String _searchQuery = "";
  String _selectedCropFilter = "All";
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),

      // Add Field button – lifted above bottom nav, right side
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.black,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "Add Field",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          onPressed: _onAddFieldPressed,
        ),
      ),

      appBar: AppBar(
        title: const Text(
          "My Fields",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: StreamBuilder<List<FieldModel>>(
        stream: _fieldService.watchFields(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          }

          final fields = snapshot.data ?? [];

          if (fields.isEmpty) {
            return _buildEmptyState();
          }

          // Apply search + crop filter
          final filteredFields = _applyFilters(fields);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildOverviewCard(fields),
                const SizedBox(height: 12),
                _buildFilterRow(fields),
                const SizedBox(height: 8),
                _buildViewToggle(),
                const SizedBox(height: 6),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: filteredFields.isEmpty
                        ? _buildNoMatchState()
                        : _isGridView
                            ? _buildGridView(filteredFields)
                            : _buildListView(filteredFields),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ADD FIELD NAVIGATION (NOW USING WIZARD)
  // ---------------------------------------------------------------------------
  Future<void> _onAddFieldPressed() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AddFieldWizardPage(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          );
        },
      ),
    );

    if (!mounted) return;
    if (result == null) return;

    // -------------------------------
    // SAVE TO FIRESTORE
    // -------------------------------

    final newField = FieldModel(
      id: "", // Firestore auto ID
      name: result["fieldName"] ?? "My Field",
      crop: result["crop"] ?? "",
      size: double.tryParse(result["size"]?.toString() ?? "") ?? 0,
      location: result["villageName"] ?? "",
      latitude: result["lat"],
      longitude: result["lng"],
      sowingDate: result["sowingDate"],
      irrigationType: result["irrigationType"],
      fertilizerType: result["fertilizerType"],
    );

    await _fieldService.addField(newField);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Field saved successfully")),
    );
  }

  // ---------------------------------------------------------------------------
  // FILTERING
  // ---------------------------------------------------------------------------
  List<FieldModel> _applyFilters(List<FieldModel> fields) {
    return fields.where((f) {
      final matchesSearch = _searchQuery.isEmpty ||
          f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (f.location ?? "").toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCrop = _selectedCropFilter == "All" ||
          (f.crop ?? "").toLowerCase() == _selectedCropFilter.toLowerCase();

      return matchesSearch && matchesCrop;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // UI SECTIONS
  // ---------------------------------------------------------------------------

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildShimmerHeader(),
          const SizedBox(height: 16),
          Expanded(child: _buildShimmerList()),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          "Something went wrong.\n$error",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            // Icon circle
            _EmptyIconCircle(),

            SizedBox(height: 22),

            Text(
              "No Fields Added Yet",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: 8),

            Text(
              "Add your first field to start tracking crops,\nweather and soil conditions.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
            ),

            SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // If filters return 0 but there are fields
  Widget _buildNoMatchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off, size: 48, color: Colors.black38),
            SizedBox(height: 10),
            Text(
              "No fields match your search/filter.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- SEARCH BAR --------------------
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
          hintText: "Search fields by name or location...",
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  // -------------------- OVERVIEW CARD --------------------
  Widget _buildOverviewCard(List<FieldModel> fields) {
    final totalArea = fields.fold<double>(0, (sum, f) => sum + (f.size ?? 0));
    final cropSet = fields
        .map((f) => f.crop)
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toSet();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFB9F5D0), Color(0xFFE8F8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.agriculture, size: 26, color: Colors.green),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Field Overview",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${fields.length} fields • ${totalArea.toStringAsFixed(1)} acre • ${cropSet.length} crop types",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Colors.black54, size: 22),
        ],
      ),
    );
  }

  // -------------------- FILTER CHIPS --------------------
  Widget _buildFilterRow(List<FieldModel> fields) {
    final cropSet = fields
        .map((f) => f.crop)
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final filters = ["All", ...cropSet];

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final label = filters[index];
          final selected = label == _selectedCropFilter;

          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) {
              setState(() => _selectedCropFilter = label);
            },
            selectedColor: Colors.black,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontSize: 12,
            ),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
        },
      ),
    );
  }

  // -------------------- VIEW TOGGLE --------------------
  Widget _buildViewToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _viewToggleButton(
                icon: Icons.view_list_rounded,
                isActive: !_isGridView,
                onTap: () => setState(() => _isGridView = false),
              ),
              _viewToggleButton(
                icon: Icons.grid_view_rounded,
                isActive: _isGridView,
                onTap: () => setState(() => _isGridView = true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _viewToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? Colors.white : Colors.grey,
        ),
      ),
    );
  }

  // -------------------- LIST / GRID --------------------

  Widget _buildListView(List<FieldModel> fields) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 140),
      itemCount: fields.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final field = fields[index];
        return _FieldCard(
          field: field,
          onDelete: () => _fieldService.deleteField(field.id),
        );
      },
    );
  }

  Widget _buildGridView(List<FieldModel> fields) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 140),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 4 / 3,
      ),
      itemCount: fields.length,
      itemBuilder: (_, index) {
        final field = fields[index];
        return _FieldCard(
          field: field,
          compact: true,
          onDelete: () => _fieldService.deleteField(field.id),
        );
      },
    );
  }

  // -------------------- SHIMMER --------------------
  Widget _buildShimmerHeader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 140),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// EMPTY ICON CIRCLE (for empty state)
// ============================================================================
class _EmptyIconCircle extends StatelessWidget {
  const _EmptyIconCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: const Icon(
        Icons.map_outlined,
        size: 64,
        color: Colors.black54,
      ),
    );
  }
}

// ============================================================================
// FIELD CARD WIDGET
// ============================================================================

class _FieldCard extends StatelessWidget {
  final FieldModel field;
  final VoidCallback onDelete;
  final bool compact;

  const _FieldCard({
    required this.field,
    required this.onDelete,
    this.compact = false,
  });

  String get _cropLabel =>
      field.crop?.isNotEmpty == true ? field.crop! : "Unknown crop";

  String get _locationLabel =>
      field.location?.isNotEmpty == true ? field.location! : "No location";

  IconData get _cropIcon {
    final crop = (field.crop ?? "").toLowerCase();
    if (crop.contains("rice") || crop.contains("paddy")) return Icons.rice_bowl;
    if (crop.contains("wheat")) return Icons.grain;
    if (crop.contains("sugar") || crop.contains("cane")) return Icons.eco;
    if (crop.contains("maize") || crop.contains("corn")) return Icons.grain;
    if (crop.contains("veg")) return Icons.local_florist;
    return Icons.agriculture;
  }

  @override
  Widget build(BuildContext context) {
    final sizeText = field.size != null ? "${field.size} acre" : "Area not set";

    // Simple fake “health” score based on size (for UI demo)
    final size = field.size ?? 0;
    final healthScore = size >= 20
        ? 0.9
        : size >= 5
            ? 0.75
            : size > 0
                ? 0.6
                : 0.5;

    final healthLabel = healthScore >= 0.85
        ? "High potential"
        : healthScore >= 0.7
            ? "Good yield"
            : "Needs attention";

    final badgeColor = healthScore >= 0.85
        ? Colors.green.shade100
        : healthScore >= 0.7
            ? Colors.blue.shade100
            : Colors.orange.shade100;

    final badgeTextColor = Colors.black87;

    return Dismissible(
      key: ValueKey(field.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Delete field?"),
            content: Text(
              "Are you sure you want to delete '${field.name}'?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FieldDetailPage(field: field),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail / icon
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDCFCE7), Color(0xFFE0F2FE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(_cropIcon, size: 26, color: Colors.green),
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
                              const Icon(Icons.location_on_outlined, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _locationLabel,
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
                        ],
                      ),
                    ),
                    if (!compact)
                      const Icon(Icons.chevron_right_rounded,
                          size: 22, color: Colors.black45),
                  ],
                ),

                const SizedBox(height: 10),

                // Middle row: crop + size + health score
                Row(
                  children: [
                    Text(
                      _cropLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(" • "),
                    Text(
                      sizeText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const Spacer(),
                    // Health score circle
                    SizedBox(
                      height: 22,
                      width: 22,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 3,
                            value: healthScore,
                            backgroundColor: Colors.grey.shade200,
                          ),
                          Center(
                            child: Text(
                              "${(healthScore * 100).round()}",
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Bottom badges
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        healthLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Tap for insights",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
