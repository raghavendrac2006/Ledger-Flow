import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../core/app_state.dart';
import '../widgets/bento_card.dart';
import '../widgets/custom_toast.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/empty_state_widget.dart';

class OwnerFinanceScreen extends StatefulWidget {
  const OwnerFinanceScreen({super.key});

  @override
  State<OwnerFinanceScreen> createState() => _OwnerFinanceScreenState();
}

class _OwnerFinanceScreenState extends State<OwnerFinanceScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _repaymentController = TextEditingController();

  bool _isNotesInitialized = false;
  bool _isSavingNotes = false;
  bool _isAddingRepayment = false;
  String? _repaymentError;

  @override
  void dispose() {
    _notesController.dispose();
    _repaymentController.dispose();
    super.dispose();
  }

  void _saveNotes(LedgerState state) async {
    final notes = _notesController.text;
    setState(() {
      _isSavingNotes = true;
    });

    try {
      await state.updateOwnerLoanNotes(notes);
      if (mounted) {
        CustomToast.showSuccess(context, "Notes Saved Successfully");
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, "Failed to Save Notes");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingNotes = false;
        });
      }
    }
  }

  void _addRepayment(LedgerState state) async {
    final amountText = _repaymentController.text.trim();
    if (amountText.isEmpty) {
      setState(() {
        _repaymentError = "Amount cannot be empty";
      });
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _repaymentError = "Enter a valid positive amount";
      });
      return;
    }

    setState(() {
      _repaymentError = null;
      _isAddingRepayment = true;
    });

    try {
      await state.addOwnerRepayment(amount);
      _repaymentController.clear();
      if (mounted) {
        CustomToast.showSuccess(context, "Repayment Recorded");
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, "Failed to Record Repayment");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingRepayment = false;
        });
      }
    }
  }

  void _showEditBorrowedDialog(LedgerState state, double currentTotal) {
    final controller = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
            final currentStr = currencyFormat.format(currentTotal);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                side: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
              ),
              backgroundColor: Colors.white,
              title: Text(
                "MANAGE CAPITAL",
                style: AppTheme.headlineMd.copyWith(fontSize: 18.0),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Current Capital: $currentStr",
                    style: AppTheme.labelSm.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTheme.bodyMd,
                    decoration: InputDecoration(
                      labelText: "Enter Amount (₹)",
                      labelStyle: AppTheme.labelSm,
                      errorText: errorText,
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setState(() {
                          errorText = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final valText = controller.text.trim();
                            final val = double.tryParse(valText);
                            if (val == null || val <= 0) {
                              setState(() {
                                errorText = "Enter a valid amount > 0";
                              });
                              return;
                            }
                            final newTotal = currentTotal + val;
                            Navigator.pop(context);
                            try {
                              await state.updateOwnerLoanTotalBorrowed(newTotal);
                              if (context.mounted) {
                                CustomToast.showSuccess(context, "Added ₹${val.toStringAsFixed(0)} to Capital");
                              }
                            } catch (e) {
                              if (context.mounted) {
                                CustomToast.showError(context, "Failed to update capital");
                              }
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: AppTheme.successContainer,
                            foregroundColor: AppTheme.onSuccessContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                          ),
                          child: const Text("ADD"),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final valText = controller.text.trim();
                            final val = double.tryParse(valText);
                            if (val == null || val <= 0) {
                              setState(() {
                                errorText = "Enter a valid amount > 0";
                              });
                              return;
                            }
                            final newTotal = (currentTotal - val).clamp(0.0, double.infinity);
                            Navigator.pop(context);
                            try {
                              await state.updateOwnerLoanTotalBorrowed(newTotal);
                              if (context.mounted) {
                                CustomToast.showSuccess(context, "Subtracted ₹${val.toStringAsFixed(0)} from Capital");
                              }
                            } catch (e) {
                              if (context.mounted) {
                                CustomToast.showError(context, "Failed to update capital");
                              }
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: AppTheme.errorContainer,
                            foregroundColor: AppTheme.onErrorContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                          ),
                          child: const Text("SUBTRACT"),
                        ),
                      ),
                    ],
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
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: TextButton(
                    onPressed: () async {
                      final valText = controller.text.trim();
                      if (valText.isEmpty) {
                        setState(() {
                          errorText = "Enter an amount to set";
                        });
                        return;
                      }
                      final val = double.tryParse(valText);
                      if (val == null || val < 0) {
                        setState(() {
                          errorText = "Enter a valid amount >= 0";
                        });
                        return;
                      }

                      Navigator.pop(context);
                      try {
                        await state.updateOwnerLoanTotalBorrowed(val);
                        if (context.mounted) {
                          CustomToast.showSuccess(context, "Capital set to ₹${val.toStringAsFixed(0)}");
                        }
                      } catch (e) {
                        if (context.mounted) {
                          CustomToast.showError(context, "Failed to set capital");
                        }
                      }
                    },
                    child: Text(
                      "SET TOTAL",
                      style: AppTheme.labelBold.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LedgerState>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    final loan = state.activeLoan;

    if (loan == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonCard(height: 24.0, width: 220.0),
                SizedBox(height: 16.0),
                SkeletonCard(height: 120.0),
                SizedBox(height: 24.0),
                SkeletonCard(height: 24.0, width: 160.0),
                SizedBox(height: 16.0),
                SkeletonCard(height: 200.0),
                SizedBox(height: 24.0),
                SkeletonCard(height: 24.0, width: 180.0),
                SizedBox(height: 16.0),
                SkeletonCard(height: 300.0),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isNotesInitialized) {
      _notesController.text = loan.notes;
      _isNotesInitialized = true;
    }

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final formattedTotal = currencyFormat.format(loan.totalBorrowed);
    final formattedRepaid = currencyFormat.format(loan.amountRepaid);
    final formattedRemaining = currencyFormat.format(loan.remainingBalance);

    Widget buildMetrics() {
      final widgets = [
        Expanded(
          child: BentoCard(
            onTap: () => _showEditBorrowedDialog(state, loan.totalBorrowed),
            padding: const EdgeInsets.all(16.0),
            backgroundColor: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "TOTAL CAPITAL BORROWED",
                      style: AppTheme.labelSm.copyWith(
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(Icons.edit_outlined, size: 16.0, color: AppTheme.primary),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  formattedTotal,
                  style: AppTheme.headlineLg.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isDesktop) const SizedBox(height: 16.0) else const SizedBox(width: 16.0),
        Expanded(
          child: BentoCard(
            padding: const EdgeInsets.all(16.0),
            backgroundColor: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TOTAL AMOUNT REPAID",
                  style: AppTheme.labelSm.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  formattedRepaid,
                  style: AppTheme.headlineLg.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isDesktop) const SizedBox(height: 16.0) else const SizedBox(width: 16.0),
        Expanded(
          child: BentoCard(
            padding: const EdgeInsets.all(16.0),
            backgroundColor: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "REMAINING BALANCE",
                  style: AppTheme.labelSm.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  formattedRemaining,
                  style: AppTheme.headlineLg.copyWith(
                    color: loan.remainingBalance > 0 ? AppTheme.error : AppTheme.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];

      if (isDesktop) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets,
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widgets.map((w) {
            if (w is Expanded) return w.child;
            return w;
          }).toList(),
        );
      }
    }

    Widget buildNotesSection() {
      return BentoCard(
        padding: const EdgeInsets.all(16.0),
        backgroundColor: AppTheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "FINANCIAL NOTES & LOGS",
                  style: AppTheme.labelBold.copyWith(
                    fontSize: 14.0,
                    color: AppTheme.primary,
                  ),
                ),
                if (_isSavingNotes)
                  const SizedBox(
                    width: 16.0,
                    height: 16.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0, color: AppTheme.primary),
                  ),
              ],
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _notesController,
              maxLines: 6,
              minLines: 3,
              style: AppTheme.bodyMd,
              decoration: InputDecoration(
                hintText: "Enter manual loan configurations, notes, or capital logs here...",
                hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.outline),
                filled: true,
                fillColor: AppTheme.background,
                contentPadding: const EdgeInsets.all(16.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _isSavingNotes ? null : () => _saveNotes(state),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              child: Text(
                "SAVE NOTES",
                style: AppTheme.labelBold.copyWith(color: Colors.white, letterSpacing: 1.2),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildRepaymentForm() {
      return BentoCard(
        padding: const EdgeInsets.all(16.0),
        backgroundColor: AppTheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "RECORD REPAYMENT INSTALLMENT",
              style: AppTheme.labelBold.copyWith(
                fontSize: 14.0,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _repaymentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTheme.bodyMd,
              decoration: InputDecoration(
                labelText: "Repayment Amount (₹)",
                labelStyle: AppTheme.labelSm,
                hintText: "e.g., 5000",
                errorText: _repaymentError,
                filled: true,
                fillColor: AppTheme.background,
                contentPadding: const EdgeInsets.all(16.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
              onChanged: (_) {
                if (_repaymentError != null) {
                  setState(() {
                    _repaymentError = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _isAddingRepayment ? null : () => _addRepayment(state),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              child: _isAddingRepayment
                  ? const SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
                    )
                  : Text(
                      "RECORD PAYMENT",
                      style: AppTheme.labelBold.copyWith(color: Colors.white, letterSpacing: 1.2),
                    ),
            ),
          ],
        ),
      );
    }

    Widget buildRepaymentHistory() {
      final logs = state.repaymentLogs;

      return BentoCard(
        padding: const EdgeInsets.all(16.0),
        backgroundColor: AppTheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "REPAYMENT TRANSACTION HISTORY",
              style: AppTheme.labelBold.copyWith(
                fontSize: 14.0,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16.0),
            if (logs.isEmpty)
              const EmptyStateWidget(
                title: "No Repayments Found",
                message: "Logs of installments will appear here.",
                icon: Icons.history_edu,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.outlineVariant),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(log.repaymentDate);
                  final formattedAmt = currencyFormat.format(log.amountPaid);

                  return AnimatedListItem(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 36.0,
                            height: 36.0,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_upward,
                              color: AppTheme.primary,
                              size: 18.0,
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Installment Payment",
                                  style: AppTheme.labelBold.copyWith(fontSize: 14.0),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  formattedDate,
                                  style: AppTheme.labelSm.copyWith(fontSize: 11.0),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formattedAmt,
                            style: AppTheme.dataTabular.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "OWNER CAPITAL LOAN LEDGER",
                style: AppTheme.labelBold.copyWith(
                  fontSize: 11.0,
                  color: AppTheme.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16.0),
              buildMetrics(),
              const SizedBox(height: 24.0),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: buildNotesSection()),
                    const SizedBox(width: 24.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buildRepaymentForm(),
                          const SizedBox(height: 24.0),
                          buildRepaymentHistory(),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                buildNotesSection(),
                const SizedBox(height: 24.0),
                buildRepaymentForm(),
                const SizedBox(height: 24.0),
                buildRepaymentHistory(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
