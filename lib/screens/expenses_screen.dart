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

  String _selectedCategory = "Cylinders"; // Default to Cylinders
  bool _isSaving = false;

  // Search/Autocomplete Overlay controllers for standard expenses
  final FocusNode _itemFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();
  final LayerLink _expenseLayerLink = LayerLink();
  bool _showSuggestions = false;
  String _itemSearchQuery = "";

  final List<String> _expenseItemsList = [
    "Gas Cylinder Commercial",
    "Gas Cylinder Domestic",
    "Petrol for Scooter",
    "Diesel for Auto",
    "Salt bag",
    "Vehicle Repair",
    "Delivery Box Roll",
    "Thread pack",
  ];



  // Separate Rice Flour Bag weight capacity inputs (Box 2)
  final TextEditingController _riceFlourKgController = TextEditingController();
  DateTime _riceFlourBagSelectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _itemController.addListener(() {
      setState(() {
        _itemSearchQuery = _itemController.text;
      });
    });
  }

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
                          : "Cylinders";
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
      _selectedCategory = "Cylinders";
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

    final bool itemExists = _expenseItemsList.any((i) => i.toLowerCase() == item.toLowerCase());
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
                onPressed: () {
                  setState(() {
                    _expenseItemsList.add(itemName);
                  });
                  Navigator.pop(context);
                  _submitExpenseConfirmed(state, itemName, amount);
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
      case "Rice Flour":
        return const Color(0xFF6B4E3D);
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
      case "Rice Flour":
        return Icons.scale;
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

    final filteredItems = _expenseItemsList
        .where((item) => item.toLowerCase().contains(_itemSearchQuery.toLowerCase()))
        .toList();

    // Calculate percentage ratios for the custom bar progress meter
    final rawPercent = total > 0 ? raw / total : 0.0;
    final cylPercent = total > 0 ? cyl / total : 0.0;
    final transPercent = total > 0 ? trans / total : 0.0;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
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
                                child: Container(color: const Color(0xFF6B4E3D)),
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
                        _buildCategoryLegend("Rice Flour", raw, const Color(0xFF6B4E3D)),
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
                          ...state.expenseCategories
                              .where((cat) => !cat.toLowerCase().contains("rice"))
                              .map((cat) {
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

                    // Item Description text field wrapped with Autocomplete link target
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

                    // Amount spent input field
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

              // RICE FLOUR BAG INTAKE (BOX 2)
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
                    // Date selector
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

                    // Weight selector
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

                    // Start bag cycle button
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

            // 7. Autocomplete dropdown container overlay, placed at Stack level
            if (_showSuggestions && _itemSearchQuery.isNotEmpty && filteredItems.isNotEmpty)
              Positioned(
                child: CompositedTransformFollower(
                  link: _expenseLayerLink,
                  showWhenUnlinked: false,
                  offset: const Offset(0, 52.0), // Underneath the search textfield
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
