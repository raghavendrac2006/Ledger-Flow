import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/app_state.dart';
import '../widgets/bento_card.dart';
import '../widgets/custom_toast.dart';

class CustomerProfileScreen extends StatelessWidget {
  final String customerName;

  const CustomerProfileScreen({
    super.key,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LedgerState>(context);

    // Find the customer details from state list
    final customerIndex = state.customers.indexWhere((c) => c.name == customerName);
    if (customerIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Customer not found.")),
      );
    }
    final customer = state.customers[customerIndex];
    final transactions = state.getTransactionsForCustomer(customerName);

    final hasDebt = customer.outstanding > 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Customer Profile",
          style: AppTheme.headlineMd.copyWith(color: AppTheme.primary, fontSize: 18.0),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
            color: AppTheme.outlineVariant,
            height: 1.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Info Card
              BentoCard(
                padding: const EdgeInsets.all(20.0),
                backgroundColor: AppTheme.surface,
                shadowStyle: ShadowStyle.heavy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.surfaceContainerHighest,
                          radius: 24.0,
                          child: Icon(customer.icon, color: AppTheme.primary, size: 24.0),
                        ),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name,
                                style: AppTheme.headlineLg.copyWith(fontSize: 22.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    const Divider(color: AppTheme.outlineVariant),
                  ],
                ),
              ),

              const SizedBox(height: 20.0),

              // 2. Outstanding Balance Banner Block (High Contrast Red/Green)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: hasDebt ? AppTheme.errorContainer : AppTheme.successContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: Colors.black, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasDebt ? "OUTSTANDING BALANCE DUE" : "SETTLED ACCOUNT BALANCE",
                      style: AppTheme.labelBold.copyWith(
                        fontSize: 10.0,
                        color: hasDebt ? AppTheme.onErrorContainer : AppTheme.onSuccessContainer,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      "₹${customer.outstanding.toStringAsFixed(2)}",
                      style: AppTheme.dataTabular.copyWith(
                        fontSize: 28.0,
                        fontWeight: FontWeight.w900,
                        color: hasDebt ? AppTheme.onErrorContainer : AppTheme.onSuccessContainer,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      hasDebt
                          ? "This customer has outstanding invoices that require cash collection rounds."
                          : "Outstanding balance fully settled. This customer is in good standing.",
                      style: AppTheme.labelSm.copyWith(
                        color: hasDebt
                            ? AppTheme.onErrorContainer.withValues(alpha: 0.8)
                            : AppTheme.onSuccessContainer.withValues(alpha: 0.8),
                        fontSize: 11.0,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36.0),

              // 3. Quick Actions
              Text(
                "ACCOUNT INTERACTIONS",
                style: AppTheme.labelBold.copyWith(
                  fontSize: 11.0,
                  color: AppTheme.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12.0),
              // Collect Cash Primary Action Button
              BentoCard(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                backgroundColor: AppTheme.primary,
                shadowStyle: ShadowStyle.heavy,
                onTap: () {
                  _showCollectCashBottomSheet(context, state, customer);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payments, color: Colors.white, size: 22.0),
                    const SizedBox(width: 12.0),
                    Text(
                      "COLLECT CASH / INSTALLMENT",
                      style: AppTheme.labelBold.copyWith(
                        color: Colors.white,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Expanded(
                    child: BentoCard(
                      padding: const EdgeInsets.all(12.0),
                      backgroundColor: AppTheme.surface,
                      shadowStyle: ShadowStyle.light,
                      onTap: () {
                        // Mock invoice share
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("PDF Invoice successfully compiled for outstanding amount!"),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.share, size: 18.0),
                          const SizedBox(width: 8.0),
                          Text("SHARE PDF", style: AppTheme.labelBold),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: BentoCard(
                      padding: const EdgeInsets.all(12.0),
                      backgroundColor: AppTheme.surface,
                      shadowStyle: ShadowStyle.light,
                      onTap: () {
                        // Return to Sales tab
                        Navigator.pop(context);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_shopping_cart, size: 18.0),
                          const SizedBox(width: 8.0),
                          Text("NEW ENTRY", style: AppTheme.labelBold),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36.0),

              // 4. Transaction History List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "TRANSACTION LEDGER HISTORY",
                    style: AppTheme.labelBold.copyWith(
                      fontSize: 11.0,
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    "${transactions.length} ITEMS",
                    style: AppTheme.labelBold.copyWith(fontSize: 10.0, color: AppTheme.outline),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),

              BentoCard(
                padding: const EdgeInsets.all(0),
                backgroundColor: AppTheme.surface,
                shadowStyle: ShadowStyle.light,
                child: transactions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text("No transaction history recorded yet."),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        separatorBuilder: (context, i) => const Divider(height: 1, color: AppTheme.outlineVariant),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final isPaid = tx.isPaid;
                          final isPayment = tx.isPayment;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onLongPress: () {
                                _showEditDeleteTransactionDialog(context, state, customer.name, index, tx);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                                child: Row(
                                  children: [
                                    // Left details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          isPayment
                                              ? Row(
                                                  children: [
                                                    const Icon(Icons.payments, size: 16.0, color: Color(0xFF2E7D32)),
                                                    const SizedBox(width: 6.0),
                                                    Text(
                                                      tx.details,
                                                      style: AppTheme.labelBold.copyWith(
                                                        fontSize: 14.0,
                                                        color: const Color(0xFF2E7D32),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Text(
                                                  tx.details,
                                                  style: AppTheme.labelBold.copyWith(fontSize: 14.0),
                                                ),
                                          const SizedBox(height: 2.0),
                                          Text(
                                            tx.date,
                                            style: AppTheme.labelSm.copyWith(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Amount & Paid Status
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          isPayment ? "-₹${tx.amount.toStringAsFixed(2)}" : "₹${tx.amount.toStringAsFixed(2)}",
                                          style: AppTheme.dataTabular.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15.0,
                                            color: isPayment
                                                ? const Color(0xFF2E7D32)
                                                : (isPaid ? Colors.black : AppTheme.error),
                                          ),
                                        ),
                                        const SizedBox(height: 4.0),
                                        isPayment
                                            ? Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.successContainer,
                                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                                  border: Border.all(color: const Color(0xFF2E7D32), width: 1.0),
                                                ),
                                                child: Text(
                                                  "RECEIVED",
                                                  style: AppTheme.labelBold.copyWith(
                                                    color: const Color(0xFF2E7D32),
                                                    fontSize: 8.0,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              )
                                            : (isPaid
                                                ? Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.successContainer,
                                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                                    ),
                                                    child: Text(
                                                      "PAID",
                                                      style: AppTheme.labelBold.copyWith(
                                                        color: AppTheme.onSuccessContainer,
                                                        fontSize: 8.0,
                                                      ),
                                                    ),
                                                  )
                                                : InkWell(
                                                    onTap: () {
                                                      state.markTransactionAsPaid(customer.name, index);
                                                      CustomToast.showSuccess(
                                                        context,
                                                        "COLLECTED ₹${tx.amount.toStringAsFixed(0)} FROM ${customer.name}",
                                                      );
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.errorContainer,
                                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                                        border: Border.all(color: Colors.black, width: 1.0),
                                                      ),
                                                      child: Text(
                                                        "MARK PAID",
                                                        style: AppTheme.labelBold.copyWith(
                                                          color: AppTheme.onErrorContainer,
                                                          fontSize: 8.0,
                                                          fontWeight: FontWeight.w900,
                                                        ),
                                                      ),
                                                    ),
                                                  )),
                                      ],
                                    ),
                                  ],
                                ),
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



  void _showEditDeleteTransactionDialog(
    BuildContext context,
    LedgerState state,
    String customerName,
    int index,
    Transaction tx,
  ) {
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
            "TRANSACTION ACTION",
            style: AppTheme.headlineMd.copyWith(fontSize: 18.0),
          ),
          content: Text(
            "Select an action for the transaction of ₹${tx.amount.toStringAsFixed(0)} on ${tx.date}.",
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
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(context, state, customerName, index, tx);
                },
                child: Text(
                  "DELETE",
                  style: AppTheme.labelBold.copyWith(color: Colors.white),
                ),
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
                  Navigator.pop(context);
                  _showEditTransactionDialog(context, state, customerName, index, tx);
                },
                child: Text(
                  "EDIT",
                  style: AppTheme.labelBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    LedgerState state,
    String customerName,
    int index,
    Transaction tx,
  ) {
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
            "PERMANENTLY DELETE?",
            style: AppTheme.headlineMd.copyWith(fontSize: 18.0, color: AppTheme.error),
          ),
          content: Text(
            "Are you sure you want to permanently delete this transaction for ₹${tx.amount.toStringAsFixed(0)}? This will adjust the customer outstanding balance and cannot be undone.",
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
                  state.deleteTransaction(customerName, index);
                  Navigator.pop(context);
                  CustomToast.showSuccess(context, "DELETED TRANSACTION");
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

  void _showEditTransactionDialog(
    BuildContext context,
    LedgerState state,
    String customerName,
    int index,
    Transaction tx,
  ) {
    final TextEditingController detailsCont = TextEditingController(text: tx.details);
    final TextEditingController amountCont = TextEditingController(text: tx.amount.toStringAsFixed(2));

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
            "EDIT TRANSACTION",
            style: AppTheme.headlineMd.copyWith(fontSize: 18.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: detailsCont,
                decoration: InputDecoration(
                  labelText: "TRANSACTION DETAILS",
                  labelStyle: AppTheme.labelBold.copyWith(fontSize: 10, color: AppTheme.outline),
                  hintText: "e.g., 1x Nippat...",
                ),
                style: AppTheme.bodyLg,
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: amountCont,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "AMOUNT (₹)",
                  labelStyle: AppTheme.labelBold.copyWith(fontSize: 10, color: AppTheme.outline),
                  hintText: "0.00",
                ),
                style: AppTheme.bodyLg,
              ),
            ],
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
                  final details = detailsCont.text.trim();
                  final amount = double.tryParse(amountCont.text.trim());
                  if (details.isNotEmpty && amount != null && amount >= 0) {
                    state.editTransaction(
                      customerName: customerName,
                      index: index,
                      newDetails: details,
                      newAmount: amount,
                    );
                    Navigator.pop(context);
                    CustomToast.showSuccess(context, "UPDATED TRANSACTION");
                  }
                },
                child: Text(
                  "SAVE CHANGES",
                  style: AppTheme.labelBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCollectCashBottomSheet(BuildContext context, LedgerState state, Customer customer) {
    final TextEditingController amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24.0,
                right: 24.0,
                top: 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Collect Cash - ${customer.name}",
                        style: AppTheme.headlineMd.copyWith(color: AppTheme.primary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    "OUTSTANDING DUE: ₹${customer.outstanding.toStringAsFixed(2)}",
                    style: AppTheme.labelBold.copyWith(
                      color: customer.outstanding > 0 ? AppTheme.error : AppTheme.onSurfaceVariant,
                      fontSize: 12.0,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Amount text field
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTheme.dataTabular.copyWith(fontSize: 24.0, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: "₹ ",
                      prefixStyle: AppTheme.headlineMd.copyWith(color: AppTheme.primary, fontSize: 24.0),
                      hintText: "0.00",
                      labelText: "Collection Amount",
                      labelStyle: AppTheme.labelBold,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(color: Colors.black, width: 2.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 2.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Quick chips: ₹100, ₹200, ₹500, ₹1000, "Settle All"
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickAmountChip(context, "₹100", 100.0, amountController),
                        const SizedBox(width: 8.0),
                        _buildQuickAmountChip(context, "₹200", 200.0, amountController),
                        const SizedBox(width: 8.0),
                        _buildQuickAmountChip(context, "₹500", 500.0, amountController),
                        const SizedBox(width: 8.0),
                        _buildQuickAmountChip(context, "₹1000", 1000.0, amountController),
                        if (customer.outstanding > 0) ...[
                          const SizedBox(width: 8.0),
                          ActionChip(
                            label: Text(
                              "Settle (₹${customer.outstanding.toStringAsFixed(0)})",
                              style: AppTheme.labelBold.copyWith(color: Colors.white, fontSize: 11.0),
                            ),
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              side: const BorderSide(color: Colors.black, width: 1.0),
                            ),
                            onPressed: () {
                              amountController.text = customer.outstanding.toStringAsFixed(2);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Date selector
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppTheme.primary,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.outlineVariant),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, color: AppTheme.primary, size: 20.0),
                              const SizedBox(width: 10.0),
                              Text(
                                "Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                                style: AppTheme.labelBold.copyWith(fontSize: 13.0),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppTheme.outline),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          side: const BorderSide(color: Colors.black, width: 2.0),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        final val = double.tryParse(amountController.text);
                        if (val == null || val <= 0.0) {
                          CustomToast.showError(context, "Please enter a valid cash amount");
                          return;
                        }

                        Navigator.pop(context);
                        
                        // Save installment in app state
                        await state.recordCustomerPayment(
                          customerName: customer.name,
                          amount: val,
                          date: selectedDate,
                        );

                        if (context.mounted) {
                          CustomToast.showSuccess(
                            context,
                            "Successfully collected ₹${val.toStringAsFixed(2)} installment!",
                          );
                        }
                      },
                      child: Text(
                        "SAVE INSTALLMENT PAYMENT",
                        style: AppTheme.labelBold.copyWith(
                          color: Colors.white,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickAmountChip(
    BuildContext context,
    String label,
    double amount,
    TextEditingController controller,
  ) {
    return ActionChip(
      label: Text(label, style: AppTheme.labelBold.copyWith(fontSize: 11.0)),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        side: const BorderSide(color: Colors.black, width: 1.0),
      ),
      onPressed: () {
        controller.text = amount.toStringAsFixed(2);
      },
    );
  }
}
