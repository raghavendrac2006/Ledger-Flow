import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../core/app_state.dart';
import '../core/models/models.dart';
import '../core/pdf_service.dart';
import '../widgets/bento_card.dart';
import '../widgets/custom_toast.dart';
import '../widgets/current_bag_performance_widget.dart';
import '../widgets/overall_business_overview_widget.dart';
import '../widgets/batch_history_widget.dart';
import '../widgets/skeleton_card.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/empty_state_widget.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String _selectedExportItem = "1 ₹ Chakli";
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  late TextEditingController _sheetsUrlController;
  late FocusNode _sheetsUrlFocusNode;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<LedgerState>(context, listen: false);
    _sheetsUrlController = TextEditingController(text: state.googleSheetsUrl);
    _sheetsUrlFocusNode = FocusNode();
    _sheetsUrlFocusNode.addListener(() {
      if (!_sheetsUrlFocusNode.hasFocus) {
        _sheetsUrlController.text = state.googleSheetsUrl;
      }
    });
  }

  @override
  void dispose() {
    _sheetsUrlController.dispose();
    _sheetsUrlFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LedgerState>(context);
    if (!_sheetsUrlFocusNode.hasFocus && _sheetsUrlController.text != state.googleSheetsUrl) {
      _sheetsUrlController.text = state.googleSheetsUrl;
    }
    final todaySales = state.latestActiveRevenue;
    final totalDeliveries = state.latestActiveDeliveriesCount;
    final yesterdaySales = state.previousActiveRevenue;

    double percentageChange = 0.0;
    if (yesterdaySales > 0.0) {
      percentageChange = ((todaySales - yesterdaySales) / yesterdaySales) * 100.0;
    } else if (todaySales > 0.0) {
      percentageChange = 100.0;
    }

    final formattedPctChange = percentageChange > 0.0
        ? "+${percentageChange.toStringAsFixed(1)}%"
        : "${percentageChange.toStringAsFixed(1)}%";

    return Scaffold(
      body: state.isLoading
          ? SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonCard(height: 24.0, width: 200.0),
                    const SizedBox(height: 16.0),
                    const SkeletonCard(height: 150.0),
                    const SizedBox(height: 32.0),
                    const SkeletonCard(height: 24.0, width: 220.0),
                    const SizedBox(height: 16.0),
                    const SkeletonCard(height: 220.0),
                    const SizedBox(height: 32.0),
                    const SkeletonCard(height: 24.0, width: 180.0),
                    const SizedBox(height: 16.0),
                    const SkeletonCard(height: 120.0),
                    const SizedBox(height: 32.0),
                    const SkeletonCard(height: 24.0, width: 140.0),
                    const SizedBox(height: 16.0),
                    const SkeletonCard(height: 200.0),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION 1: CURRENT BAG PERFORMANCE
                  Text(
                    "CURRENT BAG PERFORMANCE",
                    style: AppTheme.labelBold.copyWith(
                      fontSize: 11.0,
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  CurrentBagPerformanceWidget(
                    revenue: state.currentBagRevenue,
                    expenses: state.currentBagExpenses,
                    profit: state.currentBagProfit,
                    profitMargin: state.currentBagProfitMargin,
                  ),
                  const SizedBox(height: 28.0),

                  // SECTION 2: OVERALL BUSINESS OVERVIEW
                  Text(
                    "OVERALL BUSINESS OVERVIEW",
                    style: AppTheme.labelBold.copyWith(
                      fontSize: 11.0,
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  OverallBusinessOverviewWidget(
                    overallRevenue: state.overallRevenue,
                    overallExpenses: state.overallExpenses,
                    overallProfit: state.overallProfit,
                    overallProfitMargin: state.overallProfitMargin,
                  ),
                  const SizedBox(height: 28.0),

                  // SECTION 3: BATCH HISTORY
                  Text(
                    "BATCH HISTORY",
                    style: AppTheme.labelBold.copyWith(
                      fontSize: 11.0,
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  BatchHistoryWidget(
                    completedBags: state.riceBags.where((b) => b.status == "Completed").toList(),
                    getBagNumber: state.getBagNumber,
                    getBagProfit: state.getBagProfit,
                    onBagTap: (bag, bagNum) {
                      _showBatchDetailsBottomSheet(context, bag, bagNum, state);
                    },
                  ),
                  const SizedBox(height: 28.0),

                  // Rice Flour Bag Yields
                  Text(
                    "RICE FLOUR BAG YIELDS",
                    style: AppTheme.labelBold.copyWith(
                      fontSize: 11.0,
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
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
                                "CURRENT BAG EARNINGS",
                                style: AppTheme.labelSm.copyWith(
                                  fontSize: 8.5,
                                  color: AppTheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                "₹${NumberFormat('#,##,###.00').format(state.currentBagEarnings)}",
                                style: AppTheme.headlineMd.copyWith(
                                  fontSize: 18.0,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                state.activeRiceBag != null 
                                    ? "Remaining: ${state.activeRiceBag!.remainingKg.toStringAsFixed(1)} KG"
                                    : "No Active Bag",
                                style: AppTheme.labelSm.copyWith(fontSize: 9.5),
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
                                "PREVIOUS BAG EARNINGS",
                                style: AppTheme.labelSm.copyWith(
                                  fontSize: 8.5,
                                  color: AppTheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                "₹${NumberFormat('#,##,###.00').format(state.previousBagEarnings)}",
                                style: AppTheme.headlineMd.copyWith(
                                  fontSize: 18.0,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                state.previousCompletedRiceBag != null 
                                    ? "Size: ${state.previousCompletedRiceBag!.totalKg.toStringAsFixed(0)} KG"
                                    : "No Prev Bag",
                                style: AppTheme.labelSm.copyWith(fontSize: 9.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28.0),

                  // Hero Header Summary
                  BentoCard(
                    padding: const EdgeInsets.all(20.0),
                    backgroundColor: AppTheme.surface,
                    shadowStyle: ShadowStyle.heavy,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              state.latestActiveDateLabel == "Today"
                                  ? "TODAY'S REVENUE"
                                  : state.latestActiveDateLabel == "Yesterday"
                                      ? "YESTERDAY'S REVENUE"
                                      : "${state.latestActiveDateLabel.toUpperCase()} REVENUE",
                              style: AppTheme.labelBold.copyWith(
                                fontSize: 11.0,
                                color: AppTheme.onSurfaceVariant,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: Colors.black, width: 1.0),
                              ),
                              child: Text(
                                "$formattedPctChange VS ${state.previousActiveDateLabel.toUpperCase()}",
                                style: AppTheme.labelBold.copyWith(
                                  color: Colors.black,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          "₹${NumberFormat('#,##,###.00').format(todaySales)}",
                          style: AppTheme.headlineXl.copyWith(
                            fontSize: 28.0,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        const Divider(color: AppTheme.outlineVariant),
                        const SizedBox(height: 16.0),

                        // Stats mini row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "DELIVERIES",
                                    style: AppTheme.labelSm.copyWith(
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    "$totalDeliveries",
                                    style: AppTheme.headlineMd.copyWith(fontSize: 18.0),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1.5,
                              height: 36,
                              color: AppTheme.outlineVariant,
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.previousActiveDateLabel == "Today"
                                        ? "TODAY'S REVENUE"
                                        : state.previousActiveDateLabel == "Yesterday"
                                            ? "YESTERDAY'S REVENUE"
                                            : "${state.previousActiveDateLabel.toUpperCase()} REVENUE",
                                    style: AppTheme.labelSm.copyWith(
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    "₹${NumberFormat('#,##,###.00').format(yesterdaySales)}",
                                    style: AppTheme.dataTabular.copyWith(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32.0),

                  // Pinned Active Customer Ledger logs list
                  Text(
                    "LEDGER TRANSACTIONS LOG",
                    style: AppTheme.labelBold.copyWith(
                      fontSize: 11.0,
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  BentoCard(
                    padding: const EdgeInsets.all(0),
                    backgroundColor: AppTheme.surface,
                    shadowStyle: ShadowStyle.light,
                    child: state.filteredDeliveryLogsForSummary.isEmpty
                        ? const EmptyStateWidget(
                            title: "No Deliveries Recorded",
                            message: "No active route deliveries recorded yet. Fill out details in Sales tab.",
                            icon: Icons.local_shipping_outlined,
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.filteredDeliveryLogsForSummary.length,
                            separatorBuilder: (context, i) =>
                                const Divider(height: 1, color: AppTheme.outlineVariant),
                            itemBuilder: (context, index) {
                              final log = state.filteredDeliveryLogsForSummary[index];
                              return AnimatedListItem(
                                index: index,
                                child: ListTile(
                                  dense: true,
                                  onTap: () {
                                    _showEditDeleteBottomSheet(context, state, log);
                                  },
                                  title: Row(
                                    children: [
                                      Text(
                                        "#${log.serialNo} • ${log.customerName}",
                                        style: AppTheme.labelBold,
                                      ),
                                      const Spacer(),
                                      Text(
                                        "₹${log.amount.toStringAsFixed(2)}",
                                        style: AppTheme.dataTabular.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  subtitle: Row(
                                    children: [
                                      Text(
                                        "${log.itemName} • ${log.date}",
                                        style: AppTheme.labelSm,
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                        decoration: BoxDecoration(
                                          color: log.isPaid ? AppTheme.successContainer : AppTheme.errorContainer,
                                          borderRadius: BorderRadius.circular(100.0),
                                        ),
                                        child: Text(
                                          log.isPaid ? "PAID" : "UNPAID",
                                          style: AppTheme.labelBold.copyWith(
                                            color: log.isPaid ? AppTheme.onSuccessContainer : AppTheme.onErrorContainer,
                                            fontSize: 10.0,
                                            fontWeight: FontWeight.bold,
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

                  const SizedBox(height: 32.0),

                  // PDF EXPORT BENTO CARD
                  Text(
                    "EXPORT PRODUCT LEDGER",
                    style: AppTheme.labelBold.copyWith(
                      fontSize: 11.0,
                      color: AppTheme.onSurfaceVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  BentoCard(
                    padding: const EdgeInsets.all(20.0),
                    backgroundColor: AppTheme.surface,
                    shadowStyle: ShadowStyle.light,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SELECT PRODUCT FOR REPORT",
                          style: AppTheme.labelBold.copyWith(
                            fontSize: 10.0,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        
                        // Scrollable choice chips row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ["1 ₹ Chakli", "₹5 Chakli", "Nippat"].map((product) {
                              final isSelected = _selectedExportItem == product;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(
                                    product,
                                    style: AppTheme.labelBold.copyWith(
                                      fontSize: 12.0,
                                      color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedExportItem = product;
                                      });
                                    }
                                  },
                                  selectedColor: AppTheme.primary,
                                  backgroundColor: AppTheme.surfaceContainerHighest,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    side: BorderSide(
                                      color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
                                      width: 1.5,
                                    ),
                                  ),
                                  elevation: 0,
                                  pressElevation: 0,
                                  showCheckmark: false,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        const Divider(color: AppTheme.outlineVariant),
                        const SizedBox(height: 16.0),

                        Text(
                          "SELECT REPORT DATES LIMITS",
                          style: AppTheme.labelBold.copyWith(
                            fontSize: 10.0,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10.0),

                        // Date range picker button trigger
                        InkWell(
                          onTap: () async {
                            final DateTimeRange? pickedRange = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                              initialDateRange: _selectedDateRange,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppTheme.primary,
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: AppTheme.onSurface,
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.primary,
                                        textStyle: AppTheme.labelBold,
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedRange != null) {
                              setState(() {
                                _selectedDateRange = pickedRange;
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: AppTheme.outlineVariant, width: 1.0),
                              boxShadow: AppTheme.hardShadowLight,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, color: AppTheme.primary, size: 20.0),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: Text(
                                    "${DateFormat('dd MMM yyyy').format(_selectedDateRange.start)}  -  ${DateFormat('dd MMM yyyy').format(_selectedDateRange.end)}",
                                    style: AppTheme.dataTabular.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.0,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: AppTheme.onSurface, size: 20.0),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),

                        // PDF EXPORT ACTION BUTTON
                        InkWell(
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.showSnackBar(
                              SnackBar(
                                backgroundColor: AppTheme.primary,
                                duration: const Duration(seconds: 2),
                                content: Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.0,
                                      ),
                                    ),
                                    const SizedBox(width: 16.0),
                                    Text(
                                      "GENERATING PDF SALES REPORT...",
                                      style: AppTheme.labelBold.copyWith(color: Colors.white, fontSize: 11.0),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            await Future.delayed(const Duration(seconds: 1));

                            try {
                              await PdfService.generateAndDownloadSalesReport(
                                productName: _selectedExportItem,
                                dateRange: _selectedDateRange,
                                allLogs: state.deliveryLogs,
                              );

                              if (mounted) {
                                messenger.hideCurrentSnackBar();
                                messenger.showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppTheme.success,
                                    content: Text(
                                      "PDF SALES REPORT DOWNLOADED SUCCESSFULLY!",
                                      style: AppTheme.labelBold.copyWith(color: Colors.white, fontSize: 11.0),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                messenger.hideCurrentSnackBar();
                                messenger.showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppTheme.error,
                                    content: Text(
                                      "ERROR GENERATING REPORT: ${e.toString()}",
                                      style: AppTheme.labelBold.copyWith(color: Colors.white, fontSize: 11.0),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              boxShadow: AppTheme.hardShadowButton,
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18.0),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    "EXPORT REPORT (PDF)",
                                    style: AppTheme.labelBold.copyWith(
                                      color: Colors.white,
                                      letterSpacing: 1.0,
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

                  const SizedBox(height: 32.0),

                  // Google Sheets Deployed Web App Sync URL Bento Box
                  Text(
                    "GOOGLE SHEETS SYNC SETTINGS",
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
                        Text(
                          "DEPLOYED WEB APP URL",
                          style: AppTheme.labelBold.copyWith(fontSize: 9.5, color: AppTheme.outline),
                        ),
                        const SizedBox(height: 6.0),
                        TextField(
                          controller: _sheetsUrlController,
                          focusNode: _sheetsUrlFocusNode,
                          onChanged: (val) {
                            state.setGoogleSheetsUrl(val);
                          },
                          decoration: InputDecoration(
                            hintText: "https://script.google.com/macros/s/.../exec",
                            hintStyle: AppTheme.bodyMd.copyWith(color: AppTheme.outline),
                            filled: true,
                            fillColor: AppTheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              borderSide: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
                            ),
                          ),
                          style: AppTheme.bodyMd,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32.0),

                  // Start New Bag Action Button Card
                  Text(
                    "INVENTORY CYCLE OPERATIONS",
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
                        Text(
                          "FLOUR BAG OPERATIONS",
                          style: AppTheme.labelBold.copyWith(fontSize: 10.0, color: AppTheme.onSurface),
                        ),
                        const SizedBox(height: 6.0),
                        const Text(
                          "Close out your active flour tracking bag and start a fresh custom-sized production cycle instantly.",
                          style: TextStyle(fontSize: 12.0, color: AppTheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16.0),
                        InkWell(
                          onTap: () => _showStartNewBagDialog(context, state),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: AppTheme.primary, width: 1.5),
                              boxShadow: AppTheme.hardShadowLight,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.scale, color: AppTheme.primary, size: 18.0),
                                const SizedBox(width: 8.0),
                                Text(
                                  "START NEW BAG CYCLE",
                                  style: AppTheme.labelBold.copyWith(
                                    fontSize: 12.0,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40.0),

                  // BIG SYNC LOCKOUT BUTTON
                  InkWell(
                    onTap: state.isSyncing
                        ? null
                        : () {
                            state.triggerSync();
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(color: AppTheme.primary, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.primary,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_sync, color: Colors.white, size: 22),
                          const SizedBox(width: 10.0),
                          Text(
                            "SYNC ALL TO SHEETS",
                            style: AppTheme.headlineMd.copyWith(
                              fontSize: 16.0,
                              color: Colors.white,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            ),
          ),

          // 5. Fullscreen Cloud Syncing Spinner Overlay
          if (state.isSyncing)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: BentoCard(
                  padding: const EdgeInsets.all(28.0),
                  backgroundColor: AppTheme.surface,
                  shadowStyle: ShadowStyle.heavy,
                  borderRadius: AppTheme.radiusXl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                          strokeWidth: 4.0,
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Text(
                        "SYNCING IN PROGRESS...",
                        style: AppTheme.labelBold,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        "Uploading local ledger cache to Google Sheets.",
                        style: AppTheme.labelSm,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 6. Fullscreen Sync Complete Success Card Overlay
          if (state.syncSuccessful)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: BentoCard(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                    backgroundColor: AppTheme.surface,
                    shadowStyle: ShadowStyle.heavy,
                    borderRadius: AppTheme.radiusXl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Success Circle Indicator
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.successContainer,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.success.withValues(alpha: 0.3), width: 1.0),
                            boxShadow: AppTheme.hardShadowLight,
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: AppTheme.onSuccessContainer,
                            size: 48.0,
                          ),
                        ),
                        const SizedBox(height: 28.0),
                        Text(
                          "SYNC SUCCESSFUL!",
                          style: AppTheme.headlineLg.copyWith(fontSize: 22.0),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          "All daily route metrics, collections, and expense logs have been synced correctly to the remote cloud server database in real-time.",
                          style: AppTheme.bodyMd.copyWith(color: AppTheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32.0),
                        // CLOSE LEDGER Action button
                        InkWell(
                          onTap: () {
                            state.closeSyncOverlay();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              boxShadow: AppTheme.hardShadowButton,
                            ),
                            child: Center(
                              child: Text(
                                "CLOSE LEDGER",
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
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showStartNewBagDialog(BuildContext context, LedgerState state) {
    final TextEditingController kgCont = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            side: const BorderSide(color: AppTheme.outlineVariant, width: 1.0),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.scale, color: AppTheme.primary),
              const SizedBox(width: 8.0),
              Text(
                "START NEW BAG CYCLE",
                style: AppTheme.headlineMd.copyWith(fontSize: 18.0),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "This will close the current active bag cycle and start a fresh one. You can enter any custom weight size.",
                style: TextStyle(fontSize: 13.0, color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: kgCont,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "NEW BAG CAPACITY (KG)",
                  labelStyle: AppTheme.labelBold.copyWith(fontSize: 10, color: AppTheme.outline),
                  hintText: "e.g., 30, 45, 60...",
                  suffixText: "KG",
                  suffixStyle: AppTheme.labelBold.copyWith(color: AppTheme.onSurface),
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
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: TextButton(
                onPressed: () {
                  final kg = double.tryParse(kgCont.text.trim());
                  if (kg != null && kg > 0.0) {
                    final dateStr = DateFormat('dd MMMM yyyy').format(DateTime.now());
                    state.closeAndStartNewBag(totalKg: kg, date: dateStr);
                    Navigator.pop(context);
                    CustomToast.showSuccess(context, "NEW BAG CYCLE STARTED: $kg KG");
                  }
                },
                child: Text(
                  "START BAG",
                  style: AppTheme.labelBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditDeleteBottomSheet(BuildContext context, LedgerState state, DeliveryLog log) {
    final detailsCont = TextEditingController(text: log.itemName);
    final amountCont = TextEditingController(text: log.amount.toStringAsFixed(0));

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

              Text(
                "EDIT TRANSACTION #${log.serialNo}",
                style: AppTheme.headlineMd.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                "Customer: ${log.customerName} • Date: ${log.date}",
                style: AppTheme.labelSm.copyWith(color: AppTheme.outline),
              ),
              const SizedBox(height: 20.0),

              TextField(
                controller: detailsCont,
                decoration: InputDecoration(
                  labelText: "ITEM DETAILS",
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

              TextField(
                controller: amountCont,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                decoration: InputDecoration(
                  labelText: "AMOUNT (₹)",
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

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final confirm = await CustomToast.showDestructiveConfirmation(
                          context,
                          title: "DELETE TRANSACTION?",
                          message: "Are you sure you want to permanently delete transaction #${log.serialNo} of ₹${log.amount.toStringAsFixed(0)} for ${log.customerName}?",
                          confirmLabel: "DELETE",
                        );
                        if (confirm && context.mounted) {
                          Navigator.pop(context);
                          state.deleteTransactionBySerialNo(log.serialNo);
                          if (context.mounted) {
                            CustomToast.showSuccess(context, "TRANSACTION #${log.serialNo} DELETED");
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

                  Expanded(
                    child: InkWell(
                      onTap: () {
                        final newAmt = double.tryParse(amountCont.text.trim()) ?? log.amount;
                        Navigator.pop(context);
                        state.editTransactionBySerialNo(log.serialNo, detailsCont.text.trim(), newAmt);
                        CustomToast.showSuccess(context, "TRANSACTION #${log.serialNo} UPDATED");
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: AppTheme.hardShadowButton,
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


  void _showBatchDetailsBottomSheet(BuildContext context, RiceBag bag, int bagNum, LedgerState state) {
    final revenue = state.getBagRevenue(bag);
    final expenses = state.getBagExpenses(bag);
    final profit = state.getBagProfit(bag);
    final margin = state.getBagProfitMargin(bag);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (context) {
        return Container(
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
              // Handlebar
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

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Batch #$bagNum Snapshot",
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
              const Divider(height: 24.0, color: AppTheme.outlineVariant),

              // Financial snapshot details
              _buildSnapshotRow("Batch Number", "Batch #$bagNum"),
              _buildSnapshotRow("Total Quantity", "${bag.totalKg.toStringAsFixed(0)} KG"),
              _buildSnapshotRow("Revenue", "₹${NumberFormat('#,##,###.00').format(revenue)}"),
              _buildSnapshotRow("Expenses", "₹${NumberFormat('#,##,###.00').format(expenses)}"),
              _buildSnapshotRow("Profit", "₹${NumberFormat('#,##,###.00').format(profit)}", isProfit: true, profitVal: profit),
              _buildSnapshotRow("Profit Margin", "${margin.toStringAsFixed(2)}%"),
              _buildSnapshotRow("Start Date", bag.startDate),
              _buildSnapshotRow("End Date", bag.endDate ?? "N/A"),
              const SizedBox(height: 16.0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSnapshotRow(String label, String value, {bool isProfit = false, double profitVal = 0.0}) {
    Color valColor = Colors.black;
    if (isProfit) {
      valColor = profitVal >= 0 ? AppTheme.success : AppTheme.error;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMd.copyWith(color: AppTheme.outline, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: AppTheme.labelBold.copyWith(fontSize: 16.0, color: valColor),
          ),
        ],
      ),
    );
  }
}

