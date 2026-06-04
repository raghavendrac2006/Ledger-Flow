import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import 'bento_card.dart';

class OverallBusinessOverviewWidget extends StatelessWidget {
  final double overallRevenue;
  final double overallExpenses;
  final double overallProfit;
  final double overallProfitMargin;

  const OverallBusinessOverviewWidget({
    super.key,
    required this.overallRevenue,
    required this.overallExpenses,
    required this.overallProfit,
    required this.overallProfitMargin,
  });

  @override
  Widget build(BuildContext context) {
    final formattedProfit = "₹${NumberFormat('#,##,###.00').format(overallProfit)}";
    final formattedRevenue = "₹${NumberFormat('#,##,###').format(overallRevenue)}";
    final formattedExpenses = "₹${NumberFormat('#,##,###').format(overallExpenses)}";
    final formattedMargin = "${overallProfitMargin.toStringAsFixed(1)}%";

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
                      "OVERALL NET PROFIT",
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
                        color: overallProfit >= 0 ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                overallProfit >= 0 ? Icons.monetization_on : Icons.money_off,
                color: overallProfit >= 0 ? AppTheme.success : AppTheme.error,
                size: 28.0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        Row(
          children: [
            _buildSecondaryCard(
              "OVERALL REVENUE",
              formattedRevenue,
              AppTheme.primary,
            ),
            const SizedBox(width: 8.0),
            _buildSecondaryCard(
              "OVERALL EXPENSES",
              formattedExpenses,
              AppTheme.error,
            ),
            const SizedBox(width: 8.0),
            _buildSecondaryCard(
              "OVERALL MARGIN",
              formattedMargin,
              overallProfitMargin >= 0 ? AppTheme.success : AppTheme.error,
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

