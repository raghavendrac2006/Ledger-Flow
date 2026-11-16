import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/app_state.dart';
import '../core/models/whatsapp_message_model.dart';
import '../core/services/whatsapp_message_service.dart';
import '../widgets/bento_card.dart';
import '../widgets/custom_toast.dart';
import 'whatsapp_message_preview_screen.dart';

class WhatsAppMessageReviewScreen extends StatefulWidget {
  const WhatsAppMessageReviewScreen({super.key});

  @override
  State<WhatsAppMessageReviewScreen> createState() => _WhatsAppMessageReviewScreenState();
}

class _CustomerReviewItem {
  final String customerName;
  final double totalAmount;
  final bool isPaid;
  final int deliveryCount;
  String? phoneNumber;
  bool isSelected;

  _CustomerReviewItem({
    required this.customerName,
    required this.totalAmount,
    required this.isPaid,
    required this.deliveryCount,
    this.phoneNumber,
    this.isSelected = false,
  });
}

class _WhatsAppMessageReviewScreenState extends State<WhatsAppMessageReviewScreen> {
  final List<_CustomerReviewItem> _items = [];
  bool _initialized = false;
  String _searchQuery = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _loadTodayDeliveries();
      _initialized = true;
    }
  }

  void _loadTodayDeliveries() {
    final state = Provider.of<LedgerState>(context, listen: false);
    final businessDate = state.deliveryDate;

    // Filter delivery logs for today that are not payments
    final todayLogs = state.deliveryLogs.where((log) {
      if (log.isPayment) return false;
      return log.dateTime.year == businessDate.year &&
          log.dateTime.month == businessDate.month &&
          log.dateTime.day == businessDate.day;
    }).toList();

    // Group by customer name
    final Map<String, List<dynamic>> grouped = {};
    for (final log in todayLogs) {
      grouped.putIfAbsent(log.customerName, () => []).add(log);
    }

    _items.clear();
    grouped.forEach((name, logs) {
      final double totalAmount = logs.fold(0.0, (sum, l) => sum + (l.amount as num).toDouble());
      final bool allPaid = logs.every((l) => l.isPaid == true);
      final phone = state.getCustomerPhoneNumber(name);

      _items.add(_CustomerReviewItem(
        customerName: name,
        totalAmount: totalAmount,
        isPaid: allPaid,
        deliveryCount: logs.length,
        phoneNumber: phone,
        isSelected: false, // Per specification: Do not automatically select every customer to prevent unwanted messages
      ));
    });

    // Sort alphabetically
    _items.sort((a, b) => a.customerName.toLowerCase().compareTo(b.customerName.toLowerCase()));
  }

  void _toggleSelectAll(bool selectAll) {
    setState(() {
      for (var item in _items) {
        item.isSelected = selectAll;
      }
    });
  }

  void _showAddPhoneDialog(BuildContext context, _CustomerReviewItem item, LedgerState state) {
    final phoneController = TextEditingController(text: item.phoneNumber ?? "");
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                side: const BorderSide(color: Colors.black, width: 2.0),
              ),
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  const Icon(Icons.phone, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "PHONE FOR ${item.customerName.toUpperCase()}",
                      style: AppTheme.headlineMd.copyWith(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enter a 10-digit Indian mobile number for this customer. It will be saved permanently.",
                    style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixText: "+91 ",
                      hintText: "9876543210",
                      errorText: errorText,
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "CANCEL",
                    style: AppTheme.labelBold.copyWith(color: AppTheme.outline),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                  onPressed: () async {
                    final normalized = WhatsAppMessageService.normalizeIndianPhoneNumber(phoneController.text.trim());
                    if (normalized == null) {
                      setDialogState(() {
                        errorText = "Enter a valid 10-digit Indian mobile number";
                      });
                      return;
                    }
                    await state.updateCustomerPhoneNumber(item.customerName, phoneController.text.trim());
                    setState(() {
                      item.phoneNumber = phoneController.text.trim();
                    });
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      CustomToast.showSuccess(context, "PHONE SAVED FOR ${item.customerName.toUpperCase()}");
                    }
                  },
                  child: Text(
                    "SAVE NUMBER",
                    style: AppTheme.labelBold.copyWith(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddCustomerModal(BuildContext context, LedgerState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (ctx) {
        String modalSearch = "";
        return StatefulBuilder(
          builder: (context, setModalState) {
            final existingNames = _items.map((i) => i.customerName.toLowerCase()).toSet();
            final availableCustomers = state.customers.where((c) {
              if (existingNames.contains(c.name.toLowerCase())) return false;
              if (modalSearch.isNotEmpty && !c.name.toLowerCase().contains(modalSearch.toLowerCase())) {
                return false;
              }
              return true;
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "ADD CUSTOMER TO BATCH",
                          style: AppTheme.headlineMd.copyWith(fontSize: 18),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (val) {
                        setModalState(() {
                          modalSearch = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search customer name...",
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                        filled: true,
                        fillColor: AppTheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(color: AppTheme.outlineVariant),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: availableCustomers.isEmpty
                          ? Center(
                              child: Text(
                                "No additional customers found.",
                                style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant),
                              ),
                            )
                          : ListView.separated(
                              itemCount: availableCustomers.length,
                              separatorBuilder: (context, i) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final cust = availableCustomers[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.surfaceContainerHighest,
                                    child: Icon(cust.icon, color: AppTheme.primary, size: 20),
                                  ),
                                  title: Text(cust.name, style: AppTheme.labelBold),
                                  subtitle: Text(
                                    cust.outstanding > 0
                                        ? "Balance: ₹${cust.outstanding.toStringAsFixed(0)}"
                                        : "Clean Account",
                                    style: TextStyle(
                                      color: cust.outstanding > 0 ? AppTheme.error : AppTheme.success,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                                  onTap: () {
                                    final phone = state.getCustomerPhoneNumber(cust.name);
                                    setState(() {
                                      _items.add(_CustomerReviewItem(
                                        customerName: cust.name,
                                        totalAmount: cust.outstanding > 0 ? cust.outstanding : 0.0,
                                        isPaid: cust.outstanding <= 0,
                                        deliveryCount: 0,
                                        phoneNumber: phone,
                                        isSelected: true,
                                      ));
                                    });
                                    Navigator.pop(ctx);
                                    CustomToast.showSuccess(context, "ADDED ${cust.name.toUpperCase()}");
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _proceedToPreview(LedgerState state) {
    final selectedItems = _items.where((i) => i.isSelected).toList();
    if (selectedItems.isEmpty) {
      CustomToast.showError(context, "PLEASE SELECT AT LEAST ONE CUSTOMER");
      return;
    }

    // Build WhatsAppCustomerMessage objects
    final List<WhatsAppCustomerMessage> messages = selectedItems.map((item) {
      final defaultMsg = WhatsAppMessageService.generateMessage(
        customerName: item.customerName,
        amount: item.totalAmount,
        isPaid: item.isPaid,
      );

      return WhatsAppCustomerMessage(
        customerName: item.customerName,
        phoneNumber: item.phoneNumber,
        todayAmount: item.totalAmount,
        isPaid: item.isPaid,
        defaultMessage: defaultMsg,
      );
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WhatsAppMessagePreviewScreen(
          messages: messages,
          onPhoneUpdated: (name, phone) {
            state.updateCustomerPhoneNumber(name, phone);
            setState(() {
              for (var it in _items) {
                if (it.customerName.toLowerCase() == name.toLowerCase()) {
                  it.phoneNumber = phone;
                }
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LedgerState>(context);
    final selectedCount = _items.where((i) => i.isSelected).length;
    final allSelected = _items.isNotEmpty && _items.every((i) => i.isSelected);

    final filteredItems = _items.where((i) {
      if (_searchQuery.isEmpty) return true;
      return i.customerName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          tooltip: "Close",
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "WHATSAPP UPDATES",
              style: AppTheme.headlineMd.copyWith(fontSize: 17, letterSpacing: 1.0),
            ),
            Text(
              "Review today's deliveries & select recipients",
              style: AppTheme.labelSm.copyWith(color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppTheme.outlineVariant, height: 1.0),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Controls Bar (Search + Selection Summary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              color: Colors.white,
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Filter today's customers...",
                      hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.outline),
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.primary),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(color: AppTheme.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(color: AppTheme.outlineVariant),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Select All / Deselect All + Badge
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _toggleSelectAll(!allSelected),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                allSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                color: allSelected ? AppTheme.primary : AppTheme.outline,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                allSelected ? "DESELECT ALL" : "SELECT ALL",
                                style: AppTheme.labelBold.copyWith(fontSize: 12, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: selectedCount > 0 ? AppTheme.primaryContainer : AppTheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "$selectedCount of ${_items.length} SELECTED",
                          style: AppTheme.labelBold.copyWith(
                            color: selectedCount > 0 ? AppTheme.primary : AppTheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.outlineVariant),

            // Customer List
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppTheme.surfaceContainerLow,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.mark_chat_unread_outlined, size: 48, color: AppTheme.outline),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _items.isEmpty
                                  ? "NO DELIVERIES RECORDED TODAY"
                                  : "NO MATCHING CUSTOMERS",
                              style: AppTheme.headlineMd.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _items.isEmpty
                                  ? "You haven't logged any deliveries today yet, or you can manually add customers below."
                                  : "Try clearing your search query.",
                              textAlign: TextAlign.center,
                              style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredItems.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final hasValidPhone = WhatsAppMessageService.isValidIndianPhoneNumber(item.phoneNumber);

                        return BentoCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                          backgroundColor: item.isSelected ? Colors.white : AppTheme.surface,
                          border: Border.all(
                            color: item.isSelected ? AppTheme.primary : AppTheme.outlineVariant,
                            width: item.isSelected ? 2.0 : 1.0,
                          ),
                          shadowStyle: item.isSelected ? ShadowStyle.button : ShadowStyle.light,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                item.isSelected = !item.isSelected;
                              });
                            },
                            child: Row(
                              children: [
                                Checkbox(
                                  value: item.isSelected,
                                  activeColor: AppTheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      item.isSelected = val ?? false;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.customerName,
                                              style: AppTheme.labelBold.copyWith(fontSize: 15),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: item.isPaid ? AppTheme.successContainer : AppTheme.errorContainer,
                                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                            ),
                                            child: Text(
                                              item.isPaid ? "PAID" : "PENDING",
                                              style: AppTheme.labelBold.copyWith(
                                                color: item.isPaid ? AppTheme.onSuccessContainer : AppTheme.onErrorContainer,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            WhatsAppMessageService.formatCurrency(item.totalAmount),
                                            style: AppTheme.headlineMd.copyWith(
                                              fontSize: 15,
                                              color: AppTheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          if (item.deliveryCount > 0)
                                            Text(
                                              "(${item.deliveryCount} ${item.deliveryCount == 1 ? 'item' : 'items'})",
                                              style: AppTheme.labelSm.copyWith(color: AppTheme.onSurfaceVariant),
                                            ),
                                          const Spacer(),
                                          // Phone Indicator
                                          InkWell(
                                            onTap: () => _showAddPhoneDialog(context, item, state),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: hasValidPhone ? AppTheme.surfaceContainerLow : AppTheme.tertiaryFixed,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: hasValidPhone ? AppTheme.outlineVariant : AppTheme.onTertiaryFixedVariant,
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    hasValidPhone ? Icons.phone : Icons.phone_missed,
                                                    size: 13,
                                                    color: hasValidPhone ? AppTheme.primary : AppTheme.onTertiaryFixedVariant,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    hasValidPhone ? item.phoneNumber! : "ADD PHONE",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: hasValidPhone ? AppTheme.onSurface : AppTheme.onTertiaryFixedVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Actions (Add Customers & Next Button)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.outlineVariant, width: 1.0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        side: const BorderSide(color: Colors.black, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      onPressed: () => _showAddCustomerModal(context, state),
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.black, size: 18),
                      label: Text(
                        "ADD CUSTOMER",
                        style: AppTheme.labelBold.copyWith(color: Colors.black, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor: selectedCount > 0 ? AppTheme.primary : AppTheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        elevation: selectedCount > 0 ? 3 : 0,
                      ),
                      onPressed: selectedCount > 0 ? () => _proceedToPreview(state) : null,
                      child: Text(
                        "PREVIEW MESSAGES ($selectedCount)",
                        style: AppTheme.labelBold.copyWith(
                          color: selectedCount > 0 ? Colors.white : AppTheme.outline,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
