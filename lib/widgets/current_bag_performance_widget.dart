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
          padding: const EdgeInsets.all(16.0),
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
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      formattedProfit,
                      style: AppTheme.headlineXl.copyWith(
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold,
                        color: profit >= 0 ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                profit >= 0 ? Icons.trending_up : Icons.trending_down,
                color: profit >= 0 ? AppTheme.success : AppTheme.error,
                size: 28.0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
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
              AppTheme.error,
            ),
            const SizedBox(width: 8.0),
            _buildSecondaryCard(
              "MARGIN",
              formattedMargin,
              profitMargin >= 0 ? AppTheme.success : AppTheme.error,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryCard(String label, String value, Color valueColor) {
    return Expanded(
      child: BentoCard(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        backgroundColor: AppTheme.surface,
        shadowStyle: ShadowStyle.light,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.labelSm.copyWith(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              value,
              style: AppTheme.dataTabular.copyWith(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: valueColor,
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

