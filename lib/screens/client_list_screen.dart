import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/app_state.dart';
import '../core/models/models.dart';
import '../widgets/bento_card.dart';
import 'customer_profile_screen.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/empty_state_widget.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  String _balanceFilter = "All Balances";
  String _statusFilter = "All Status";
  String _alphabetFilter = "All A-Z";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(
    String label,
    String activeVal,
    ValueChanged<String> onSelected,
    List<String> options,
  ) {
    final isSelected = activeVal != options.first;
    return PopupMenuButton<String>(
      initialValue: activeVal,
      onSelected: onSelected,
      itemBuilder: (context) {
        return options.map((opt) {
          return PopupMenuItem<String>(
            value: opt,
            child: Text(
              opt,
              style: AppTheme.labelBold.copyWith(
                fontSize: 12.0,
                color: activeVal == opt ? AppTheme.primary : Colors.black,
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(100.0),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              activeVal,
              style: AppTheme.labelBold.copyWith(
                fontSize: 12.0,
                color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4.0),
            Icon(
              Icons.arrow_drop_down,
              size: 16.0,
              color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LedgerState>(context);
    final customers = state.customers;

    // Calculate dynamic stats
    final totalClients = customers.length;
    final pendingCount = customers.where((c) => c.outstanding > 0).length;
    final totalOutstanding = customers.fold<double>(0.0, (sum, c) => sum + c.outstanding);
    final activeCount = totalClients - pendingCount;

    // Filter customers
    final filteredCustomers = customers.where((c) {
      final nameMatch = c.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!nameMatch) return false;

      if (_balanceFilter == "Pending (> ₹0)" && c.outstanding <= 0) {
        return false;
      }
      if (_balanceFilter == "High (> ₹5k)" && c.outstanding <= 5000) {
        return false;
      }

      if (_statusFilter == "Active Client" && c.outstanding > 0) {
        return false;
      }
      if (_statusFilter == "Inactive" && c.outstanding == 0) {
        return false;
      }

      if (_alphabetFilter == "A - M") {
        final firstLetter = c.name.trim().isEmpty ? "" : c.name.trim()[0].toUpperCase();
        if (firstLetter.compareTo("A") < 0 || firstLetter.compareTo("M") > 0) {
          return false;
        }
      }
      if (_alphabetFilter == "N - Z") {
        final firstLetter = c.name.trim().isEmpty ? "" : c.name.trim()[0].toUpperCase();
        if (firstLetter.compareTo("N") < 0 || firstLetter.compareTo("Z") > 0) {
          return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bento Stats Grid (2x2 Layout)
                        Row(
                          children: [
                            Expanded(
                              child: BentoCard(
                                padding: const EdgeInsets.all(16.0),
                                backgroundColor: AppTheme.surface,
                                shadowStyle: ShadowStyle.light,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "TOTAL CLIENTS",
                                      style: AppTheme.labelSm.copyWith(fontSize: 10.0, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      "$totalClients",
                                      style: AppTheme.headlineLg.copyWith(fontSize: 20.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: BentoCard(
                                padding: const EdgeInsets.all(16.0),
                                backgroundColor: AppTheme.surface,
                                shadowStyle: ShadowStyle.light,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "ACTIVE RUN",
                                      style: AppTheme.labelSm.copyWith(fontSize: 10.0, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      "$activeCount",
                                      style: AppTheme.headlineLg.copyWith(fontSize: 20.0, color: AppTheme.success),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          children: [
                            Expanded(
                              child: BentoCard(
                                padding: const EdgeInsets.all(16.0),
                                backgroundColor: AppTheme.surface,
                                shadowStyle: ShadowStyle.light,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "DEBT ENTRIES",
                                      style: AppTheme.labelSm.copyWith(fontSize: 10.0, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      "$pendingCount",
                                      style: AppTheme.headlineLg.copyWith(fontSize: 20.0, color: AppTheme.error),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: BentoCard(
                                onTap: () {
                                  _showOutstandingCollectionsBottomSheet(context);
                                },
                                padding: const EdgeInsets.all(16.0),
                                backgroundColor: AppTheme.surface,
                                shadowStyle: ShadowStyle.light,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "TOTAL PENDING",
                                      style: AppTheme.labelSm.copyWith(fontSize: 10.0, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      "₹${totalOutstanding.toStringAsFixed(0)}",
                                      style: AppTheme.dataTabular.copyWith(fontSize: 18.0, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyHeaderDelegate(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search input bar
                        Container(
                          decoration: const BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x0A000000),
                                offset: Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Search shop name...",
                              hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.outline),
                              prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = "";
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppTheme.surface,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.black, width: 2.0),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              ),
                            ),
                            style: AppTheme.bodyLg,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        // Filter Chips Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip("All Balances", _balanceFilter, (val) {
                                setState(() => _balanceFilter = val);
                              }, ["All Balances", "Pending (> ₹0)", "High (> ₹5k)"]),
                              const SizedBox(width: 8.0),
                              _buildFilterChip("All Status", _statusFilter, (val) {
                                setState(() => _statusFilter = val);
                              }, ["All Status", "Active Client", "Inactive"]),
                              const SizedBox(width: 8.0),
                              _buildFilterChip("All A-Z", _alphabetFilter, (val) {
                                setState(() => _alphabetFilter = val);
                              }, ["All A-Z", "A - M", "N - Z"]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "CLIENTS DIRECTORY",
                      style: AppTheme.labelBold.copyWith(
                        fontSize: 11.0,
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      "${filteredCustomers.length} FOUND",
                      style: AppTheme.labelBold.copyWith(fontSize: 10.0, color: AppTheme.outline),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: SingleChildScrollView(
                    child: BentoCard(
                      padding: const EdgeInsets.all(0),
                      backgroundColor: AppTheme.surface,
                      shadowStyle: ShadowStyle.light,
                      child: filteredCustomers.isEmpty
                          ? const EmptyStateWidget(
                              title: "No Clients Found",
                              message: "No matching clients found.",
                              icon: Icons.people_outline,
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredCustomers.length,
                              separatorBuilder: (context, i) =>
                                  const Divider(height: 1, color: AppTheme.outlineVariant),
                              itemBuilder: (context, index) {
                                final customer = filteredCustomers[index];
                                final hasDebt = customer.outstanding > 0;

                                return AnimatedListItem(
                                  index: index,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: hasDebt
                                          ? AppTheme.errorContainer.withValues(alpha: 0.4)
                                          : AppTheme.surfaceContainerHighest,
                                      radius: 20.0,
                                      child: Icon(
                                        customer.icon,
                                        color: hasDebt ? AppTheme.error : AppTheme.primary,
                                        size: 20.0,
                                      ),
                                    ),
                                    title: Text(
                                      customer.name,
                                      style: AppTheme.labelBold.copyWith(fontSize: 15.0),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              hasDebt ? "₹${customer.outstanding.toStringAsFixed(0)}" : "CLEAN",
                                              style: AppTheme.dataTabular.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.0,
                                                color: hasDebt ? AppTheme.error : AppTheme.success,
                                              ),
                                            ),
                                            if (hasDebt)
                                              Text(
                                                "OUTSTANDING",
                                                style: AppTheme.labelSm.copyWith(
                                                  fontSize: 8.0,
                                                  color: AppTheme.error,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 8.0),
                                        const Icon(Icons.chevron_right, color: AppTheme.outline, size: 20.0),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CustomerProfileScreen(
                                            customerName: customer.name,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
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

  void _showOutstandingCollectionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (context) {
        return const OutstandingCollectionsSheet();
      },
    );
  }
}

class OutstandingCollectionsSheet extends StatefulWidget {
  const OutstandingCollectionsSheet({super.key});

  @override
  State<OutstandingCollectionsSheet> createState() => _OutstandingCollectionsSheetState();
}

class _OutstandingCollectionsSheetState extends State<OutstandingCollectionsSheet> {
  final TextEditingController _modalSearchController = TextEditingController();
  String _modalSearchQuery = "";

  @override
  void dispose() {
    _modalSearchController.dispose();
    super.dispose();
  }

  int _calculateDaysElapsed(DateTime pastDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final past = DateTime(pastDate.year, pastDate.month, pastDate.day);
    return today.difference(past).inDays;
  }

  String _getPaymentPendingText(Customer customer, LedgerState state) {
    // Find all logs for this customer
    final customerLogs = state.deliveryLogs
        .where((log) => log.customerName == customer.name)
        .toList();

    // Find the latest payment log
    final paymentLogs = customerLogs.where((log) => log.isPayment).toList();

    if (paymentLogs.isNotEmpty) {
      final lastPayment = paymentLogs.first;
      final days = _calculateDaysElapsed(lastPayment.dateTime);
      if (days <= 0) {
        return "Last paid: Today";
      } else if (days == 1) {
        return "Last paid: Yesterday";
      } else {
        return "Last paid: $days days ago";
      }
    } else {
      // Find oldest unpaid delivery log
      final unpaidDeliveries = customerLogs
          .where((log) => !log.isPayment && !log.isPaid)
          .toList();

      if (unpaidDeliveries.isNotEmpty) {
        unpaidDeliveries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        final oldestUnpaid = unpaidDeliveries.first;
        final days = _calculateDaysElapsed(oldestUnpaid.dateTime);
        if (days <= 0) {
          return "Pending since: Today";
        } else if (days == 1) {
          return "Pending since: Yesterday";
        } else {
          return "Pending since: $days days ago";
        }
      }
      return "No payments recorded";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: Consumer<LedgerState>(
        builder: (context, state, child) {
          final pendingCustomers = state.customers
              .where((c) => c.outstanding > 0)
              .toList();

          // Sort Highest Pending Amount -> Lowest Pending Amount
          pendingCustomers.sort((a, b) => b.outstanding.compareTo(a.outstanding));

          // Filter pending customers by name search only
          final filteredPending = pendingCustomers.where((c) {
            final query = _modalSearchQuery.toLowerCase();
            return c.name.toLowerCase().contains(query);
          }).toList();

          final totalPending = pendingCustomers.fold<double>(0.0, (sum, c) => sum + c.outstanding);
          final pendingCount = pendingCustomers.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handlebar / Pull Bar
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
              const SizedBox(height: 16.0),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Outstanding Collections",
                    style: AppTheme.headlineMd.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Total pending statistics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TOTAL PENDING AMOUNT",
                        style: AppTheme.labelSm.copyWith(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        "₹${totalPending.toStringAsFixed(0)}",
                        style: AppTheme.headlineLg.copyWith(
                          fontSize: 26.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "CUSTOMERS",
                        style: AppTheme.labelSm.copyWith(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.outline,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        "$pendingCount",
                        style: AppTheme.headlineMd.copyWith(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Search box
              Container(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0A000000),
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _modalSearchController,
                  onChanged: (val) {
                    setState(() {
                      _modalSearchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search customer...",
                    hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.outline),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                    suffixIcon: _modalSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _modalSearchController.clear();
                              setState(() {
                                _modalSearchQuery = "";
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surface,
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1.5),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.black, width: 2.0),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  style: AppTheme.bodyLg,
                ),
              ),
              const SizedBox(height: 16.0),

              // Section Header
              Text(
                "CUSTOMERS WITH PENDING BALANCE: ${filteredPending.length}",
                style: AppTheme.labelBold.copyWith(
                  fontSize: 11.0,
                  color: AppTheme.onSurfaceVariant,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16.0),

              // Scrollable list of pending clients
              Expanded(
                child: BentoCard(
                  padding: const EdgeInsets.all(0),
                  backgroundColor: AppTheme.surface,
                  shadowStyle: ShadowStyle.light,
                  child: filteredPending.isEmpty
                      ? const EmptyStateWidget(
                          title: "No Pending Balances",
                          message: "No matching pending balances found.",
                          icon: Icons.account_balance_wallet_outlined,
                        )
                      : ListView.separated(
                          itemCount: filteredPending.length,
                          separatorBuilder: (context, i) =>
                              const Divider(height: 1, color: AppTheme.outlineVariant),
                          itemBuilder: (context, index) {
                            final customer = filteredPending[index];
                            final pendingText = _getPaymentPendingText(customer, state);

                            return AnimatedListItem(
                              index: index,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.errorContainer.withValues(alpha: 0.4),
                                  radius: 20.0,
                                  child: Icon(
                                    customer.icon,
                                    color: AppTheme.error,
                                    size: 20.0,
                                  ),
                                ),
                                title: Text(
                                  customer.name,
                                  style: AppTheme.labelBold.copyWith(fontSize: 15.0),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  pendingText,
                                  style: AppTheme.labelSm.copyWith(color: AppTheme.outline),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "₹${customer.outstanding.toStringAsFixed(0)}",
                                          style: AppTheme.dataTabular.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.0,
                                            color: AppTheme.error,
                                          ),
                                        ),
                                        Text(
                                          "OUTSTANDING",
                                          style: AppTheme.labelSm.copyWith(
                                            fontSize: 8.0,
                                            color: AppTheme.error,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8.0),
                                    const Icon(Icons.chevron_right, color: AppTheme.outline, size: 20.0),
                                  ],
                                ),
                                onTap: () {
                                  // Close the bottom sheet and push the ledger page
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CustomerProfileScreen(
                                        customerName: customer.name,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyHeaderDelegate({required this.child});

  @override
  double get minExtent => 110.0;
  @override
  double get maxExtent => 110.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.only(bottom: 8.0),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return true;
  }
}


