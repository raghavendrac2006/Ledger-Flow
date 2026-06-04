import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/models/rice_bag.dart';
import 'bento_card.dart';

class BatchHistoryWidget extends StatelessWidget {
  final List<RiceBag> completedBags;
  final int Function(RiceBag) getBagNumber;
  final double Function(RiceBag) getBagProfit;
  final void Function(RiceBag, int bagNum) onBagTap;

  const BatchHistoryWidget({
    super.key,
    required this.completedBags,
    required this.getBagNumber,
    required this.getBagProfit,
    required this.onBagTap,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(0),
      backgroundColor: AppTheme.surface,
      shadowStyle: ShadowStyle.light,
      child: completedBags.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  "No completed batches found.",
                  style: TextStyle(color: AppTheme.outline),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completedBags.length,
              separatorBuilder: (context, i) =>
                  const Divider(height: 1, color: AppTheme.outlineVariant),
              itemBuilder: (context, index) {
                final bag = completedBags[index];
                final bagNum = getBagNumber(bag);
                final profit = getBagProfit(bag);
                final endDateStr = bag.endDate ?? "N/A";

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryContainer.withValues(alpha: 0.1),
                    radius: 20.0,
                    child: const Icon(
                      Icons.shopping_bag,
                      color: AppTheme.primary,
                      size: 20.0,
                    ),
                  ),
                  title: Text(
                    "Batch #$bagNum",
                    style: AppTheme.labelBold.copyWith(fontSize: 15.0),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${bag.totalKg.toStringAsFixed(0)} KG",
                        style: AppTheme.labelSm.copyWith(color: AppTheme.outline),
                      ),
                      Text(
                        "Completed: $endDateStr",
                        style: AppTheme.labelSm.copyWith(color: AppTheme.outline),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${profit.toStringAsFixed(0)}",
                            style: AppTheme.dataTabular.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                              color: profit >= 0 ? AppTheme.success : AppTheme.error,
                            ),
                          ),
                          Text(
                            "PROFIT",
                            style: AppTheme.labelSm.copyWith(
                              fontSize: 8.0,
                              color: profit >= 0 ? AppTheme.success : AppTheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8.0),
                      const Icon(Icons.chevron_right, color: AppTheme.outline, size: 20.0),
                    ],
                  ),
                  onTap: () => onBagTap(bag, bagNum),
                );
              },
            ),
    );
  }
}
