import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../core/models/expense_log.dart';
import 'bento_card.dart';

class RecentExpendituresListWidget extends StatelessWidget {
  final List<ExpenseLog> expenses;
  final void Function(ExpenseLog) onExpenseTap;

  const RecentExpendituresListWidget({
    super.key,
    required this.expenses,
    required this.onExpenseTap,
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

  IconData _getItemIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains("cylinder") || lower.contains("gas") || lower.contains("lpg")) {
      return Icons.propane_tank;
    }
    if (lower.contains("petrol") || lower.contains("diesel") || lower.contains("transport") || lower.contains("auto") || lower.contains("scooter") || lower.contains("vehicle")) {
      return Icons.local_shipping;
    }
    if (lower.contains("flour") || lower.contains("rice") || lower.contains("bag") || lower.contains("batch")) {
      return Icons.shopping_bag;
    }
    return Icons.receipt_long;
  }

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(0),
      backgroundColor: AppTheme.surface,
      shadowStyle: ShadowStyle.light,
      child: expenses.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  "No expenses recorded for this period.",
                  style: TextStyle(color: AppTheme.outline),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              separatorBuilder: (context, i) => const Divider(height: 1, color: AppTheme.outlineVariant),
              itemBuilder: (context, index) {
                final expense = expenses[index];
                String formattedTxDate = "";
                try {
                  formattedTxDate = DateFormat('dd MMM yyyy').format(DateTime.parse(expense.date));
                } catch (_) {
                  formattedTxDate = expense.date;
                }

                return ListTile(
                  onTap: () => onExpenseTap(expense),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getItemColor(expense.itemName).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getItemColor(expense.itemName),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _getItemIcon(expense.itemName),
                      color: _getItemColor(expense.itemName),
                      size: 18.0,
                    ),
                  ),
                  title: Text(
                    expense.itemName,
                    style: AppTheme.labelBold.copyWith(fontSize: 14.0),
                  ),
                  subtitle: Text(
                    formattedTxDate,
                    style: AppTheme.labelSm.copyWith(fontSize: 10),
                  ),
                  trailing: Text(
                    "₹${expense.amount.toStringAsFixed(0)}",
                    style: AppTheme.dataTabular.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
