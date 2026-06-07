import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_theme.dart';
import '../core/app_state.dart';
import '../widgets/bento_card.dart';

class SetupScreen extends StatefulWidget {
  final VoidCallback? onRoundsStarted;
  const SetupScreen({super.key, this.onRoundsStarted});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _isStarting = false;
  final TextEditingController _riceUsageController = TextEditingController();

  @override
  void dispose() {
    _riceUsageController.dispose();
    super.dispose();
  }

  void _showUsageHistoryDialog(BuildContext context, LedgerState state) {
    final activeBag = state.activeRiceBag;
    if (activeBag == null) return;

    final usages = state.dailyUsages.where((u) => u.bagId == activeBag.bagId).toList();
    
    DateTime parseDate(String dateStr) {
      try {
        return DateFormat('dd MMMM yyyy').parse(dateStr);
      } catch (_) {
        try {
          return DateTime.parse(dateStr);
        } catch (_) {
          return DateTime.fromMillisecondsSinceEpoch(0);
        }
      }
    }

    usages.sort((a, b) {
      final dateA = parseDate(a.date);
      final dateB = parseDate(b.date);
      final dateCompare = dateB.compareTo(dateA); // Latest date at the top
      if (dateCompare != 0) {
        return dateCompare;
      }
      // Within the same day, First-In-First-Out (oldest creation time first)
      return a.usageId.compareTo(b.usageId);
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            side: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
          ),
          backgroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "PRODUCTION LOGS",
                style: AppTheme.headlineMd.copyWith(fontSize: 18.0),
              ),
              const SizedBox(height: 4.0),
              Text(
                "Active Bag #${state.getBagNumber(activeBag)} (${activeBag.totalKg.toStringAsFixed(0)} KG)",
                style: AppTheme.labelSm.copyWith(color: AppTheme.onSurfaceVariant),
              ),
            ],
          ),
          content: usages.isEmpty
              ? SizedBox(
                  height: 120,
                  child: Center(
                     child: Text(
                      "No daily production logged for this bag yet.",
                      style: AppTheme.labelSm.copyWith(color: AppTheme.outline),
                    ),
                  ),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: usages.length,
                    separatorBuilder: (context, index) => const Divider(color: AppTheme.outlineVariant),
                    itemBuilder: (context, index) {
                      final usage = usages[index];
                      String displayDate = usage.date;
                      try {
                        final parsed = DateFormat('dd MMMM yyyy').parse(usage.date);
                        displayDate = DateFormat('dd MMM yyyy').format(parsed);
                      } catch (_) {
                        try {
                          final parsed = DateTime.parse(usage.date);
                          displayDate = DateFormat('dd MMM yyyy').format(parsed);
                        } catch (_) {
                          // Keep as is
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppTheme.primary, size: 16.0),
                                const SizedBox(width: 12.0),
                                Text(
                                  displayDate,
                                  style: AppTheme.bodyMd.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Text(
                              "${usage.usedKg.toStringAsFixed(1)} KG",
                              style: AppTheme.dataTabular.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "CLOSE",
                style: AppTheme.labelBold.copyWith(color: AppTheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddProductDialog(BuildContext context, LedgerState state) {
    final TextEditingController nameCont = TextEditingController();
    final TextEditingController subCont = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            side: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
          ),
          backgroundColor: Colors.white,
          title: Text(
            "NEW PRODUCT VARIETY",
            style: AppTheme.headlineMd.copyWith(fontSize: 18.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCont,
                decoration: InputDecoration(
                  labelText: "PRODUCT NAME",
                  labelStyle: AppTheme.labelBold.copyWith(fontSize: 10, color: AppTheme.outline),
                  hintText: "e.g., ₹10 Mixture, 5rs Chakli...",
                  hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.outline),
                ),
                style: AppTheme.bodyLg,
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: subCont,
                decoration: InputDecoration(
                  labelText: "SUBTITLE / DESCRIPTION",
                  labelStyle: AppTheme.labelBold.copyWith(fontSize: 10, color: AppTheme.outline),
                  hintText: "e.g., Crispy Snack Bag...",
                  hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.outline),
                ),
                style: AppTheme.bodyLg,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "CANCEL",
                style: AppTheme.labelBold.copyWith(color: AppTheme.outline),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: TextButton(
                onPressed: () {
                  final name = nameCont.text.trim();
                  final sub = subCont.text.trim();
                  if (name.isNotEmpty) {
                    state.addSetupItem(
                      name: name,
                      subtitle: sub.isNotEmpty ? sub : "Custom variety",
                      icon: Icons.cookie,
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  "ADD PRODUCT",
                  style: AppTheme.labelBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context, LedgerState state) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: state.deliveryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                textStyle: AppTheme.labelBold,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != state.deliveryDate) {
      state.setDeliveryDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LedgerState>(context);
    final formattedDate = DateFormat('dd MMMM yyyy').format(state.deliveryDate);
    final formattedDayName = DateFormat('EEEE').format(state.deliveryDate).toUpperCase();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero header block
              Text(
                "ROUTE INITIALIZATION",
                style: AppTheme.labelSm.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                "Daily Setup",
                style: AppTheme.headlineXl,
              ),
              const SizedBox(height: 24.0),

              // Date Picker Card
              Text(
                "DELIVERY DATE",
                style: AppTheme.labelBold.copyWith(fontSize: 12, color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8.0),
              BentoCard(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
                backgroundColor: AppTheme.surface,
                borderRadius: AppTheme.radiusLg,
                shadowStyle: ShadowStyle.light,
                onTap: () => _selectDate(context, state),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: AppTheme.primary,
                      size: 28.0,
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDayName,
                            style: AppTheme.labelSm.copyWith(
                              color: AppTheme.onSurfaceVariant,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            formattedDate,
                            style: AppTheme.headlineMd.copyWith(
                              fontSize: 18.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: AppTheme.borderSm,
                      ),
                      child: Text(
                        "CHANGE",
                        style: AppTheme.labelBold.copyWith(
                          fontSize: 11.0,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32.0),

              // Rice Flour Daily Usage Tracker Input
              Text(
                "RICE FLOUR DAILY PRODUCTION",
                style: AppTheme.labelBold.copyWith(fontSize: 12, color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8.0),
              GestureDetector(
                onLongPress: () {
                  if (state.activeRiceBag != null) {
                    _showUsageHistoryDialog(context, state);
                  }
                },
                child: BentoCard(
                  padding: const EdgeInsets.all(18.0),
                  backgroundColor: AppTheme.surface,
                  borderRadius: AppTheme.radiusLg,
                  shadowStyle: ShadowStyle.light,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.activeRiceBag == null) ...[
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 24.0),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Text(
                                "No active rice flour bag cycle started yet. Log RICE FLOUR cost in Expenses tab to initialize a bag.",
                                style: AppTheme.labelSm.copyWith(color: AppTheme.error, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "ACTIVE BAG STATUS (LONG PRESS FOR LOGS)",
                              style: AppTheme.labelSm.copyWith(
                                color: AppTheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: 9.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: AppTheme.primary, width: 1.0),
                              ),
                              child: Text(
                                "ACTIVE",
                                style: AppTheme.labelBold.copyWith(fontSize: 9.0, color: AppTheme.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          children: [
                            _buildBagMetric("TOTAL KG", "${state.activeRiceBag!.totalKg.toStringAsFixed(0)} KG"),
                            _buildSeparator(),
                            _buildBagMetric("USED", "${state.activeRiceBag!.usedKg.toStringAsFixed(1)} KG"),
                            _buildSeparator(),
                            _buildBagMetric("REMAINING", "${state.activeRiceBag!.remainingKg.toStringAsFixed(1)} KG", isHighlighted: true),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        const Divider(color: AppTheme.outlineVariant, height: 1),
                        const SizedBox(height: 16.0),
                        Text(
                          "HOW MANY KG OF RICE FLOUR USED TODAY?",
                          style: AppTheme.labelBold.copyWith(fontSize: 10.0, color: AppTheme.onSurface),
                        ),
                        const SizedBox(height: 10.0),
                        TextField(
                          controller: _riceUsageController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: "e.g., 7.0",
                            suffixText: "KG",
                            suffixStyle: AppTheme.labelBold.copyWith(color: AppTheme.onSurface),
                            filled: true,
                            fillColor: AppTheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              borderSide: const BorderSide(color: AppTheme.primary, width: 2.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                          ),
                          style: AppTheme.headlineMd.copyWith(fontSize: 18.0),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32.0),

              // Product Choice Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "ITEMS TO SELL TODAY",
                    style: AppTheme.labelBold.copyWith(fontSize: 12, color: AppTheme.onSurfaceVariant),
                  ),
                  Text(
                    "${state.setupItems.where((x) => x['isSelected'] == true).length} SELECTED",
                    style: AppTheme.labelBold.copyWith(
                      fontSize: 12, 
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Product Choice Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisExtent: 88,
                  mainAxisSpacing: 16,
                ),
                itemCount: state.setupItems.length,
                itemBuilder: (context, index) {
                  final item = state.setupItems[index];
                  final isSelected = item["isSelected"] as bool;

                  return BentoCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    backgroundColor: isSelected ? AppTheme.surfaceContainerLow : AppTheme.surface,
                    borderRadius: AppTheme.radiusLg,
                    border: isSelected
                        ? Border.all(color: AppTheme.primary, width: 2.0)
                        : AppTheme.cardBorder,
                    shadowStyle: isSelected ? ShadowStyle.heavy : ShadowStyle.light,
                    onTap: () => state.toggleSetupItem(index),
                    child: Row(
                      children: [
                        // Dynamic circle shape icon indicator
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: Icon(
                            item["icon"] as IconData,
                            color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                            size: 24.0,
                          ),
                        ),
                        const SizedBox(width: 16.0),
                        // Title / Subtitle
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["name"] as String,
                                style: AppTheme.headlineMd.copyWith(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  decoration: isSelected ? TextDecoration.none : null,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                item["subtitle"] as String,
                                style: AppTheme.labelSm.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Soft Shape Custom Checkbox
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary : Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.outline, width: 1.5),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18.0,
                                )
                              : null,
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 16.0),
              // ADD CUSTOM PRODUCT BUTTON
              InkWell(
                onTap: () => _showAddProductDialog(context, state),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.primary, width: 1.5),
                    boxShadow: AppTheme.hardShadowLight,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: AppTheme.primary, size: 20.0),
                      const SizedBox(width: 8.0),
                      Text(
                        "ADD CUSTOM PRODUCT",
                        style: AppTheme.labelBold.copyWith(
                          fontSize: 13.0,
                          color: AppTheme.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40.0),

              // BIG ACTION BUTTON
              InkWell(
                onTap: (!state.isStartRoundsEnabled || _isStarting)
                    ? null
                    : () => _handleStartRounds(state),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  decoration: BoxDecoration(
                    color: state.isStartRoundsEnabled
                        ? AppTheme.primary
                        : AppTheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: state.isStartRoundsEnabled && !_isStarting
                        ? AppTheme.hardShadowButton
                        : null,
                  ),
                  child: Center(
                    child: _isStarting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3.0,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                (state.roundsStarted ? "UPDATE ACTIVE ITEMS" : "START ROUNDS").toUpperCase(),
                                style: AppTheme.headlineMd.copyWith(
                                  fontSize: 16.0,
                                  color: state.isStartRoundsEnabled
                                      ? Colors.white
                                      : AppTheme.outline,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Icon(
                                Icons.arrow_forward,
                                color: state.isStartRoundsEnabled
                                    ? Colors.white
                                    : AppTheme.outline,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Center(
                child: Text(
                  state.roundsStarted
                      ? "Update your selection for today's active delivery rounds."
                      : "Select at least one product to begin the day's delivery rounds.",
                  style: AppTheme.labelSm.copyWith(
                    fontSize: 11.0,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get isSelectedStyle => true;

  Widget _buildBagMetric(String label, String value, {bool isHighlighted = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.labelSm.copyWith(
              fontSize: 9.0,
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: AppTheme.headlineMd.copyWith(
              fontSize: 16.0,
              color: isHighlighted ? AppTheme.primary : AppTheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
      width: 1.5,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      color: AppTheme.outlineVariant,
    );
  }

  void _handleStartRounds(LedgerState state) async {
    final usageText = _riceUsageController.text.trim();
    final double usageKg = double.tryParse(usageText) ?? 0.0;

    final activeBag = state.activeRiceBag;

    if (usageKg > 0.0) {
      if (activeBag == null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              side: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
            ),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                const SizedBox(width: 8.0),
                Text("NO ACTIVE BAG", style: AppTheme.headlineMd.copyWith(fontSize: 18.0)),
              ],
            ),
            content: const Text(
              "You entered a rice flour usage, but no bag is currently active. Please register a bag in the Expenses page first.",
              style: TextStyle(fontSize: 14.0, color: AppTheme.onSurface),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK", style: AppTheme.labelBold.copyWith(color: AppTheme.primary)),
              ),
            ],
          ),
        );
        return;
      }

      if (usageKg > activeBag.remainingKg) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              side: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
            ),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                const SizedBox(width: 8.0),
                Text("LIMIT EXCEEDED", style: AppTheme.headlineMd.copyWith(fontSize: 18.0)),
              ],
            ),
            content: Text(
              "Rice flour usage exceeded current bag limit.\n\nRemaining: ${activeBag.remainingKg.toStringAsFixed(1)} KG\nAttempted: ${usageKg.toStringAsFixed(1)} KG",
              style: const TextStyle(fontSize: 14.0, color: AppTheme.onSurface),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("CANCEL", style: AppTheme.labelBold.copyWith(color: AppTheme.outline)),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleStartRoundsWithAudit(state, usageKg);
                  },
                  child: Text("PROCEED ANYWAY", style: AppTheme.labelBold.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
        return;
      }
    }

    _handleStartRoundsWithAudit(state, usageKg);
  }

  void _handleStartRoundsWithAudit(LedgerState state, double usageKg) async {
    setState(() {
      _isStarting = true;
    });

    try {
      final auditDate = state.deliveryDate.subtract(const Duration(days: 1));
      final auditDateStr = DateFormat('yyyy-MM-dd').format(auditDate);

      final auditDoc = await FirebaseFirestore.instance
          .collection('audit_results')
          .doc(auditDateStr)
          .get();

      if (auditDoc.exists && auditDoc.data() != null) {
        final result = auditDoc.data()!['result'] as String? ?? '';
        if (result.startsWith("ALERT:")) {
          setState(() {
            _isStarting = false;
          });
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  side: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
                ),
                backgroundColor: Colors.white,
                title: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                    const SizedBox(width: 8.0),
                    Text("AUDIT ALERT", style: AppTheme.headlineMd.copyWith(fontSize: 18.0)),
                  ],
                ),
                content: Text(
                  "Yesterday's financial ledger has audit warnings:\n\n${result.replaceFirst("ALERT:", "").trim()}\n\nDo you want to proceed with starting today's rounds?",
                  style: const TextStyle(fontSize: 14.0, color: AppTheme.onSurface),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("CANCEL", style: AppTheme.labelBold.copyWith(color: AppTheme.outline)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _proceedWithStartRounds(state, usageKg);
                      },
                      child: Text("PROCEED", style: AppTheme.labelBold.copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Error checking audit results: $e");
    }

    _proceedWithStartRounds(state, usageKg);
  }

  void _proceedWithStartRounds(LedgerState state, double usageKg) {
    setState(() {
      _isStarting = true;
    });

    if (usageKg > 0.0) {
      final formattedDate = DateFormat('dd MMMM yyyy').format(state.deliveryDate);
      state.addDailyUsage(usedKg: usageKg, date: formattedDate);
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        state.startRounds();
        setState(() {
          _isStarting = false;
        });
        _riceUsageController.clear();
        widget.onRoundsStarted?.call();
      }
    });
  }
}

