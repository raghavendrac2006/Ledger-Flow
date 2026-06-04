import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../core/models/expense_log.dart';
import 'bento_card.dart';

class TotalExpenditureStatsWidget extends StatelessWidget {
  final List<ExpenseLog> expenses;

  const TotalExpenditureStatsWidget({
    super.key,
    required this.expenses,
  });

  Color _getItemColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains("cylinder") || lower.contains("gas") || lower.contains("lpg")) {
      return AppTheme.secondary;
    }
    if (lower.contains("petrol") || lower.contains("diesel") || lower.contains("transport") || lower.contains("auto") || lower.contains("scooter") || lower.contains("vehicle")) {
      return AppTheme.tertiary;
    }
    if (lower.contains("flour") || lower.contains("rice") || lower.contains("bag") || lower.contains("batch")) {
      return const Color(0xFF6B4E3D);
    }
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Total
    final total = expenses.fold<double>(0.0, (sum, exp) => sum + exp.amount);

    // 2. Group expenditures by item name for breakdown
    final Map<String, double> itemTotals = {};
    for (var exp in expenses) {
      final name = exp.itemName.trim();
      if (name.isNotEmpty) {
        itemTotals[name] = (itemTotals[name] ?? 0.0) + exp.amount;
      }
    }

    // 3. Sort item totals descending
    final sortedItems = itemTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 4. Get top 3 items for existing stats bar
    final top3 = sortedItems.take(3).toList();

    // 5. Group for Top Expense Breakdown (Top 3 + Others)
    final List<MapEntry<String, double>> breakdownCategories = [];
    double othersSum = 0.0;
    for (int i = 0; i < sortedItems.length; i++) {
      if (i < 3) {
        breakdownCategories.add(sortedItems[i]);
      } else {
        othersSum += sortedItems[i].value;
      }
    }
    if (othersSum > 0.0) {
      breakdownCategories.add(MapEntry("Others", othersSum));
    }

    // Color definitions for top 3 items
    final List<Color> segmentColors = [
      AppTheme.primary,      // Top 1
      AppTheme.secondary,    // Top 2
      AppTheme.tertiary,     // Top 3
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4. EXISTING STATISTICS
        Text(
          "TOTAL EXPENDITURE STATS",
          style: AppTheme.labelBold.copyWith(
            fontSize: 11.0,
            color: AppTheme.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12.0),

        BentoCard(
          padding: const EdgeInsets.all(20.0),
          backgroundColor: AppTheme.surface,
          shadowStyle: ShadowStyle.heavy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TOTAL EXPENDITURE",
                style: AppTheme.labelBold.copyWith(
                  fontSize: 11.0,
                  color: AppTheme.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                "₹${NumberFormat('#,##,###.00').format(total)}",
                style: AppTheme.headlineXl.copyWith(
                  fontSize: 28.0,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20.0),

              // Segmented bar
              Container(
                height: 12.0,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2.0),
                  child: Row(
                    children: [
                      if (total > 0 && top3.isEmpty)
                        Expanded(
                          child: Container(color: AppTheme.outlineVariant),
                        ),
                      ...top3.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final val = entry.value.value;
                        final pct = val / total;
                        if (pct <= 0) return const SizedBox.shrink();
                        return Expanded(
                          flex: (pct * 100).round().clamp(1, 100),
                          child: Container(color: segmentColors[idx % segmentColors.length]),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (top3.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          "No expenditures recorded yet",
                          style: AppTheme.labelSm.copyWith(color: AppTheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ...top3.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final name = entry.value.key;
                      final val = entry.value.value;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: _buildCategoryLegend(
                            name.length > 15 ? "${name.substring(0, 13)}.." : name,
                            val,
                            segmentColors[idx % segmentColors.length],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32.0),

        // 5. TOP EXPENSE BREAKDOWN
        Text(
          "TOP EXPENSES BREAKDOWN",
          style: AppTheme.labelBold.copyWith(
            fontSize: 11.0,
            color: AppTheme.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12.0),

        BentoCard(
          padding: const EdgeInsets.all(18.0),
          backgroundColor: AppTheme.surface,
          shadowStyle: ShadowStyle.light,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (breakdownCategories.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      "No expenses recorded for this period.",
                      style: TextStyle(color: AppTheme.outline),
                    ),
                  ),
                )
              else
                ...breakdownCategories.map((entry) {
                  final pct = total > 0 ? (entry.value / total) : 0.0;
                  final pctString = "${(pct * 100).toStringAsFixed(0)}%";

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: AppTheme.labelBold.copyWith(fontSize: 14.0),
                            ),
                            Text(
                              "₹${entry.value.toStringAsFixed(0)} ($pctString)",
                              style: AppTheme.dataTabular.copyWith(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6.0),
                        Container(
                          height: 8.0,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: pct,
                            child: Container(
                              decoration: BoxDecoration(
                                color: entry.key == "Others"
                                    ? AppTheme.outline
                                    : _getItemColor(entry.key),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryLegend(String name, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6.0),
            Text(
              name,
              style: AppTheme.labelSm.copyWith(fontSize: 11.0),
            ),
          ],
        ),
        const SizedBox(height: 2.0),
        Text(
          "₹${value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toStringAsFixed(0)}",
          style: AppTheme.dataTabular.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13.0,
          ),
        ),
      ],
    );
  }
}
