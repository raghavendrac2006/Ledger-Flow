import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/app_state.dart';
import '../core/models/models.dart';
import '../widgets/empty_state_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LedgerState>(context);

    // Retrieve latest 2 rice flour bags (active + completed)
    final allBags = List<RiceBag>.from(state.riceBags);
    allBags.sort((a, b) => (b.bagNumber ?? 0).compareTo(a.bagNumber ?? 0));
    final latest2Bags = allBags.take(2).toList();
    final latest2BagIds = latest2Bags.map((b) => b.bagId).toSet();

    // Filter delivery logs for latest 2 batches
    final latest2DeliveryLogs = state.deliveryLogs.where((log) {
      if (log.associatedBagId != null) {
        return latest2BagIds.contains(log.associatedBagId);
      }
      return true; // Keep recent if unassociated
    }).where((log) {
      if (_searchQuery.isEmpty) return true;
      return log.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          log.itemName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Filter expenses for latest 2 batches
    final latest2Expenses = state.expenses.where((exp) {
      if (exp.associatedBagId != null) {
        return latest2BagIds.contains(exp.associatedBagId);
      }
      return true;
    }).where((exp) {
      if (_searchQuery.isEmpty) return true;
      return exp.itemName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          exp.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Filter daily flour usage logs for latest 2 batches
    final latest2Usages = state.dailyUsages.where((usage) {
      return latest2BagIds.contains(usage.bagId);
    }).toList();

    // Oil Usages
    final oilUsages = state.oilUsages;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                "BATCH LEDGER HISTORY",
                style: AppTheme.labelSm.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                "Latest 2 Batches History",
                style: AppTheme.headlineXl,
              ),
              const SizedBox(height: 8.0),
              Text(
                "Complete overview of sales, expenses, flour usage, and gas logs for the active & recent 2 batches.",
                style: AppTheme.labelSm.copyWith(color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24.0),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search transactions or items...",
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: const BorderSide(color: AppTheme.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),

              // Tab Bar
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.outline,
                indicatorColor: AppTheme.primary,
                tabs: [
                  Tab(text: "Sales (${latest2DeliveryLogs.length})"),
                  Tab(text: "Expenses (${latest2Expenses.length})"),
                  Tab(text: "Flour Usage (${latest2Usages.length})"),
                  Tab(text: "Oil & LPG (${oilUsages.length})"),
                ],
              ),
              const SizedBox(height: 20.0),

              // Tab Bar View Content
              SizedBox(
                height: 500,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Sales Logs
                    _buildSalesTab(latest2DeliveryLogs),
                    // Tab 2: Expenses
                    _buildExpensesTab(latest2Expenses),
                    // Tab 3: Daily Flour Usage
                    _buildUsagesTab(latest2Usages, state),
                    // Tab 4: Oil & LPG Logs
                    _buildOilLpgTab(oilUsages, latest2Bags, state),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesTab(List<DeliveryLog> logs) {
    if (logs.isEmpty) {
      return const EmptyStateWidget(
        title: "No Sales Logs",
        message: "No sales recorded for the latest 2 batches.",
        icon: Icons.receipt_long,
      );
    }
    return ListView.separated(
      itemCount: logs.length,
      separatorBuilder: (context, i) => const Divider(color: AppTheme.outlineVariant),
      itemBuilder: (context, index) {
        final log = logs[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: log.isPayment ? AppTheme.successContainer : AppTheme.primaryContainer,
            child: Icon(
              log.isPayment ? Icons.payments : Icons.shopping_bag,
              color: log.isPayment ? AppTheme.onSuccessContainer : AppTheme.primary,
              size: 20,
            ),
          ),
          title: Text(log.customerName, style: AppTheme.labelBold),
          subtitle: Text("${log.itemName} • ${log.date}", style: AppTheme.labelSm),
          trailing: Text(
            "${log.isPayment ? '+' : ''}₹${log.amount.toStringAsFixed(0)}",
            style: AppTheme.dataTabular.copyWith(
              fontWeight: FontWeight.bold,
              color: log.isPayment ? AppTheme.success : AppTheme.onSurface,
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpensesTab(List<ExpenseLog> expenses) {
    if (expenses.isEmpty) {
      return const EmptyStateWidget(
        title: "No Expenses",
        message: "No expenses recorded for the latest 2 batches.",
        icon: Icons.payments_outlined,
      );
    }
    return ListView.separated(
      itemCount: expenses.length,
      separatorBuilder: (context, i) => const Divider(color: AppTheme.outlineVariant),
      itemBuilder: (context, index) {
        final exp = expenses[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppTheme.surfaceContainerHighest,
            child: Icon(Icons.receipt, color: AppTheme.primary, size: 20),
          ),
          title: Text(exp.itemName, style: AppTheme.labelBold),
          subtitle: Text("${exp.category} • ${exp.date}", style: AppTheme.labelSm),
          trailing: Text(
            "₹${exp.amount.toStringAsFixed(0)}",
            style: AppTheme.dataTabular.copyWith(fontWeight: FontWeight.bold, color: AppTheme.error),
          ),
        );
      },
    );
  }

  Widget _buildUsagesTab(List<DailyUsage> usages, LedgerState state) {
    if (usages.isEmpty) {
      return const EmptyStateWidget(
        title: "No Flour Production Logs",
        message: "No daily flour usage logged for the latest 2 batches.",
        icon: Icons.grain,
      );
    }
    return ListView.separated(
      itemCount: usages.length,
      separatorBuilder: (context, i) => const Divider(color: AppTheme.outlineVariant),
      itemBuilder: (context, index) {
        final usage = usages[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppTheme.primaryContainer,
            child: Icon(Icons.scale, color: AppTheme.primary, size: 20),
          ),
          title: Text("${usage.usedKg.toStringAsFixed(1)} KG Used", style: AppTheme.labelBold),
          subtitle: Text("Flour: ${usage.flourType} • Date: ${usage.date}", style: AppTheme.labelSm),
        );
      },
    );
  }

  Widget _buildOilLpgTab(List<OilUsage> oilLogs, List<RiceBag> bags, LedgerState state) {
    final lpgBags = bags.where((b) => b.lpgCylinderKg != null && b.lpgCylinderKg! > 0).toList();

    return ListView(
      children: [
        Text(
          "OIL USAGE LOGS",
          style: AppTheme.labelBold.copyWith(fontSize: 11, color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8.0),
        if (oilLogs.isEmpty)
          const Text("No oil usage logged yet.", style: TextStyle(color: AppTheme.outline))
        else
          ...oilLogs.map((oil) => ListTile(
                leading: const Icon(Icons.water_drop, color: AppTheme.tertiary),
                title: Text("${oil.liters.toStringAsFixed(1)} Liters Oil Consumed", style: AppTheme.labelBold),
                subtitle: Text("Date: ${oil.date}", style: AppTheme.labelSm),
              )),
        const SizedBox(height: 24.0),
        Text(
          "LPG CYLINDER CONSUMPTION LOGS",
          style: AppTheme.labelBold.copyWith(fontSize: 11, color: AppTheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8.0),
        if (lpgBags.isEmpty)
          const Text("No LPG gas recorded for completed batches.", style: TextStyle(color: AppTheme.outline))
        else
          ...lpgBags.map((bag) => ListTile(
                leading: const Icon(Icons.propane_tank, color: AppTheme.secondary),
                title: Text(
                  "Batch #${state.getBagNumber(bag)}: ${bag.lpgCylinderKg?.toStringAsFixed(1)} KG Gas Used",
                  style: AppTheme.labelBold,
                ),
                subtitle: Text("Flour Type: ${bag.flourType} • ${bag.startDate}", style: AppTheme.labelSm),
              )),
      ],
    );
  }
}
