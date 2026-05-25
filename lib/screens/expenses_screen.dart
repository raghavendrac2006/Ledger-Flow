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

  String _selectedCategory = "RICE";
  bool _isSaving = false;

  void _showAddCategoryDialog(BuildContext context, LedgerState state) {
    final TextEditingController catCont = TextEditingController();

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
            "NEW EXPENSE CATEGORY",
            style: AppTheme.headlineMd.copyWith(fontSize: 18.0),
          ),
          content: TextField(
            controller: catCont,
            decoration: InputDecoration(
              labelText: "CATEGORY NAME",
              labelStyle: AppTheme.labelBold.copyWith(fontSize: 10, color: AppTheme.outline),
              hintText: "e.g., Labor, Rent, Packaging...",
              hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.outline),
            ),
            style: AppTheme.bodyLg,
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
                color: Colors.black,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: TextButton(
                onPressed: () {
                  final cat = catCont.text.trim();
                  if (cat.isNotEmpty) {
                    state.addExpenseCategory(cat);
                    setState(() {
                      _selectedCategory = cat; // Auto-select new category
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  "ADD CATEGORY",
                  style: AppTheme.labelBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, LedgerState state, String category) {
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
            "DELETE CATEGORY?",
            style: AppTheme.headlineMd.copyWith(fontSize: 18.0, color: AppTheme.error),
          ),
          content: Text(
            "Are you sure you want to permanently delete the category '$category'? Any logged expenses under this category will remain, but the category chip will be removed.",
            style: AppTheme.bodyMd,
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
                color: AppTheme.error,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: TextButton(
                onPressed: () {
                  state.deleteExpenseCategory(category);
                  if (_selectedCategory == category) {
                    setState(() {
                      _selectedCategory = state.expenseCategories.isNotEmpty
                          ? state.expenseCategories.first
                          : "RICE";
                    });
                  }
                  Navigator.pop(context);
                  CustomToast.showSuccess(context, "DELETED CATEGORY: $category");
                },
                child: Text(
                  "DELETE",
                  style: AppTheme.labelBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _itemController.dispose();
    _amountController.dispose();
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
      _selectedCategory = "RICE";
    });
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

    setState(() {
      _isSaving = true;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

        state.addExpense(
          itemName: item,
          category: _selectedCategory,
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case "RICE":
        return AppTheme.primary;
      case "Cylinders":
        return AppTheme.secondary;
      case "Transportation":
        return AppTheme.tertiary;
      default:
        return AppTheme.onSurfaceVariant;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "RICE":
        return Icons.shopping_bag;
      case "Cylinders":
        return Icons.propane_tank;
      case "Transportation":
        return Icons.local_shipping;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LedgerState>(context);
    final total = state.totalExpenditure;
    final raw = state.riceExpenditure;
    final cyl = state.cylindersExpenditure;
    final trans = state.transportExpenditure;

    // Calculate percentage ratios for the custom bar progress meter
    final rawPercent = total > 0 ? raw / total : 0.0;
    final cylPercent = total > 0 ? cyl / total : 0.0;
    final transPercent = total > 0 ? trans / total : 0.0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Balance Header Bento Card
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

                    // Custom Multi-segment Bar Progress Indicator
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
                            if (rawPercent > 0)
                              Expanded(
                                flex: (rawPercent * 100).toInt(),
                                child: Container(color: AppTheme.primary),
                              ),
                            if (cylPercent > 0)
                              Expanded(
                                flex: (cylPercent * 100).toInt(),
                                child: Container(color: AppTheme.secondary),
                              ),
                            if (transPercent > 0)
                              Expanded(
                                flex: (transPercent * 100).toInt(),
                                child: Container(color: AppTheme.tertiary),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Metrics Grid Labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCategoryLegend("RICE", raw, AppTheme.primary),
                        _buildCategoryLegend("Cylinders", cyl, AppTheme.secondary),
                        _buildCategoryLegend("Transport", trans, AppTheme.tertiary),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32.0),

              // Logging Form Title
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
                    // Category Chips choice list
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...state.expenseCategories.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = cat;
                                  });
                                },
                                onLongPress: () {
                                  _showDeleteCategoryDialog(context, state, cat);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                                  decoration: BoxDecoration(
                                    color: isSelected ? _getCategoryColor(cat) : AppTheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    border: Border.all(
                                      color: isSelected ? Colors.black : AppTheme.outlineVariant,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getCategoryIcon(cat),
                                        color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                                        size: 14.0,
                                      ),
                                      const SizedBox(width: 6.0),
                                      Text(
                                        cat.toUpperCase(),
                                        style: AppTheme.labelBold.copyWith(
                                          fontSize: 10.0,
                                          color: isSelected ? Colors.white : AppTheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          // ADD CATEGORY "+" CHIP
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: InkWell(
                              onTap: () => _showAddCategoryDialog(context, state),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.add,
                                      color: Colors.black,
                                      size: 14.0,
                                    ),
                                    const SizedBox(width: 4.0),
                                    Text(
                                      "NEW",
                                      style: AppTheme.labelBold.copyWith(
                                        fontSize: 10.0,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Item Description text field
                    TextField(
                      controller: _itemController,
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
                    const SizedBox(height: 16.0),

                    // Date Picker Box
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

                    // Amount text field
                    TextField(
                      controller: _amountController,
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

                    // Action Add Button
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

              // Transaction List Header
              Text(
                "RECENT EXPENDITURES",
                style: AppTheme.labelBold.copyWith(
                  fontSize: 11.0,
                  color: AppTheme.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12.0),

              // Expenditures List
              BentoCard(
                padding: const EdgeInsets.all(0),
                backgroundColor: AppTheme.surface,
                shadowStyle: ShadowStyle.light,
                child: state.expenses.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: Text("No expenses recorded yet today.")),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.expenses.length,
                        separatorBuilder: (context, i) => const Divider(height: 1, color: AppTheme.outlineVariant),
                        itemBuilder: (context, index) {
                          final expense = state.expenses[index];
                          final formattedTxDate = DateFormat('dd MMM yyyy').format(DateTime.parse(expense.date));

                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(expense.category).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _getCategoryColor(expense.category),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                _getCategoryIcon(expense.category),
                                color: _getCategoryColor(expense.category),
                                size: 18.0,
                              ),
                            ),
                            title: Text(
                              expense.itemName,
                              style: AppTheme.labelBold.copyWith(fontSize: 14.0),
                            ),
                            subtitle: Text(
                              "${expense.category.toUpperCase()} • $formattedTxDate",
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
            ],
          ),
        ),
      ),
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
