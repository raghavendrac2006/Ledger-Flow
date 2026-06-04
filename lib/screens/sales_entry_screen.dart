import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/app_state.dart';
import '../widgets/bento_card.dart';
import '../widgets/custom_toast.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/animated_list_item.dart';

class SalesEntryScreen extends StatefulWidget {
  const SalesEntryScreen({super.key});

  @override
  State<SalesEntryScreen> createState() => _SalesEntryScreenState();
}

class _SalesEntryScreenState extends State<SalesEntryScreen> {
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _customerFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  bool _isPaid = true;
  bool _isSaving = false;
  String _searchQuery = "";
  bool _showSuggestions = false;

  String? _customerError;
  String? _amountError;

  final List<double> _quickAmounts = [100, 150, 200, 250, 300, 500, 800, 1000];

  @override
  void initState() {
    super.initState();
    _customerController.addListener(() {
      setState(() {
        _searchQuery = _customerController.text;
      });
      _validateCustomer(_customerController.text);
    });
    _amountController.addListener(() {
      _validateAmount(_amountController.text);
    });
  }

  void _validateCustomer(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _customerError = "Shop name cannot be empty";
      });
    } else {
      setState(() {
        _customerError = null;
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

  @override
  void dispose() {
    _customerController.dispose();
    _amountController.dispose();
    _customerFocusNode.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _clearForm() {
    _customerController.clear();
    _amountController.clear();
    setState(() {
      _isPaid = true;
      _searchQuery = "";
      _showSuggestions = false;
      _customerError = null;
      _amountError = null;
    });
    _customerFocusNode.unfocus();
    _amountFocusNode.unfocus();
  }

  void _submitDelivery(LedgerState state) {
    final customer = _customerController.text.trim();
    final amountText = _amountController.text.trim();

    _validateCustomer(customer);
    _validateAmount(amountText);

    if (_customerError != null || _amountError != null) {
      return;
    }

    final amount = double.parse(amountText);

    final bool customerExists = state.customers.any((c) => c.name.toLowerCase() == customer.toLowerCase());
    if (!customerExists) {
      _showAddCustomerDialog(context, state, customer, amount);
      return;
    }

    _submitDeliveryConfirmed(state, customer, amount);
  }

  void _showAddCustomerDialog(BuildContext context, LedgerState state, String customerName, double amount) {
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
            "ADD NEW CUSTOMER?",
            style: AppTheme.headlineMd.copyWith(fontSize: 18.0),
          ),
          content: Text(
            "'$customerName' is not in your customer list. Would you like to add them permanently or log this sale once?",
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
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _submitDeliveryConfirmed(state, customerName, amount);
              },
              child: Text(
                "LOG ONCE",
                style: AppTheme.labelBold.copyWith(color: AppTheme.primary),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: TextButton(
                onPressed: () {
                  state.addCustomer(name: customerName);
                  Navigator.pop(context);
                  _submitDeliveryConfirmed(state, customerName, amount);
                },
                child: Text(
                  "ADD PERMANENTLY",
                  style: AppTheme.labelBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _submitDeliveryConfirmed(LedgerState state, String customer, double amount) {
    setState(() {
      _isSaving = true;
    });

    // Simulate saving spinner to match custom loading transitions
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        state.addDeliveryLog(
          customerName: customer,
          itemName: state.currentLoggingItem,
          amount: amount,
          isPaid: _isPaid,
        );

        CustomToast.showSuccess(
          context,
          "LOGGED ₹${amount.toStringAsFixed(0)} FOR $customer",
        );

        _clearForm();
        setState(() {
          _isSaving = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LedgerState>(context);

    if (state.isLoading) {
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonCard(height: 24.0, width: 180.0),
                const SizedBox(height: 16.0),
                const SkeletonCard(height: 380.0),
                const SizedBox(height: 32.0),
                const SkeletonCard(height: 24.0, width: 220.0),
                const SizedBox(height: 16.0),
                const SkeletonCard(height: 180.0),
              ],
            ),
          ),
        ),
      );
    }

    // If rounds have not started yet, block sales log with lock screen
    if (!state.roundsStarted) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppTheme.primary,
                      size: 32.0,
                    ),
                  ),
                  const SizedBox(height: 28.0),
                  Text(
                    "ROUTE INITIALIZATION REQUIRED",
                    style: AppTheme.headlineLg.copyWith(fontSize: 20.0),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    "You need to initialize your day's delivery route and select products in the Setup screen before you can record sales transactions.",
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28.0),
                  InkWell(
                    onTap: () {
                      state.resetRounds();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
                        border: Border.all(color: Colors.black, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.primary,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          )
                        ],
                      ),
                      child: Text(
                        "GO TO SETUP",
                        style: AppTheme.labelBold.copyWith(color: Colors.white, letterSpacing: 1.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Filter customers based on search query (only filter by customer name)
    final filteredCustomers = state.customers.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort by historical frequency in deliveryLogs (predictive autocomplete)
    final Map<String, int> customerFrequency = {};
    for (var log in state.deliveryLogs) {
      customerFrequency[log.customerName] = (customerFrequency[log.customerName] ?? 0) + 1;
    }
    filteredCustomers.sort((a, b) {
      final freqA = customerFrequency[a.name] ?? 0;
      final freqB = customerFrequency[b.name] ?? 0;
      return freqB.compareTo(freqA);
    });

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _showSuggestions = false;
        });
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main Scrollable form fields Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Context Switcher: Active Products
                    Text(
                      "ACTIVE SALES ITEM",
                      style: AppTheme.labelBold.copyWith(fontSize: 11, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8.0),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: state.activeRoundsItems.map((item) {
                          final isCurrent = state.currentLoggingItem == item;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: InkWell(
                              onTap: () => state.setCurrentLoggingItem(item),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                                decoration: BoxDecoration(
                                  color: isCurrent ? AppTheme.primary : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  border: Border.all(
                                    color: isCurrent ? Colors.black : AppTheme.outlineVariant,
                                    width: isCurrent ? 2.0 : 1.5,
                                  ),
                                  boxShadow: isCurrent ? AppTheme.hardShadowLight : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCurrent ? Icons.check_circle : Icons.circle_outlined,
                                      color: isCurrent ? Colors.white : AppTheme.onSurfaceVariant,
                                      size: 18.0,
                                    ),
                                    const SizedBox(width: 8.0),
                                    Text(
                                      item,
                                      style: AppTheme.labelBold.copyWith(
                                        color: isCurrent ? Colors.white : AppTheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 28.0),

                    // 2. Customer Search Input field
                    Text(
                      "CUSTOMER / SHOP NAME",
                      style: AppTheme.labelBold.copyWith(fontSize: 11, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8.0),
                    CompositedTransformTarget(
                      link: _layerLink,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: _customerFocusNode.hasFocus ? AppTheme.hardShadowLight : null,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: TextField(
                          controller: _customerController,
                          focusNode: _customerFocusNode,
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
                            hintText: "Search or enter new shop name...",
                            hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.outline),
                            prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                            filled: true,
                            fillColor: AppTheme.surface,
                            errorText: _customerError,
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.black, width: 2.0),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppTheme.error, width: 2.0),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                          ),
                          style: AppTheme.bodyLg,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24.0),

                    // 3. Amount Section
                    Text(
                      "DELIVERY VALUE (₹)",
                      style: AppTheme.labelBold.copyWith(fontSize: 11, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: _amountFocusNode.hasFocus ? AppTheme.hardShadowLight : null,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: TextField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitDelivery(state),
                        decoration: InputDecoration(
                          hintText: "Enter manual amount...",
                          hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.outline),
                          prefixIcon: const Icon(Icons.currency_rupee, color: AppTheme.primary),
                          filled: true,
                          fillColor: AppTheme.surface,
                          errorText: _amountError,
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black, width: 2.0),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppTheme.error, width: 2.0),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                        ),
                        style: AppTheme.headlineMd.copyWith(color: Colors.black),
                      ),
                    ),

                    const SizedBox(height: 16.0),

                    // 4. Fast Key-Chips Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisExtent: 44,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _quickAmounts.length,
                      itemBuilder: (context, index) {
                        final quickAmount = _quickAmounts[index];
                        final isMatch = _amountController.text == quickAmount.toStringAsFixed(0);

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _amountController.text = quickAmount.toStringAsFixed(0);
                            });
                            _amountFocusNode.unfocus();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isMatch ? Colors.black : AppTheme.surface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(
                                color: isMatch ? Colors.black : AppTheme.outlineVariant,
                                width: 1.5,
                              ),
                              boxShadow: isMatch ? AppTheme.hardShadowLight : null,
                            ),
                            child: Center(
                              child: Text(
                                "₹${quickAmount.toStringAsFixed(0)}",
                                style: AppTheme.labelBold.copyWith(
                                  color: isMatch ? Colors.white : AppTheme.onSurface,
                                  fontSize: 13.0,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28.0),

                    // 5. PAID / NOT PAID Toggle Switches
                    Text(
                      "PAYMENT STATUS",
                      style: AppTheme.labelBold.copyWith(fontSize: 11, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isPaid = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              decoration: BoxDecoration(
                                color: _isPaid ? AppTheme.successContainer : AppTheme.surface,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(AppTheme.radiusMd),
                                  bottomLeft: Radius.circular(AppTheme.radiusMd),
                                ),
                                border: Border.all(
                                  color: _isPaid ? Colors.black : AppTheme.outlineVariant,
                                  width: _isPaid ? 2.0 : 1.5,
                                ),
                                boxShadow: _isPaid ? AppTheme.hardShadowLight : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: _isPaid ? AppTheme.onSuccessContainer : AppTheme.outline,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    "PAID",
                                    style: AppTheme.labelBold.copyWith(
                                      color: _isPaid ? AppTheme.onSuccessContainer : AppTheme.outline,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isPaid = false;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              decoration: BoxDecoration(
                                color: !_isPaid ? AppTheme.errorContainer : AppTheme.surface,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(AppTheme.radiusMd),
                                  bottomRight: Radius.circular(AppTheme.radiusMd),
                                ),
                                border: Border.all(
                                  color: !_isPaid ? Colors.black : AppTheme.outlineVariant,
                                  width: !_isPaid ? 2.0 : 1.5,
                                ),
                                boxShadow: !_isPaid ? AppTheme.hardShadowLight : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error,
                                    color: !_isPaid ? AppTheme.onErrorContainer : AppTheme.outline,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    "NOT PAID",
                                    style: AppTheme.labelBold.copyWith(
                                      color: !_isPaid ? AppTheme.onErrorContainer : AppTheme.outline,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36.0),

                    // 6. Action Button: ADD DELIVERY
                    InkWell(
                      onTap: _isSaving ? null : () => _submitDelivery(state),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          boxShadow: !_isSaving ? AppTheme.hardShadowButton : null,
                        ),
                        child: Center(
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3.0,
                                  ),
                                )
                              : Text(
                                  "ADD DELIVERY LOG",
                                  style: AppTheme.headlineMd.copyWith(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // Recent Logs Preview block inside a bento container
                    if (state.deliveryLogs.isNotEmpty) ...[
                      const SizedBox(height: 32.0),
                      Text(
                        "RECENT ENTRIES FOR THIS RUN",
                        style: AppTheme.labelBold.copyWith(fontSize: 11, color: AppTheme.onSurfaceVariant, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 16.0),
                      BentoCard(
                        padding: const EdgeInsets.all(0),
                        backgroundColor: AppTheme.surface,
                        shadowStyle: ShadowStyle.light,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.deliveryLogs.take(3).length,
                          separatorBuilder: (context, i) => const Divider(height: 1, color: AppTheme.outlineVariant),
                          itemBuilder: (context, index) {
                            final log = state.deliveryLogs[index];
                            if (_isSaving) {
                              return const SkeletonCard(height: 60);
                            }
                            return AnimatedListItem(
                              index: index,
                              child: ListTile(
                                dense: true,
                                title: Row(
                                  children: [
                                    Text(
                                      "#${log.serialNo} • ${log.customerName}",
                                      style: AppTheme.labelBold,
                                    ),
                                    const Spacer(),
                                    Text(
                                      "₹${log.amount.toStringAsFixed(0)}",
                                      style: AppTheme.dataTabular.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      log.itemName,
                                      style: AppTheme.labelSm,
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                      decoration: BoxDecoration(
                                        color: log.isPaid ? AppTheme.successContainer : AppTheme.errorContainer,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      ),
                                      child: Text(
                                        log.isPaid ? "PAID" : "UNPAID",
                                        style: AppTheme.labelBold.copyWith(
                                          color: log.isPaid ? AppTheme.onSuccessContainer : AppTheme.onErrorContainer,
                                          fontSize: 9.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),

                // 7. Autocomplete dropdown container overlay, placed at Stack level
                if (_showSuggestions && _searchQuery.isNotEmpty && filteredCustomers.isNotEmpty)
                  Positioned(
                    child: CompositedTransformFollower(
                      link: _layerLink,
                      showWhenUnlinked: false,
                      offset: const Offset(0, 60.0), // Perfect vertical gap under the search textfield
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          width: MediaQuery.of(context).size.width - 48,
                          constraints: const BoxConstraints(maxHeight: 200),
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
                              itemCount: filteredCustomers.length,
                              separatorBuilder: (context, i) => const Divider(height: 1, color: AppTheme.outlineVariant),
                              itemBuilder: (context, index) {
                                final customer = filteredCustomers[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.surfaceContainerHighest,
                                    radius: 16.0,
                                    child: Icon(customer.icon, color: AppTheme.primary, size: 16.0),
                                  ),
                                  title: Text(
                                    customer.name,
                                    style: AppTheme.labelBold,
                                  ),
                                  trailing: Text(
                                    customer.outstanding > 0 ? "₹${customer.outstanding.toStringAsFixed(0)}" : "CLEAN",
                                    style: AppTheme.dataTabular.copyWith(
                                      color: customer.outstanding > 0 ? AppTheme.error : AppTheme.success,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                  onTap: () {
                                    _customerController.text = customer.name;
                                    _customerFocusNode.unfocus();
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
        ),
      ),
    );
  }
}

