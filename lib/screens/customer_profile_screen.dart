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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    ),
                                    child: Text(
                                      customer.type,
                                      style: AppTheme.labelBold.copyWith(fontSize: 8.0, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successContainer,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    ),
                                    child: Text(
                                      customer.status.toUpperCase(),
                                      style: AppTheme.labelBold.copyWith(
                                        fontSize: 8.0,
                                        color: AppTheme.onSuccessContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6.0),
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
                    const SizedBox(height: 12.0),

                    // Metadata details
                    _buildMetaRow("LOCATION/SECTOR", customer.location),
                    const SizedBox(height: 8.0),
                    _buildMetaRow("MARKET AREA", customer.area),
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
                                          Text(
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
                                          "₹${tx.amount.toStringAsFixed(2)}",
                                          style: AppTheme.dataTabular.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15.0,
                                            color: isPaid ? Colors.black : AppTheme.error,
                                          ),
                                        ),
                                        const SizedBox(height: 4.0),
                                        isPaid
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
                                              ),
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

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.labelSm.copyWith(
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: AppTheme.labelBold.copyWith(
            fontSize: 12.0,
            color: Colors.black,
          ),
        ),
      ],
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
}
