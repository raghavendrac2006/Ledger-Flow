import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import 'bento_card.dart';

class CurrentBagPerformanceWidget extends StatelessWidget {
  final double revenue;
  final double expenses;
  final double profit;
  final double profitMargin;

  const CurrentBagPerformanceWidget({
    super.key,
    required this.revenue,
    required this.expenses,
    required this.profit,
    required this.profitMargin,
  });

  @override
  Widget build(BuildContext context) {
    final formattedProfit = "₹${NumberFormat('#,##,###.00').format(profit)}";
    final formattedRevenue = "₹${NumberFormat('#,##,###').format(revenue)}";
    final formattedExpenses = "₹${NumberFormat('#,##,###').format(expenses)}";
    final formattedMargin = "${profitMargin.toStringAsFixed(1)}%";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BentoCard(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          backgroundColor: AppTheme.surface,
          shadowStyle: ShadowStyle.light,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CURRENT BAG NET PROFIT",
                      style: AppTheme.labelSm.copyWith(
                        fontSize: 9.0,
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      formattedProfit,
                      style: AppTheme.headlineMd.copyWith(
                        fontSize: 24.0,
                        color: profit >= 0 ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                profit >= 0 ? Icons.trending_up : Icons.trending_down,
                color: profit >= 0 ? Colors.green[700] : Colors.red[700],
                size: 28.0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12.0),
        Row(
          children: [
            _buildSecondaryCard(
              "REVENUE",
              formattedRevenue,
              AppTheme.primary,
            ),
            const SizedBox(width: 8.0),
            _buildSecondaryCard(
              "EXPENSES",
              formattedExpenses,
              Colors.red[700] ?? Colors.red,
            ),
            const SizedBox(width: 8.0),
            _buildSecondaryCard(
              "MARGIN",
              formattedMargin,
              profitMargin >= 0 ? Colors.green[700] ?? Colors.green : Colors.red[700] ?? Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryCard(String label, String value, Color valueColor) {
    return Expanded(
      child: BentoCard(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        backgroundColor: AppTheme.surface,
        shadowStyle: ShadowStyle.light,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.labelSm.copyWith(
                fontSize: 8.0,
                color: AppTheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              value,
              style: AppTheme.headlineMd.copyWith(
                fontSize: 13.0,
                color: valueColor,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
