import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../core/app_state.dart';
import '../widgets/bento_card.dart';
import '../widgets/custom_toast.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  bool _isSaving = false;

  // Search/Autocomplete Overlay controllers for standard expenses
  final FocusNode _itemFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();
  final LayerLink _expenseLayerLink = LayerLink();
  bool _showSuggestions = false;
  String _itemSearchQuery = "";

  // Separate Rice Flour Bag weight capacity inputs (Box 2)
  final TextEditingController _riceFlourKgController = TextEditingController();
  DateTime _riceFlourBagSelectedDate = DateTime.now();

  // New Date Filters state
  ExpenseFilter _currentFilter = ExpenseFilter.today;
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _itemController.addListener(() {
      setState(() {
        _itemSearchQuery = _itemController.text;
      });
    });
  }

  @override
  void dispose() {
    _itemController.dispose();
    _amountController.dispose();
    _riceFlourKgController.dispose();
    _itemFocusNode.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearForm() {
    _itemController.clear();
    _amountController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _showSuggestions = false;
      _itemSearchQuery = "";
    });
    _itemFocusNode.unfocus();
    _amountFocusNode.unfocus();
  }

  void _submitExpense(LedgerState state) {
    final item = _itemController.text.trim();
    final amountText = _amountController.text.trim();

    if (item.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter expense details.")),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid expense amount.")),
      );
      return;
    }

    final bool itemExists = state.expenseSuggestions.any((i) => i.toLowerCase() == item.toLowerCase());
    if (!itemExists) {
      _showAddExpenseItemDialog(context, state, item, amount);
      return;
    }

    _submitExpenseConfirmed(state, item, amount);
  }

  void _showAddExpenseItemDialog(BuildContext context, LedgerState state, String itemName, double amount) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            side: const BorderSide(color: Colors.black, width: 2.5),
          ),
          backgroundColor: Colors.white,
          title: Text(
            "ADD TO EXPENSE LIST?",
            style: AppTheme.headlineMd.copyWith(fontSize: 18.0),
          ),
          content: Text(
            "'$itemName' is not in your expense quick list. Would you like to add it permanently?",
            style: AppTheme.bodyMd,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _submitExpenseConfirmed(state, itemName, amount);
              },
              child: Text(
                "NO",
                style: AppTheme.labelBold.copyWith(color: AppTheme.outline),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: TextButton(
                onPressed: () async {
                  await state.addExpenseSuggestion(itemName);
                  if (context.mounted) {
                    Navigator.pop(context);
                    _submitExpenseConfirmed(state, itemName, amount);
                  }
                },
                child: Text(
                  "YES",
                  style: AppTheme.labelBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _submitExpenseConfirmed(LedgerState state, String item, double amount) {
    setState(() {
      _isSaving = true;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

        state.addExpense(
          itemName: item,
          category: "General",
          amount: amount,
          date: dateStr,
        );

        CustomToast.showSuccess(
          context,
          "EXPENSE SAVED: ₹${amount.toStringAsFixed(0)}",
        );

        _clearForm();
        setState(() {
          _isSaving = false;
        });
      }
    });
  }

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

  void _showEditExpenseBottomSheet(BuildContext context, ExpenseLog expense, LedgerState state) {
    final TextEditingController editItemController = TextEditingController(text: expense.itemName);
    final TextEditingController editAmountController = TextEditingController(text: expense.amount.toStringAsFixed(0));
    final String? expenseId = expense.expenseId;

    if (expenseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot edit this expense because it lacks a unique ID.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Bar Handle
              Center(
                child: Container(
                  width: 40.0,
                  height: 5.0,
                  decoration: BoxDecoration(
                    color: AppTheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),

              // Title Header
              Text(
                "EDIT EXPENSE DETAILS",
                style: AppTheme.headlineMd.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20.0),

              // Item Name field
              TextField(
                controller: editItemController,
                decoration: InputDecoration(
                  labelText: "EXPENSE DETAILS / ITEM NAME",
                  labelStyle: AppTheme.labelBold.copyWith(fontSize: 10, color: AppTheme.outline),
                  filled: true,
                  fillColor: AppTheme.surface,
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
                style: AppTheme.bodyLg,
              ),
              const SizedBox(height: 16.0),

              // Amount Spent field
              TextField(
                controller: editAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "AMOUNT SPENT (₹)",
                  labelStyle: AppTheme.labelBold.copyWith(fontSize: 10, color: AppTheme.outline),
                  prefixIcon: const Icon(Icons.currency_rupee, color: Colors.black),
                  filled: true,
                  fillColor: AppTheme.surface,
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
                style: AppTheme.headlineMd.copyWith(fontSize: 20.0),
              ),
              const SizedBox(height: 24.0),

              // Action Buttons: Delete and Save
              Row(
                children: [
                  // Delete Button
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        // Confirm deletion dialog
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              side: const BorderSide(color: Colors.black, width: 2.5),
                            ),
                            backgroundColor: Colors.white,
                            title: Text(
                              "DELETE EXPENSE?",
                              style: AppTheme.headlineMd.copyWith(fontSize: 18.0, color: AppTheme.error),
                            ),
                            content: Text(
                              "Are you sure you want to permanently delete this expense of ₹${expense.amount.toStringAsFixed(0)} for '${expense.itemName}'?",
                              style: AppTheme.bodyMd,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  "CANCEL",
                                  style: AppTheme.labelBold.copyWith(color: AppTheme.outline),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.error,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  border: Border.all(color: Colors.black, width: 1.5),
                                ),
                                child: TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx); // Close dialog
                                    Navigator.pop(context); // Close sheet
                                    await state.deleteExpense(expenseId);
                                    if (context.mounted) {
                                      CustomToast.showSuccess(
                                        context,
                                        "EXPENSE DELETED",
                                      );
                                    }
                                  },
                                  child: Text(
                                    "DELETE",
                                    style: AppTheme.labelBold.copyWith(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            "DELETE",
                            style: AppTheme.labelBold.copyWith(
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),

                  // Save Button
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final newItem = editItemController.text.trim();
                        final newAmountText = editAmountController.text.trim();

                        if (newItem.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please enter expense details.")),
                          );
                          return;
                        }

                        final newAmount = double.tryParse(newAmountText);
                        if (newAmount == null || newAmount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please enter a valid amount.")),
                          );
                          return;
                        }

                        Navigator.pop(context); // Close sheet
                        await state.updateExpense(
                          expenseId: expenseId,
                          newItemName: newItem,
                          newAmount: newAmount,
                        );

                        if (context.mounted) {
                          CustomToast.showSuccess(
                            context,
                            "EXPENSE DETAILS UPDATED",
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            "SAVE CHANGES",
                            style: AppTheme.labelBold.copyWith(
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<ExpenseLog> _getFilteredExpenses(List<ExpenseLog> allExpenses) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_currentFilter) {
      case ExpenseFilter.all:
        return allExpenses;

      case ExpenseFilter.today:
        return allExpenses.where((exp) {
          try {
            final date = DateTime.parse(exp.date);
            return date.year == today.year && date.month == today.month && date.day == today.day;
          } catch (_) {
            return false;
          }
        }).toList();

      case ExpenseFilter.thisWeek:
        final startOfWeek = today.subtract(const Duration(days: 7));
        return allExpenses.where((exp) {
          try {
            final date = DateTime.parse(exp.date);
            return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
          } catch (_) {
            return false;
          }
        }).toList();

      case ExpenseFilter.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return allExpenses.where((exp) {
          try {
            final date = DateTime.parse(exp.date);
            return date.isAfter(startOfMonth.subtract(const Duration(seconds: 1)));
          } catch (_) {
            return false;
          }
        }).toList();

      case ExpenseFilter.custom:
        if (_customDateRange == null) return allExpenses;
        final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
        final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
        return allExpenses.where((exp) {
          try {
            final date = DateTime.parse(exp.date);
            return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
                   date.isBefore(end.add(const Duration(seconds: 1)));
          } catch (_) {
            return false;
          }
        }).toList();
    }
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _currentFilter = ExpenseFilter.custom;
      });
    } else if (_customDateRange == null) {
      setState(() {
        _currentFilter = ExpenseFilter.today;
      });
    }
  }

  Widget _buildFilterChip(String label, ExpenseFilter filter) {
    final isSelected = _currentFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (filter == ExpenseFilter.custom) {
          _selectCustomDateRange(context);
        } else {
          setState(() {
            _currentFilter = filter;
          });
        }
      },
      selectedColor: Colors.black,
      backgroundColor: AppTheme.surface,
      labelStyle: AppTheme.labelBold.copyWith(
        fontSize: 12.0,
        color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        side: BorderSide(
          color: isSelected ? Colors.black : AppTheme.outlineVariant,
          width: 1.5,
        ),
      ),
      showCheckmark: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LedgerState>(context);
    final filteredExpenses = _getFilteredExpenses(state.expenses);
    final total = state.expenses.fold<double>(0.0, (sum, exp) => sum + exp.amount);

    // Group expenditures by item name for breakdown
    final Map<String, double> itemTotals = {};
    for (var exp in state.expenses) {
      final name = exp.itemName.trim();
      if (name.isNotEmpty) {
        itemTotals[name] = (itemTotals[name] ?? 0.0) + exp.amount;
      }
    }

    // Sort item totals descending
    final sortedItems = itemTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get top 3 items for existing stats bar
    final top3 = sortedItems.take(3).toList();

    // Group for Top Expense Breakdown (Top 3 + Others)
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

    final filteredItems = state.expenseSuggestions
        .where((item) => item.toLowerCase().contains(_itemSearchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. RECORD NEW EXPENDITURE TITLE & FORM
                  Text(
                    "RECORD NEW EXPENDITURE",
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
                        CompositedTransformTarget(
                          link: _expenseLayerLink,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: _itemFocusNode.hasFocus ? AppTheme.hardShadowLight : null,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: TextField(
                              controller: _itemController,
                              focusNode: _itemFocusNode,
                              onTap: () {
                                setState(() {
                                  _showSuggestions = true;
                                });
                              },
                              onChanged: (text) {
                                setState(() {
                                  _showSuggestions = true;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: "EXPENSE DETAILS / ITEM NAME",
                                labelStyle: AppTheme.labelBold.copyWith(fontSize: 10, color: AppTheme.outline),
                                hintText: "e.g., Gas Cylinder Commercial...",
                                hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.outline),
                                filled: true,
                                fillColor: AppTheme.surface,
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black, width: 2.0),
                                ),
                              ),
                              style: AppTheme.bodyLg,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppTheme.outlineVariant, width: 1.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppTheme.primary, size: 20),
                                const SizedBox(width: 12.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "DATE OF TRANSACTION",
                                      style: AppTheme.labelBold.copyWith(fontSize: 9, color: AppTheme.outline),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      DateFormat('dd MMMM yyyy').format(_selectedDate),
                                      style: AppTheme.labelBold.copyWith(fontSize: 14.0),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Icon(Icons.chevron_right, color: AppTheme.outline),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        TextField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "AMOUNT SPENT (₹)",
                            labelStyle: AppTheme.labelBold.copyWith(fontSize: 10, color: AppTheme.outline),
                            hintText: "0.00",
                            prefixIcon: const Icon(Icons.currency_rupee, color: Colors.black),
                            filled: true,
                            fillColor: AppTheme.surface,
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black, width: 2.0),
                            ),
                          ),
                          style: AppTheme.headlineMd.copyWith(fontSize: 20.0),
                        ),
                        const SizedBox(height: 24.0),

                        InkWell(
                          onTap: _isSaving ? null : () => _submitExpense(state),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: Colors.black, width: 1.5),
                            ),
                            child: Center(
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.0,
                                      ),
                                    )
                                  : Text(
                                      "LOG EXPENDITURE",
                                      style: AppTheme.labelBold.copyWith(
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32.0),

                  // 2. RECORD RICE FLOUR BAG WEIGHT TITLE & FORM
                  Text(
                    "RECORD RICE FLOUR BAG WEIGHT (KG)",
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
                        InkWell(
                          onTap: () => _selectRiceFlourBagDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppTheme.outlineVariant, width: 1.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppTheme.primary, size: 20),
                                const SizedBox(width: 12.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "DATE BAG WAS STARTED",
                                      style: AppTheme.labelBold.copyWith(fontSize: 9, color: AppTheme.outline),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      DateFormat('dd MMMM yyyy').format(_riceFlourBagSelectedDate),
                                      style: AppTheme.labelBold.copyWith(fontSize: 14.0),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Icon(Icons.chevron_right, color: AppTheme.outline),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),

                        TextField(
                          controller: _riceFlourKgController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: "BAG SIZE / WEIGHT CAPACITY (KG)",
                            labelStyle: AppTheme.labelBold.copyWith(fontSize: 10, color: AppTheme.outline),
                            hintText: "e.g., 30, 45, 60...",
                            suffixText: "KG",
                            suffixStyle: AppTheme.labelBold.copyWith(color: Colors.black),
                            filled: true,
                            fillColor: AppTheme.surface,
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black, width: 2.0),
                            ),
                          ),
                          style: AppTheme.headlineMd.copyWith(fontSize: 20.0),
                        ),
                        const SizedBox(height: 24.0),

                        InkWell(
                          onTap: _isSaving ? null : () => _submitRiceFlourWeight(state),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: Colors.black, width: 1.5),
                            ),
                            child: Center(
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.0,
                                      ),
                                    )
                                  : Text(
                                      "START NEW BAG CYCLE",
                                      style: AppTheme.labelBold.copyWith(
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32.0),

                  // 3. RECENT EXPENDITURES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "RECENT EXPENDITURES",
                        style: AppTheme.labelBold.copyWith(
                          fontSize: 11.0,
                          color: AppTheme.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        "${filteredExpenses.length} FOUND",
                        style: AppTheme.labelBold.copyWith(fontSize: 10.0, color: AppTheme.outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),

                  // Date Filters Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip("All", ExpenseFilter.all),
                        const SizedBox(width: 8.0),
                        _buildFilterChip("Today", ExpenseFilter.today),
                        const SizedBox(width: 8.0),
                        _buildFilterChip("This Week", ExpenseFilter.thisWeek),
                        const SizedBox(width: 8.0),
                        _buildFilterChip("This Month", ExpenseFilter.thisMonth),
                        const SizedBox(width: 8.0),
                        _buildFilterChip(
                          _customDateRange == null
                              ? "Custom Range"
                              : "${DateFormat('dd MMM').format(_customDateRange!.start)} - ${DateFormat('dd MMM').format(_customDateRange!.end)}",
                          ExpenseFilter.custom,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  BentoCard(
                    padding: const EdgeInsets.all(0),
                    backgroundColor: AppTheme.surface,
                    shadowStyle: ShadowStyle.light,
                    child: filteredExpenses.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: Text("No expenses recorded for this period.")),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredExpenses.length,
                            separatorBuilder: (context, i) => const Divider(height: 1, color: AppTheme.outlineVariant),
                            itemBuilder: (context, index) {
                              final expense = filteredExpenses[index];
                              final formattedTxDate = DateFormat('dd MMM yyyy').format(DateTime.parse(expense.date));

                              return ListTile(
                                onTap: () => _showEditExpenseBottomSheet(context, expense, state),
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
                  ),
                  const SizedBox(height: 32.0),

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

                  // 5. TOP EXPENSE BREAKDOWN (NEW SECTION)
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
              ),
            ),

            // Autocomplete suggestions
            if (_showSuggestions && _itemSearchQuery.isNotEmpty && filteredItems.isNotEmpty)
              Positioned(
                child: CompositedTransformFollower(
                  link: _expenseLayerLink,
                  showWhenUnlinked: false,
                  offset: const Offset(0, 52.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 48,
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2.0),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Material(
                        elevation: 0,
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        clipBehavior: Clip.antiAlias,
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: filteredItems.length,
                          separatorBuilder: (context, i) => const Divider(height: 1, color: AppTheme.outlineVariant),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                item,
                                style: AppTheme.labelBold,
                              ),
                              onTap: () {
                                _itemController.text = item;
                                _itemFocusNode.unfocus();
                                setState(() {
                                  _showSuggestions = false;
                                });
                                FocusScope.of(context).requestFocus(_amountFocusNode);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectRiceFlourBagDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _riceFlourBagSelectedDate,
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
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _riceFlourBagSelectedDate) {
      setState(() {
        _riceFlourBagSelectedDate = picked;
      });
    }
  }

  void _submitRiceFlourWeight(LedgerState state) {
    final kgText = _riceFlourKgController.text.trim();
    final kg = double.tryParse(kgText);

    if (kg == null || kg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid weight capacity (KG).")),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        final dateStr = DateFormat('dd MMMM yyyy').format(_riceFlourBagSelectedDate);

        state.closeAndStartNewBag(totalKg: kg, date: dateStr);

        CustomToast.showSuccess(context, "NEW FLOUR BAG LOADED: ${kg.toStringAsFixed(0)} KG");
        _riceFlourKgController.clear();
        setState(() {
          _isSaving = false;
        });
      }
    });
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

enum ExpenseFilter { all, today, thisWeek, thisMonth, custom }
