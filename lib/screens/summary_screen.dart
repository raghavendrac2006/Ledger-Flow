import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../core/app_state.dart';
import '../core/pdf_service.dart';
import '../widgets/bento_card.dart';
import '../widgets/custom_toast.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  int _selectedBarIndex = 4; // Defaults to October (index 4)
  String _selectedExportItem = "2 ₹ Chakli";
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  late TextEditingController _sheetsUrlController;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<LedgerState>(context, listen: false);
    _sheetsUrlController = TextEditingController(text: state.googleSheetsUrl);
  }

  @override
  void dispose() {
    _sheetsUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LedgerState>(context);
    final todaySales = state.todaySales;
    final totalDeliveries = state.todayDeliveriesCount;
    final totalReturns = state.todayReturnsCount;

    final chartData = state.getChartData();
    final selectedMonthData = chartData[_selectedBarIndex];
    final selectedMonthName = selectedMonthData["month"] as String;
    final selectedMonthSales = selectedMonthData["sales"] as double;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rice Flour Bag Yields
                  Text(
                    "RICE FLOUR BAG YIELDS",
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
                              "TODAY'S REVENUE",
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
                                "0.0% VS YESTERDAY",
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
                        const SizedBox(height: 12.0),

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
                                    "RETURNED BAGS",
                                    style: AppTheme.labelSm.copyWith(
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    "$totalReturns",
                                    style: AppTheme.headlineMd.copyWith(fontSize: 18.0),
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

                  // Interactive Sales Trend Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "MONTHLY SALES TREND",
                        style: AppTheme.labelBold.copyWith(
                          fontSize: 11.0,
                          color: AppTheme.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        "$selectedMonthName: ₹${NumberFormat('#,##,###').format(selectedMonthSales)}",
                        style: AppTheme.labelBold.copyWith(
                          fontSize: 12.0,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),

                  // Custom Interactive Bar Chart Bento Container
                  BentoCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                    backgroundColor: AppTheme.surface,
                    shadowStyle: ShadowStyle.light,
                    child: Column(
                      children: [
                        // Chart body
                        SizedBox(
                          height: 140,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(chartData.length, (index) {
                              final data = chartData[index];
                              final sales = data["sales"] as double;
                              final month = data["month"] as String;

                              final isSelected = _selectedBarIndex == index;

                              // Maximum sales base value is 150000.0 for scaling heights
                              final double scaleRatio = sales == 0.0 ? 0.0 : sales / 150000.0;
                              final double barHeight = sales == 0.0 ? 2.0 : (scaleRatio * 120.0).clamp(15.0, 120.0);

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedBarIndex = index;
                                    });
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Hover/Selection Details Value Tooltip
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                          margin: const EdgeInsets.only(bottom: 4.0),
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius: BorderRadius.circular(2.0),
                                          ),
                                          child: Text(
                                            "₹${(sales / 1000).toStringAsFixed(0)}k",
                                            style: AppTheme.labelBold.copyWith(
                                              fontSize: 9.0,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      // The actual bar
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 24.0,
                                        height: barHeight,
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.black : AppTheme.surfaceContainerHighest,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(AppTheme.radiusSm),
                                            topRight: Radius.circular(AppTheme.radiusSm),
                                          ),
                                          border: Border.all(
                                            color: Colors.black,
                                            width: isSelected ? 2.0 : 1.5,
                                          ),
                                          boxShadow: isSelected
                                              ? const [
                                                  BoxShadow(
                                                    color: AppTheme.primary,
                                                    offset: Offset(2, 0),
                                                    blurRadius: 0,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      Text(
                                        month,
                                        style: AppTheme.labelBold.copyWith(
                                          fontSize: 10.0,
                                          color: isSelected ? Colors.black : AppTheme.outline,
                                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
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
                  const SizedBox(height: 12.0),

                  BentoCard(
                    padding: const EdgeInsets.all(0),
                    backgroundColor: AppTheme.surface,
                    shadowStyle: ShadowStyle.light,
                    child: state.deliveryLogs.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(28.0),
                            child: Center(
                              child: Text(
                                "No active route deliveries recorded yet. Fill out details in Sales tab.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13.0, color: AppTheme.outline),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.deliveryLogs.length,
                            separatorBuilder: (context, i) =>
                                const Divider(height: 1, color: AppTheme.outlineVariant),
                            itemBuilder: (context, index) {
                              final log = state.deliveryLogs[index];
                              return ListTile(
                                dense: true,
                                onLongPress: () {
                                  _showEditDeleteDialog(context, state, log);
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
                  const SizedBox(height: 12.0),

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
                            children: ["2 ₹ Chakli", "₹5 Chakli", "Nippat"].map((product) {
                              final isSelected = _selectedExportItem == product;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(
                                    product,
                                    style: AppTheme.labelBold.copyWith(
                                      fontSize: 12.0,
                                      color: isSelected ? Colors.white : Colors.black,
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
                                  selectedColor: Colors.black,
                                  backgroundColor: AppTheme.surfaceContainerHighest,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    side: BorderSide(
                                      color: Colors.black,
                                      width: isSelected ? 2.0 : 1.5,
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
                                      onSurface: Colors.black,
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.black,
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
                              border: Border.all(color: Colors.black, width: 1.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, color: AppTheme.primary, size: 20.0),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: Text(
                                    "${DateFormat('dd MMM yyyy').format(_selectedDateRange.start)}  -  ${DateFormat('dd MMM yyyy').format(_selectedDateRange.end)}",
                                    style: AppTheme.dataTabular.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.0,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.black, size: 20.0),
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
                                backgroundColor: Colors.black,
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
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: Colors.black, width: 1.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppTheme.primary,
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
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
                  const SizedBox(height: 12.0),

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
                              borderSide: const BorderSide(color: Colors.black, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              borderSide: const BorderSide(color: Colors.black, width: 1.5),
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
                  const SizedBox(height: 12.0),

                  BentoCard(
                    padding: const EdgeInsets.all(18.0),
                    backgroundColor: AppTheme.surface,
                    shadowStyle: ShadowStyle.light,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "FLOUR BAG OPERATIONS",
                          style: AppTheme.labelBold.copyWith(fontSize: 10.0, color: Colors.black),
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
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: Colors.black, width: 2.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.scale, color: Colors.black, size: 18.0),
                                const SizedBox(width: 8.0),
                                Text(
                                  "START NEW BAG CYCLE",
                                  style: AppTheme.labelBold.copyWith(
                                    fontSize: 12.0,
                                    color: Colors.black,
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
                        border: Border.all(color: Colors.black, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
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
                            border: Border.all(color: Colors.black, width: 2.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
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
                        const SizedBox(height: 12.0),
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
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              border: Border.all(color: Colors.black, width: 1.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppTheme.success,
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
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
            side: const BorderSide(color: Colors.black, width: 2.5),
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
                  suffixStyle: AppTheme.labelBold.copyWith(color: Colors.black),
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

  void _showEditDeleteDialog(BuildContext context, LedgerState state, DeliveryLog log) {
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
            "Select an action for transaction #${log.serialNo} of ₹${log.amount.toStringAsFixed(0)} for ${log.customerName}.",
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
                  _showDeleteConfirmDialog(context, state, log);
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
                  _showEditTransactionDialog(context, state, log);
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

  void _showDeleteConfirmDialog(BuildContext context, LedgerState state, DeliveryLog log) {
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
            "CONFIRM DELETE",
            style: AppTheme.headlineMd.copyWith(fontSize: 18.0),
          ),
          content: Text(
            "Are you sure you want to permanently delete transaction #${log.serialNo} for ${log.customerName}? This will adjust outstanding balance if unpaid.",
            style: AppTheme.bodyMd,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "NO",
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
                  state.deleteTransactionBySerialNo(log.serialNo);
                  Navigator.pop(context);
                  CustomToast.showSuccess(context, "TRANSACTION #${log.serialNo} DELETED");
                },
                child: Text(
                  "YES, DELETE",
                  style: AppTheme.labelBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditTransactionDialog(BuildContext context, LedgerState state, DeliveryLog log) {
    final detailsCont = TextEditingController(text: log.itemName);
    final amountCont = TextEditingController(text: log.amount.toStringAsFixed(0));

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
            "EDIT TRANSACTION #${log.serialNo}",
            style: AppTheme.headlineMd.copyWith(fontSize: 18.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: detailsCont,
                decoration: const InputDecoration(labelText: "ITEM DETAILS"),
              ),
              const SizedBox(height: 12.0),
              TextField(
                controller: amountCont,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "AMOUNT (₹)"),
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
                  final newAmt = double.tryParse(amountCont.text.trim()) ?? log.amount;
                  state.editTransactionBySerialNo(log.serialNo, detailsCont.text.trim(), newAmt);
                  Navigator.pop(context);
                  CustomToast.showSuccess(context, "TRANSACTION #${log.serialNo} UPDATED");
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
