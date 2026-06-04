import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../core/app_state.dart';
import '../core/models/models.dart';
import '../widgets/bento_card.dart';
import '../widgets/custom_toast.dart';
import '../widgets/recent_expenditures_list_widget.dart';
import '../widgets/total_expenditure_stats_widget.dart';
import '../widgets/skeleton_card.dart';

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

  String? _itemError;
  String? _amountError;
  String? _riceFlourKgError;

  @override
  void initState() {
    super.initState();
    _itemController.addListener(() {
      setState(() {
        _itemSearchQuery = _itemController.text;
      });
      _validateItem(_itemController.text);
    });
    _amountController.addListener(() {
      _validateAmount(_amountController.text);
    });
    _riceFlourKgController.addListener(() {
      _validateRiceFlourKg(_riceFlourKgController.text);
    });
  }

  void _validateItem(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _itemError = "Expense details cannot be empty";
      });
    } else {
      setState(() {
        _itemError = null;
      });
    }
  }

  void _validateAmount(String value) {
    final amt = double.tryParse(value.trim());
    if (value.trim().isEmpty) {
      setState(() {
        _amountError = "Amount cannot be empty";
      });
    } else if (amt == null || amt <= 0) {
      setState(() {
        _amountError = "Enter a valid positive amount";
      });
    } else {
      setState(() {
        _amountError = null;
      });
    }
  }

  void _validateRiceFlourKg(String value) {
    final kg = double.tryParse(value.trim());
    if (value.trim().isEmpty) {
      setState(() {
        _riceFlourKgError = "Bag weight capacity cannot be empty";
      });
    } else if (kg == null || kg <= 0) {
      setState(() {
        _riceFlourKgError = "Enter a valid positive weight";
      });
    } else {
      setState(() {
        _riceFlourKgError = null;
      });
    }
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
      _itemError = null;
      _amountError = null;
    });
    _itemFocusNode.unfocus();
    _amountFocusNode.unfocus();
  }

  void _submitExpense(LedgerState state) {
    final item = _itemController.text.trim();
    final amountText = _amountController.text.trim();

    _validateItem(item);
    _validateAmount(amountText);

    if (_itemError != null || _amountError != null) {
      return;
    }

    final amount = double.parse(amountText);

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
            side: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
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
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
                    borderSide: BorderSide(color: AppTheme.primary, width: 2.0),
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
                  prefixIcon: const Icon(Icons.currency_rupee, color: AppTheme.onSurface),
                  filled: true,
                  fillColor: AppTheme.surface,
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primary, width: 2.0),
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
                      onTap: () async {
                        final confirm = await CustomToast.showDestructiveConfirmation(
                          context,
                          title: "DELETE EXPENSE?",
                          message: "Are you sure you want to permanently delete this expense of ₹${expense.amount.toStringAsFixed(0)} for '${expense.itemName}'?",
                          confirmLabel: "DELETE",
                        );
                        if (confirm && context.mounted) {
                          Navigator.pop(context); // Close sheet
                          await state.deleteExpense(expenseId);
                          if (context.mounted) {
                            CustomToast.showSuccess(
                              context,
                              "EXPENSE DELETED",
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
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
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      labelStyle: AppTheme.labelBold.copyWith(
        fontSize: 12.0,
        color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
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

    final filteredItems = state.expenseSuggestions
        .where((item) => item.toLowerCase().contains(_itemSearchQuery.toLowerCase()))
        .toList();

    // Sort by historical frequency in state.expenses (predictive autocomplete)
    final Map<String, int> expenseFrequency = {};
    for (var exp in state.expenses) {
      final nameLower = exp.itemName.toLowerCase();
      expenseFrequency[nameLower] = (expenseFrequency[nameLower] ?? 0) + 1;
    }
    filteredItems.sort((a, b) {
      final freqA = expenseFrequency[a.toLowerCase()] ?? 0;
      final freqB = expenseFrequency[b.toLowerCase()] ?? 0;
      return freqB.compareTo(freqA);
    });

    return Scaffold(
      body: SafeArea(
        child: state.isLoading
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonCard(height: 24.0, width: 180.0),
                    const SizedBox(height: 16.0),
                    const SkeletonCard(height: 250.0),
                    const SizedBox(height: 32.0),
                    const SkeletonCard(height: 24.0, width: 220.0),
                    const SizedBox(height: 16.0),
                    const SkeletonCard(height: 220.0),
                    const SizedBox(height: 32.0),
                    const SkeletonCard(height: 24.0, width: 140.0),
                    const SizedBox(height: 16.0),
                    const SkeletonCard(height: 200.0),
                  ],
                ),
              )
            : Stack(
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
                  const SizedBox(height: 16.0),

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
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) {
                                FocusScope.of(context).requestFocus(_amountFocusNode);
                              },
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
                                errorText: _itemError,
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppTheme.primary, width: 2.0),
                                ),
                                errorBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppTheme.error, width: 1.5),
                                ),
                                focusedErrorBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppTheme.error, width: 2.0),
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
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppTheme.outlineVariant, width: 1.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppTheme.primary, size: 20),
                                const SizedBox(width: 16.0),
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submitExpense(state),
                          decoration: InputDecoration(
                            labelText: "AMOUNT SPENT (₹)",
                            labelStyle: AppTheme.labelBold.copyWith(fontSize: 10, color: AppTheme.outline),
                            hintText: "0.00",
                            prefixIcon: const Icon(Icons.currency_rupee, color: AppTheme.onSurface),
                            filled: true,
                            fillColor: AppTheme.surface,
                            errorText: _amountError,
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.primary, width: 2.0),
                            ),
                            errorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.error, width: 1.5),
                            ),
                            focusedErrorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.error, width: 2.0),
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
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              boxShadow: !_isSaving ? AppTheme.hardShadowButton : null,
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
                  const SizedBox(height: 16.0),

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
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppTheme.outlineVariant, width: 1.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppTheme.primary, size: 20),
                                const SizedBox(width: 16.0),
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submitRiceFlourWeight(state),
                          decoration: InputDecoration(
                            labelText: "BAG SIZE / WEIGHT CAPACITY (KG)",
                            labelStyle: AppTheme.labelBold.copyWith(fontSize: 10, color: AppTheme.outline),
                            hintText: "e.g., 30, 45, 60...",
                            suffixText: "KG",
                            suffixStyle: AppTheme.labelBold.copyWith(color: AppTheme.onSurface),
                            filled: true,
                            fillColor: AppTheme.surface,
                            errorText: _riceFlourKgError,
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.primary, width: 2.0),
                            ),
                            errorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.error, width: 1.5),
                            ),
                            focusedErrorBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.error, width: 2.0),
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
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              boxShadow: !_isSaving ? AppTheme.hardShadowButton : null,
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
                  const SizedBox(height: 16.0),

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
                  const SizedBox(height: 16.0),

                  RecentExpendituresListWidget(
                    expenses: filteredExpenses,
                    onExpenseTap: (expense) => _showEditExpenseBottomSheet(context, expense, state),
                  ),
                  const SizedBox(height: 32.0),

                  TotalExpenditureStatsWidget(
                    expenses: state.expenses,
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
    _validateRiceFlourKg(kgText);

    if (_riceFlourKgError != null) {
      return;
    }

    final kg = double.parse(kgText);

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

}

enum ExpenseFilter { all, today, thisWeek, thisMonth, custom }

