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
                      "OVERALL NET PROFIT",
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
                        color: overallProfit >= 0 ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                overallProfit >= 0 ? Icons.monetization_on : Icons.money_off,
                color: overallProfit >= 0 ? Colors.green[700] : Colors.red[700],
                size: 28.0,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12.0),
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
              Colors.red[700] ?? Colors.red,
            ),
            const SizedBox(width: 8.0),
            _buildSecondaryCard(
              "OVERALL MARGIN",
              formattedMargin,
              overallProfitMargin >= 0 ? Colors.green[700] ?? Colors.green : Colors.red[700] ?? Colors.red,
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
